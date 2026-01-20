import 'package:flutter/foundation.dart';
import '../services/progress_service.dart';

/// Provider para gerenciar o estado de progresso do paciente.
///
/// Centraliza a lógica de desbloqueio de conteúdo baseada nos dias
/// desde a cirurgia/cadastro do paciente.
class ProgressProvider extends ChangeNotifier {
  int _daysSinceStart = 0;
  int _currentWeek = 1;
  bool _isInitialized = false;
  DateTime? _surgeryDate;
  DateTime? _createdAt;

  // Getters
  int get daysSinceStart => _daysSinceStart;
  int get currentWeek => _currentWeek;
  bool get isInitialized => _isInitialized;
  DateTime? get surgeryDate => _surgeryDate;
  DateTime? get createdAt => _createdAt;

  /// Lista das fases da timeline
  List<TimelinePhase> get phases => ProgressService.phases;

  /// Inicializa o provider com os dados do paciente.
  ///
  /// Deve ser chamado após autenticação, quando temos acesso aos dados do usuário.
  void initialize(DateTime? surgeryDate, DateTime? createdAt) {
    _surgeryDate = surgeryDate;
    _createdAt = createdAt;
    _daysSinceStart = ProgressService.calculateDaysSinceStart(surgeryDate, createdAt);
    _currentWeek = ProgressService.getCurrentWeek(_daysSinceStart);
    _isInitialized = true;

    debugPrint('[ProgressProvider] Inicializado: dias=$_daysSinceStart, semana=$_currentWeek');
    notifyListeners();
  }

  /// Reseta o provider (usar no logout).
  void reset() {
    _daysSinceStart = 0;
    _currentWeek = 1;
    _isInitialized = false;
    _surgeryDate = null;
    _createdAt = null;
    notifyListeners();
  }

  /// Verifica se uma semana está desbloqueada.
  bool isWeekUnlocked(int weekNumber) {
    return ProgressService.isWeekUnlocked(weekNumber, _daysSinceStart);
  }

  /// Verifica se uma fase (D+X) está desbloqueada.
  bool isPhaseUnlocked(int phaseDays) {
    return ProgressService.isPhaseUnlocked(phaseDays, _daysSinceStart);
  }

  /// Retorna quantos dias faltam para desbloquear uma fase.
  int daysUntilPhaseUnlock(int phaseDays) {
    return ProgressService.daysUntilUnlock(phaseDays, _daysSinceStart);
  }

  /// Retorna quantos dias faltam para desbloquear uma semana.
  int daysUntilWeekUnlock(int weekNumber) {
    return ProgressService.daysUntilWeekUnlock(weekNumber, _daysSinceStart);
  }

  /// Retorna o status de uma fase da timeline.
  PhaseStatus getPhaseStatus(int phaseDays) {
    return ProgressService.getPhaseStatus(phaseDays, _daysSinceStart);
  }

  /// Retorna o status de uma semana de treino.
  WeekStatus getWeekStatus(int weekNumber) {
    return ProgressService.getWeekStatus(weekNumber, _daysSinceStart);
  }

  /// Retorna a fase atual do paciente.
  TimelinePhase? get currentPhase {
    return ProgressService.getCurrentPhase(_daysSinceStart);
  }

  /// Retorna a próxima fase a ser desbloqueada.
  TimelinePhase? get nextPhase {
    return ProgressService.getNextPhase(_daysSinceStart);
  }

  /// Retorna o status de todas as fases para exibição na timeline.
  List<PhaseWithStatus> get phasesWithStatus {
    return phases.map((phase) {
      return PhaseWithStatus(
        phase: phase,
        status: getPhaseStatus(phase.day),
        daysUntilUnlock: daysUntilPhaseUnlock(phase.day),
      );
    }).toList();
  }
}

/// Classe auxiliar que combina uma fase com seu status atual.
class PhaseWithStatus {
  final TimelinePhase phase;
  final PhaseStatus status;
  final int daysUntilUnlock;

  const PhaseWithStatus({
    required this.phase,
    required this.status,
    required this.daysUntilUnlock,
  });

  bool get isUnlocked => status != PhaseStatus.locked;
  bool get isCurrent => status == PhaseStatus.current;
  bool get isCompleted => status == PhaseStatus.completed;
  bool get isLocked => status == PhaseStatus.locked;
}
