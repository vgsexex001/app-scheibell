/// Model que representa um template de conteúdo da clínica
/// Templates são a base de conteúdo que pode ser personalizado por paciente
class ContentTemplate {
  final String id;
  final String clinicId;
  final String type; // SYMPTOMS, DIET, ACTIVITIES, CARE, TRAINING, EXAMS, DOCUMENTS, MEDICATIONS
  final String category; // NORMAL, WARNING, EMERGENCY, ALLOWED, RESTRICTED, PROHIBITED, INFO
  final String title;
  final String? description;
  final int? validFromDay;
  final int? validUntilDay;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  ContentTemplate({
    required this.id,
    required this.clinicId,
    required this.type,
    required this.category,
    required this.title,
    this.description,
    this.validFromDay,
    this.validUntilDay,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory ContentTemplate.fromJson(Map<String, dynamic> json) {
    return ContentTemplate(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      type: json['type'] as String? ?? 'SYMPTOMS',
      category: json['category'] as String? ?? 'INFO',
      title: json['title'] as String,
      description: json['description'] as String?,
      validFromDay: json['validFromDay'] as int?,
      validUntilDay: json['validUntilDay'] as int?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clinicId': clinicId,
        'type': type,
        'category': category,
        'title': title,
        if (description != null) 'description': description,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  ContentTemplate copyWith({
    String? type,
    String? category,
    String? title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
    int? sortOrder,
    bool? isActive,
  }) {
    return ContentTemplate(
      id: id,
      clinicId: clinicId,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      validFromDay: validFromDay ?? this.validFromDay,
      validUntilDay: validUntilDay ?? this.validUntilDay,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
    );
  }
}
