/// Model que representa um conteúdo da clínica
/// Baseado na estrutura do backend: ContentType e ContentCategory
class ClinicContent {
  final String id;
  final String type; // SYMPTOMS, DIET, ACTIVITIES, CARE, TRAINING, EXAMS, DOCUMENTS, MEDICATIONS, DIARY
  final String category; // NORMAL, WARNING, EMERGENCY, ALLOWED, RESTRICTED, PROHIBITED, INFO
  final String title;
  final String? description;
  final int? validFromDay;
  final int? validUntilDay;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClinicContent({
    required this.id,
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
  });

  factory ClinicContent.fromJson(Map<String, dynamic> json) {
    return ClinicContent(
      id: json['id'] as String,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'category': category,
        'title': title,
        if (description != null) 'description': description,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
      };

  ClinicContent copyWith({
    String? title,
    String? description,
    String? category,
    int? validFromDay,
    int? validUntilDay,
    bool? isActive,
  }) {
    return ClinicContent(
      id: id,
      type: type,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      validFromDay: validFromDay ?? this.validFromDay,
      validUntilDay: validUntilDay ?? this.validUntilDay,
      sortOrder: sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
