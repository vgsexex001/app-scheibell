/// Status de um evento na timeline
enum TimelineEventStatus {
  completed,
  current,
  upcoming,
}

/// Tipo de evento na timeline
enum TimelineEventType {
  surgery,
  appointment,
  milestone,
  task,
  medication,
  exam,
}

/// Entidade que representa um evento na timeline de recuperação
class TimelineEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimelineEventStatus status;
  final TimelineEventType type;
  final int? dayNumber;
  final bool isImportant;
  final Map<String, dynamic>? metadata;

  const TimelineEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.status,
    required this.type,
    this.dayNumber,
    this.isImportant = false,
    this.metadata,
  });

  /// Retorna o rótulo do dia (ex: "D+7", "D+14", "Cirurgia")
  String get dayLabel {
    if (type == TimelineEventType.surgery) {
      return 'Cirurgia';
    }
    if (dayNumber != null) {
      return 'D+$dayNumber';
    }
    return '';
  }

  /// Retorna se o evento está no passado
  bool get isPast => status == TimelineEventStatus.completed;

  /// Retorna se o evento é atual
  bool get isCurrent => status == TimelineEventStatus.current;

  /// Retorna se o evento é futuro
  bool get isFuture => status == TimelineEventStatus.upcoming;

  /// Retorna o nome do tipo de evento
  String get typeLabel {
    switch (type) {
      case TimelineEventType.surgery:
        return 'Cirurgia';
      case TimelineEventType.appointment:
        return 'Consulta';
      case TimelineEventType.milestone:
        return 'Marco';
      case TimelineEventType.task:
        return 'Tarefa';
      case TimelineEventType.medication:
        return 'Medicação';
      case TimelineEventType.exam:
        return 'Exame';
    }
  }

  TimelineEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimelineEventStatus? status,
    TimelineEventType? type,
    int? dayNumber,
    bool? isImportant,
    Map<String, dynamic>? metadata,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      type: type ?? this.type,
      dayNumber: dayNumber ?? this.dayNumber,
      isImportant: isImportant ?? this.isImportant,
      metadata: metadata ?? this.metadata,
    );
  }
}
