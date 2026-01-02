/// Status da semana de treino
enum TrainingWeekStatus {
  completed,
  current,
  locked,
}

/// Entidade que representa uma semana do protocolo de treino
class TrainingWeek {
  final int weekNumber;
  final String title;
  final String dayRange;
  final TrainingWeekStatus status;
  final String objective;
  final int? maxHeartRate;
  final String? heartRateLabel;
  final List<String> canDo;
  final List<String> avoid;
  final List<String>? safetyCriteria;

  const TrainingWeek({
    required this.weekNumber,
    required this.title,
    required this.dayRange,
    required this.status,
    required this.objective,
    this.maxHeartRate,
    this.heartRateLabel,
    this.canDo = const [],
    this.avoid = const [],
    this.safetyCriteria,
  });

  /// Retorna se a semana está completa
  bool get isCompleted => status == TrainingWeekStatus.completed;

  /// Retorna se é a semana atual
  bool get isCurrent => status == TrainingWeekStatus.current;

  /// Retorna se está bloqueada
  bool get isLocked => status == TrainingWeekStatus.locked;

  /// Retorna a frequência cardíaca formatada
  String get heartRateDisplay {
    if (maxHeartRate != null) {
      return '$maxHeartRate bpm';
    }
    return 'Sem limite';
  }

  /// Cria a partir de um Map (resposta da API)
  factory TrainingWeek.fromMap(Map<String, dynamic> map) {
    TrainingWeekStatus status;
    final statusStr = map['status'] as String? ?? 'FUTURE';
    switch (statusStr.toUpperCase()) {
      case 'COMPLETED':
        status = TrainingWeekStatus.completed;
        break;
      case 'CURRENT':
        status = TrainingWeekStatus.current;
        break;
      default:
        status = TrainingWeekStatus.locked;
    }

    return TrainingWeek(
      weekNumber: map['weekNumber'] as int? ?? 1,
      title: map['title'] as String? ?? 'Semana ${map['weekNumber'] ?? 1}',
      dayRange: map['dayRange'] as String? ?? '',
      status: status,
      objective: map['objective'] as String? ?? '',
      maxHeartRate: map['maxHeartRate'] as int?,
      heartRateLabel: map['heartRateLabel'] as String?,
      canDo: List<String>.from(map['canDo'] ?? []),
      avoid: List<String>.from(map['avoid'] ?? []),
      safetyCriteria: map['safetyCriteria'] != null
          ? List<String>.from(map['safetyCriteria'])
          : null,
    );
  }

  TrainingWeek copyWith({
    int? weekNumber,
    String? title,
    String? dayRange,
    TrainingWeekStatus? status,
    String? objective,
    int? maxHeartRate,
    String? heartRateLabel,
    List<String>? canDo,
    List<String>? avoid,
    List<String>? safetyCriteria,
  }) {
    return TrainingWeek(
      weekNumber: weekNumber ?? this.weekNumber,
      title: title ?? this.title,
      dayRange: dayRange ?? this.dayRange,
      status: status ?? this.status,
      objective: objective ?? this.objective,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      heartRateLabel: heartRateLabel ?? this.heartRateLabel,
      canDo: canDo ?? this.canDo,
      avoid: avoid ?? this.avoid,
      safetyCriteria: safetyCriteria ?? this.safetyCriteria,
    );
  }
}
