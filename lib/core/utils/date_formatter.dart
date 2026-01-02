import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Helper para formatação de datas em pt-BR
///
/// Centraliza toda formatação de datas do app para garantir
/// consistência e facilitar manutenção.
class DateFormatter {
  static bool _initialized = false;

  /// Inicializa locale pt_BR (chamar uma vez no main.dart)
  static Future<void> init() async {
    if (!_initialized) {
      await initializeDateFormatting('pt_BR', null);
      _initialized = true;
    }
  }

  /// Formato completo: "3 de janeiro de 2026"
  static String fullDate(DateTime date) {
    return DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(date);
  }

  /// Formato curto: "03/01/2026"
  static String shortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  /// Mês e ano: "janeiro 2026"
  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'pt_BR').format(date);
  }

  /// Mês e ano capitalizado: "Janeiro 2026"
  static String monthYearCapitalized(DateTime date) {
    final formatted = DateFormat('MMMM yyyy', 'pt_BR').format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  /// Mês abreviado: "jan"
  static String monthAbbr(DateTime date) {
    return DateFormat('MMM', 'pt_BR').format(date);
  }

  /// Dia da semana completo: "sábado"
  static String weekday(DateTime date) {
    return DateFormat('EEEE', 'pt_BR').format(date);
  }

  /// Dia da semana abreviado: "sáb"
  static String weekdayAbbr(DateTime date) {
    return DateFormat('E', 'pt_BR').format(date);
  }

  /// Dia e mês: "3 de janeiro"
  static String dayMonth(DateTime date) {
    return DateFormat("d 'de' MMMM", 'pt_BR').format(date);
  }

  /// Formatação para título de data selecionada
  /// Retorna "Hoje, 3 de janeiro" ou "Amanhã, 4 de janeiro" ou "3 de janeiro"
  static String selectedDateTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final tomorrow = today.add(const Duration(days: 1));

    final dayMonthFormatted = dayMonth(date);

    if (targetDate == today) {
      return 'Hoje, $dayMonthFormatted';
    } else if (targetDate == tomorrow) {
      return 'Amanhã, $dayMonthFormatted';
    }
    return dayMonthFormatted;
  }

  /// Formatação para eventos: "Sex, 03/01"
  static String eventDate(DateTime date) {
    final weekdayStr = DateFormat('E', 'pt_BR').format(date);
    final dayMonth = DateFormat('dd/MM', 'pt_BR').format(date);
    return '${weekdayStr[0].toUpperCase()}${weekdayStr.substring(1)}, $dayMonth';
  }

  /// Formatação para lista de eventos: "3 jan" ou "Hoje" ou "Amanhã"
  static String eventDateShort(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (targetDate == today) {
      return 'Hoje';
    } else if (targetDate == tomorrow) {
      return 'Amanhã';
    }

    final day = date.day;
    final month = monthNamesAbbr[date.month - 1].toLowerCase();
    return '$day $month';
  }

  /// Lista de nomes de meses em português (completo)
  static const List<String> monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  /// Lista de nomes de meses abreviados em português
  static const List<String> monthNamesAbbr = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  /// Lista de dias da semana abreviados (começando em Domingo)
  static const List<String> weekDaysAbbr = [
    'Dom',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
  ];

  /// Lista de dias da semana completos (começando em Domingo)
  static const List<String> weekDaysFull = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];
}
