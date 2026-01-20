import '../utils/recovery_calculator.dart';

/// Representa uma fase da timeline de recuperação (D+1, D+7, etc.)
class TimelinePhase {
  final int day;
  final String label;
  final String title;
  final String description;

  const TimelinePhase({
    required this.day,
    required this.label,
    required this.title,
    required this.description,
  });
}

/// Status de uma fase da timeline
enum PhaseStatus {
  completed, // Fase já passou
  current, // Fase atual
  locked, // Fase bloqueada (futuro)
}

/// Status de uma semana de treino
enum WeekStatus {
  completed, // Semana concluída
  current, // Semana atual
  locked, // Semana bloqueada
}

/// Serviço de progresso - centraliza lógica de desbloqueio de conteúdo.
///
/// Usa RecoveryCalculator como fonte única de verdade para cálculos.
class ProgressService {
  ProgressService._();

  /// Fases da timeline de recuperação
  static const List<TimelinePhase> phases = [
    TimelinePhase(
      day: 1,
      label: 'D+1',
      title: 'Primeiro Dia',
      description: 'Início da recuperação',
    ),
    TimelinePhase(
      day: 7,
      label: 'D+7',
      title: 'Primeira Semana',
      description: 'Fase inicial',
    ),
    TimelinePhase(
      day: 30,
      label: 'D+30',
      title: 'Primeiro Mês',
      description: 'Progressão moderada',
    ),
    TimelinePhase(
      day: 90,
      label: 'D+90',
      title: 'Três Meses',
      description: 'Recuperação avançada',
    ),
    TimelinePhase(
      day: 180,
      label: 'D+180',
      title: 'Seis Meses',
      description: 'Fase final',
    ),
  ];

  /// Calcula dias desde o início (surgeryDate ou createdAt como fallback).
  ///
  /// Usa RecoveryCalculator para normalização de timezone.
  static int calculateDaysSinceStart(DateTime? surgeryDate, DateTime? createdAt) {
    return RecoveryCalculator.getDaysSinceSurgery(surgeryDate ?? createdAt);
  }

  /// Retorna a semana atual (1-8) baseada nos dias desde o início.
  static int getCurrentWeek(int days, {int maxWeeks = 8}) {
    return RecoveryCalculator.getCurrentWeek(days, maxWeeks: maxWeeks);
  }

  /// Verifica se uma semana está desbloqueada.
  ///
  /// Uma semana está desbloqueada se seu número for menor ou igual à semana atual.
  static bool isWeekUnlocked(int weekNumber, int currentDays) {
    final currentWeek = getCurrentWeek(currentDays);
    return weekNumber <= currentWeek;
  }

  /// Verifica se uma fase (D+X) está desbloqueada.
  ///
  /// Uma fase está desbloqueada se os dias atuais forem >= ao dia da fase.
  static bool isPhaseUnlocked(int phaseDays, int currentDays) {
    return currentDays >= phaseDays;
  }

  /// Calcula quantos dias faltam para desbloquear um conteúdo.
  ///
  /// Retorna 0 se já estiver desbloqueado.
  static int daysUntilUnlock(int requiredDays, int currentDays) {
    final remaining = requiredDays - currentDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Calcula quantos dias faltam para desbloquear uma semana específica.
  ///
  /// Semana 1: desbloqueada no dia 0
  /// Semana 2: desbloqueada no dia 7
  /// Semana N: desbloqueada no dia (N-1) * 7
  static int daysUntilWeekUnlock(int weekNumber, int currentDays) {
    final requiredDays = (weekNumber - 1) * 7;
    return daysUntilUnlock(requiredDays, currentDays);
  }

  /// Retorna o status de uma fase da timeline.
  ///
  /// - completed: fase já passou (há uma fase posterior também desbloqueada)
  /// - current: fase atual (desbloqueada, mas próxima fase ainda não)
  /// - locked: fase bloqueada (dias atuais < dia da fase)
  static PhaseStatus getPhaseStatus(int phaseDays, int currentDays) {
    if (currentDays < phaseDays) {
      return PhaseStatus.locked;
    }

    // Encontrar a próxima fase
    final currentPhaseIndex = phases.indexWhere((p) => p.day == phaseDays);
    if (currentPhaseIndex == -1) {
      // Fase não encontrada, considerar como current se desbloqueada
      return PhaseStatus.current;
    }

    // Se for a última fase, é current se desbloqueada
    if (currentPhaseIndex == phases.length - 1) {
      return PhaseStatus.current;
    }

    // Verificar se a próxima fase já está desbloqueada
    final nextPhase = phases[currentPhaseIndex + 1];
    if (currentDays >= nextPhase.day) {
      return PhaseStatus.completed;
    }

    return PhaseStatus.current;
  }

  /// Retorna o status de uma semana de treino.
  ///
  /// Usa RecoveryCalculator.getWeekStatus e converte para WeekStatus enum.
  static WeekStatus getWeekStatus(int weekNumber, int currentDays) {
    final currentWeek = getCurrentWeek(currentDays);
    final status = RecoveryCalculator.getWeekStatus(weekNumber, currentWeek);

    switch (status) {
      case 0:
        return WeekStatus.completed;
      case 1:
        return WeekStatus.current;
      case 2:
      default:
        return WeekStatus.locked;
    }
  }

  /// Retorna a fase atual baseada nos dias desde o início.
  ///
  /// Retorna null se nenhuma fase estiver desbloqueada.
  static TimelinePhase? getCurrentPhase(int currentDays) {
    TimelinePhase? current;

    for (final phase in phases) {
      if (currentDays >= phase.day) {
        current = phase;
      } else {
        break;
      }
    }

    return current;
  }

  /// Retorna a próxima fase a ser desbloqueada.
  ///
  /// Retorna null se todas as fases já estiverem desbloqueadas.
  static TimelinePhase? getNextPhase(int currentDays) {
    for (final phase in phases) {
      if (currentDays < phase.day) {
        return phase;
      }
    }
    return null;
  }
}
