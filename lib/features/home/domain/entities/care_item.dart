/// Representa um item de cuidado (checklist)
class CareItem {
  final String id;
  final String title;
  final String? description;
  final String? category; // NORMAL, WARNING, EMERGENCY
  final bool completed;
  final DateTime? completedAt;
  final int? validFromDay;
  final int? validUntilDay;
  final int sortOrder;

  const CareItem({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.completed = false,
    this.completedAt,
    this.validFromDay,
    this.validUntilDay,
    this.sortOrder = 0,
  });

  /// Verifica se é um item de alerta/atenção
  bool get isWarning => category == 'WARNING';

  /// Verifica se é emergência
  bool get isEmergency => category == 'EMERGENCY';

  CareItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? completed,
    DateTime? completedAt,
    int? validFromDay,
    int? validUntilDay,
    int? sortOrder,
  }) {
    return CareItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
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
      'category': category,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'validFromDay': validFromDay,
      'validUntilDay': validUntilDay,
      'sortOrder': sortOrder,
    };
  }

  factory CareItem.fromJson(Map<String, dynamic> json) {
    return CareItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      validFromDay: json['validFromDay'],
      validUntilDay: json['validUntilDay'],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  /// Cria CareItem a partir de ContentItem do backend
  factory CareItem.fromContentItem(Map<String, dynamic> json) {
    return CareItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      validFromDay: json['validFromDay'],
      validUntilDay: json['validUntilDay'],
      sortOrder: json['sortOrder'] ?? 0,
      completed: false,
    );
  }
}
