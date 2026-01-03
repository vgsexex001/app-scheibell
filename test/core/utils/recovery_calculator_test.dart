import 'package:flutter_test/flutter_test.dart';
import 'package:teste_ios/core/utils/recovery_calculator.dart';

void main() {
  group('RecoveryCalculator', () {
    group('getDaysSinceSurgery', () {
      test('retorna 0 quando surgeryDate é null', () {
        expect(RecoveryCalculator.getDaysSinceSurgery(null), 0);
      });

      test('retorna 0 para cirurgia hoje', () {
        final today = DateTime.now();
        expect(RecoveryCalculator.getDaysSinceSurgery(today), 0);
      });

      test('retorna 0 para cirurgia no futuro', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(RecoveryCalculator.getDaysSinceSurgery(tomorrow), 0);
      });

      test('retorna dias corretos para cirurgia no passado', () {
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));
        expect(RecoveryCalculator.getDaysSinceSurgery(sixDaysAgo), 6);
      });

      test('retorna 7 para cirurgia há 7 dias', () {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        expect(RecoveryCalculator.getDaysSinceSurgery(sevenDaysAgo), 7);
      });

      test('retorna 14 para cirurgia há 14 dias', () {
        final fourteenDaysAgo = DateTime.now().subtract(const Duration(days: 14));
        expect(RecoveryCalculator.getDaysSinceSurgery(fourteenDaysAgo), 14);
      });

      test('ignora horas na comparação (cirurgia às 23:59 conta como mesmo dia)', () {
        final now = DateTime.now();
        final surgeryLateToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
        expect(RecoveryCalculator.getDaysSinceSurgery(surgeryLateToday), 0);
      });
    });

    group('getCurrentWeek', () {
      test('D+0 retorna semana 1', () {
        expect(RecoveryCalculator.getCurrentWeek(0), 1);
      });

      test('D+6 retorna semana 1', () {
        expect(RecoveryCalculator.getCurrentWeek(6), 1);
      });

      test('D+7 retorna semana 2', () {
        expect(RecoveryCalculator.getCurrentWeek(7), 2);
      });

      test('D+13 retorna semana 2', () {
        expect(RecoveryCalculator.getCurrentWeek(13), 2);
      });

      test('D+14 retorna semana 3', () {
        expect(RecoveryCalculator.getCurrentWeek(14), 3);
      });

      test('D+20 retorna semana 3', () {
        expect(RecoveryCalculator.getCurrentWeek(20), 3);
      });

      test('D+21 retorna semana 4', () {
        expect(RecoveryCalculator.getCurrentWeek(21), 4);
      });

      test('D+49 retorna semana 8 (limite padrão)', () {
        expect(RecoveryCalculator.getCurrentWeek(49), 8);
      });

      test('D+56+ não excede maxWeeks (default 8)', () {
        expect(RecoveryCalculator.getCurrentWeek(100), 8);
      });

      test('respeita maxWeeks customizado', () {
        expect(RecoveryCalculator.getCurrentWeek(100, maxWeeks: 12), 12);
      });

      test('dias negativos retornam semana 1', () {
        expect(RecoveryCalculator.getCurrentWeek(-5), 1);
      });
    });

    group('getWeekStatus', () {
      test('retorna 0 (Concluída) para semana < semanaAtual', () {
        expect(RecoveryCalculator.getWeekStatus(1, 3), 0);
        expect(RecoveryCalculator.getWeekStatus(2, 3), 0);
      });

      test('retorna 1 (AGORA) para semana == semanaAtual', () {
        expect(RecoveryCalculator.getWeekStatus(3, 3), 1);
        expect(RecoveryCalculator.getWeekStatus(1, 1), 1);
      });

      test('retorna 2 (Em breve) para semana > semanaAtual', () {
        expect(RecoveryCalculator.getWeekStatus(4, 3), 2);
        expect(RecoveryCalculator.getWeekStatus(8, 3), 2);
      });
    });

    group('getWeekStatusName', () {
      test('retorna nomes corretos', () {
        expect(RecoveryCalculator.getWeekStatusName(0), 'COMPLETED');
        expect(RecoveryCalculator.getWeekStatusName(1), 'CURRENT');
        expect(RecoveryCalculator.getWeekStatusName(2), 'FUTURE');
        expect(RecoveryCalculator.getWeekStatusName(99), 'UNKNOWN');
      });
    });

    group('apiStatusToInternal', () {
      test('converte COMPLETED para 0', () {
        expect(RecoveryCalculator.apiStatusToInternal('COMPLETED'), 0);
      });

      test('converte CURRENT para 1', () {
        expect(RecoveryCalculator.apiStatusToInternal('CURRENT'), 1);
      });

      test('converte FUTURE para 2', () {
        expect(RecoveryCalculator.apiStatusToInternal('FUTURE'), 2);
      });

      test('converte null para 2 (default FUTURE)', () {
        expect(RecoveryCalculator.apiStatusToInternal(null), 2);
      });

      test('converte status desconhecido para 2', () {
        expect(RecoveryCalculator.apiStatusToInternal('UNKNOWN'), 2);
      });
    });

    group('Integração: fluxo completo D+X -> Semana -> Status', () {
      test('paciente D+0: Semana 1 AGORA, demais Em breve', () {
        final days = 0;
        final currentWeek = RecoveryCalculator.getCurrentWeek(days);
        expect(currentWeek, 1);

        expect(RecoveryCalculator.getWeekStatus(1, currentWeek), 1); // AGORA
        expect(RecoveryCalculator.getWeekStatus(2, currentWeek), 2); // Em breve
        expect(RecoveryCalculator.getWeekStatus(3, currentWeek), 2); // Em breve
      });

      test('paciente D+7: Semana 2 AGORA, Sem 1 Concluída', () {
        final days = 7;
        final currentWeek = RecoveryCalculator.getCurrentWeek(days);
        expect(currentWeek, 2);

        expect(RecoveryCalculator.getWeekStatus(1, currentWeek), 0); // Concluída
        expect(RecoveryCalculator.getWeekStatus(2, currentWeek), 1); // AGORA
        expect(RecoveryCalculator.getWeekStatus(3, currentWeek), 2); // Em breve
      });

      test('paciente D+14: Semana 3 AGORA, Sem 1-2 Concluídas', () {
        final days = 14;
        final currentWeek = RecoveryCalculator.getCurrentWeek(days);
        expect(currentWeek, 3);

        expect(RecoveryCalculator.getWeekStatus(1, currentWeek), 0); // Concluída
        expect(RecoveryCalculator.getWeekStatus(2, currentWeek), 0); // Concluída
        expect(RecoveryCalculator.getWeekStatus(3, currentWeek), 1); // AGORA
        expect(RecoveryCalculator.getWeekStatus(4, currentWeek), 2); // Em breve
      });
    });
  });
}
