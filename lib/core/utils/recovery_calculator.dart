import 'package:flutter/foundation.dart';

/// Classe utilitária para cálculos de recuperação pós-operatória.
///
/// FONTE ÚNICA DA VERDADE - usar em Home, Treino e qualquer outro lugar
/// que precise calcular dias desde cirurgia ou semana atual.
///
/// Garante consistência entre todas as telas do app.
class RecoveryCalculator {
  RecoveryCalculator._(); // Construtor privado - classe apenas com métodos estáticos

  /// Calcula dias desde a cirurgia com normalização de timezone.
  ///
  /// Normaliza para "dia" (sem hora) para evitar problemas de timezone
  /// que poderiam causar diferenças de +/- 1 dia.
  ///
  /// Retorna 0 se:
  /// - surgeryDate for null
  /// - surgeryDate for no futuro
  ///
  /// Exemplo:
  /// - Cirurgia hoje: retorna 0
  /// - Cirurgia há 6 dias: retorna 6
  /// - Cirurgia há 7 dias: retorna 7
  static int getDaysSinceSurgery(DateTime? surgeryDate) {
    if (surgeryDate == null) {
      debugPrint('[RecoveryCalculator] surgeryDate é null, retornando 0');
      return 0;
    }

    // Normalizar para "dia" (sem hora) para evitar problemas de timezone
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final surgeryDay = DateTime(surgeryDate.year, surgeryDate.month, surgeryDate.day);

    final days = today.difference(surgeryDay).inDays;

    debugPrint('[RecoveryCalculator] surgeryDate=$surgeryDate, today=$today, days=$days');

    // Se cirurgia no futuro, retorna 0
    return days < 0 ? 0 : days;
  }

  /// Calcula semana atual baseada nos dias desde cirurgia.
  ///
  /// Fórmula: (diasDesdeCirurgia ~/ 7) + 1
  ///
  /// Exemplos:
  /// - Dias 0-6: Semana 1
  /// - Dias 7-13: Semana 2
  /// - Dias 14-20: Semana 3
  /// - etc.
  ///
  /// [daysSinceSurgery] - Número de dias desde a cirurgia
  /// [maxWeeks] - Número máximo de semanas do protocolo (default: 8)
  ///
  /// Retorna um valor entre 1 e maxWeeks (inclusive).
  static int getCurrentWeek(int daysSinceSurgery, {int maxWeeks = 8}) {
    if (daysSinceSurgery < 0) return 1;

    final week = (daysSinceSurgery ~/ 7) + 1;
    final clampedWeek = week.clamp(1, maxWeeks);

    debugPrint('[RecoveryCalculator] daysSince=$daysSinceSurgery, week=$week, clamped=$clampedWeek');

    return clampedWeek;
  }

  /// Retorna o status de uma semana baseado na semana atual.
  ///
  /// Estados:
  /// - 0 = Concluída (semana < semanaAtual)
  /// - 1 = AGORA (semana == semanaAtual)
  /// - 2 = Em breve (semana > semanaAtual)
  ///
  /// [weekNumber] - Número da semana a verificar (1-8)
  /// [currentWeek] - Semana atual do paciente (1-8)
  static int getWeekStatus(int weekNumber, int currentWeek) {
    if (weekNumber < currentWeek) return 0; // Concluída
    if (weekNumber == currentWeek) return 1; // AGORA
    return 2; // Em breve
  }

  /// Retorna o nome do status para debug/display.
  static String getWeekStatusName(int status) {
    switch (status) {
      case 0:
        return 'COMPLETED';
      case 1:
        return 'CURRENT';
      case 2:
        return 'FUTURE';
      default:
        return 'UNKNOWN';
    }
  }

  /// Converte status da API (String) para formato interno (int).
  ///
  /// API retorna: 'COMPLETED', 'CURRENT', 'FUTURE'
  /// App usa: 0, 1, 2
  static int apiStatusToInternal(String? apiStatus) {
    switch (apiStatus) {
      case 'COMPLETED':
        return 0;
      case 'CURRENT':
        return 1;
      case 'FUTURE':
      default:
        return 2;
    }
  }
}
