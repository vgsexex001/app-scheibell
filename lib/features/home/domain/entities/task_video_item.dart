/// Tipo do item (tarefa ou vídeo)
enum TaskVideoType { task, video }

/// Prioridade para tarefas
enum TaskPriority { low, medium, high }

/// Representa uma tarefa ou vídeo
class TaskVideoItem {
  final String id;
  final String title;
  final String? description;
  final TaskVideoType type;
  final String? duration; // Para vídeos: "5:30", "10:00"
  final TaskPriority priority; // Para tarefas
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool completed;
  final DateTime? completedAt;
  final int? validFromDay;
  final int? validUntilDay;
  final int sortOrder;

  const TaskVideoItem({
    required this.id,
    required this.title,
    this.description,
    this.type = TaskVideoType.task,
    this.duration,
    this.priority = TaskPriority.medium,
    this.videoUrl,
    this.thumbnailUrl,
    this.completed = false,
    this.completedAt,
    this.validFromDay,
    this.validUntilDay,
    this.sortOrder = 0,
  });

  bool get isVideo => type == TaskVideoType.video;
  bool get isTask => type == TaskVideoType.task;

  /// Ícone baseado no tipo
  String get iconName => isVideo ? 'play_circle' : 'assignment';

  /// Label da prioridade
  String get priorityLabel {
    switch (priority) {
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.medium:
        return 'Média';
      case TaskPriority.low:
        return 'Baixa';
    }
  }

  TaskVideoItem copyWith({
    String? id,
    String? title,
    String? description,
    TaskVideoType? type,
    String? duration,
    TaskPriority? priority,
    String? videoUrl,
    String? thumbnailUrl,
    bool? completed,
    DateTime? completedAt,
    int? validFromDay,
    int? validUntilDay,
    int? sortOrder,
  }) {
    return TaskVideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      priority: priority ?? this.priority,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      validFromDay: validFromDay ?? this.validFromDay,
      validUntilDay: validUntilDay ?? this.validUntilDay,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'duration': duration,
      'priority': priority.name,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'validFromDay': validFromDay,
      'validUntilDay': validUntilDay,
      'sortOrder': sortOrder,
    };
  }

  factory TaskVideoItem.fromJson(Map<String, dynamic> json) {
    TaskVideoType type = TaskVideoType.task;
    if (json['type'] == 'video') {
      type = TaskVideoType.video;
    }

    TaskPriority priority = TaskPriority.medium;
    if (json['priority'] == 'high') {
      priority = TaskPriority.high;
    } else if (json['priority'] == 'low') {
      priority = TaskPriority.low;
    }

    return TaskVideoItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: type,
      duration: json['duration'],
      priority: priority,
      videoUrl: json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      validFromDay: json['validFromDay'],
      validUntilDay: json['validUntilDay'],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  /// Cria TaskVideoItem a partir de ContentItem do backend
  factory TaskVideoItem.fromContentItem(Map<String, dynamic> json) {
    // Detecta se é vídeo pela descrição ou título
    final description = (json['description'] as String? ?? '').toLowerCase();
    final title = (json['title'] as String? ?? '').toLowerCase();
    final isVideo = description.contains('vídeo') ||
        description.contains('video') ||
        description.contains('assistir') ||
        title.contains('vídeo') ||
        title.contains('video');

    // Extrai duração se for vídeo
    String? duration;
    if (isVideo) {
      final durationMatch =
          RegExp(r'(\d+:\d+|\d+\s*min)').firstMatch(description);
      if (durationMatch != null) {
        duration = durationMatch.group(1);
      }
    }

    // Detecta prioridade
    TaskPriority priority = TaskPriority.medium;
    if (description.contains('importante') ||
        description.contains('urgente') ||
        description.contains('obrigatório')) {
      priority = TaskPriority.high;
    } else if (description.contains('opcional')) {
      priority = TaskPriority.low;
    }

    return TaskVideoItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: isVideo ? TaskVideoType.video : TaskVideoType.task,
      duration: duration,
      priority: priority,
      validFromDay: json['validFromDay'],
      validUntilDay: json['validUntilDay'],
      sortOrder: json['sortOrder'] ?? 0,
      completed: false,
    );
  }
}
