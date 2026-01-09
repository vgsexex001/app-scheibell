/// Enum para ações de override
enum OverrideAction {
  add,
  disable,
  modify;

  static OverrideAction fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADD':
        return OverrideAction.add;
      case 'DISABLE':
        return OverrideAction.disable;
      case 'MODIFY':
        return OverrideAction.modify;
      default:
        return OverrideAction.add;
    }
  }

  String toJsonString() => name.toUpperCase();
}

/// Model que representa uma personalização de conteúdo para um paciente específico
/// Permite ADD (adicionar novo), DISABLE (desabilitar template), MODIFY (modificar template)
class PatientContentOverride {
  final String id;
  final String patientId;
  final String? templateId;
  final OverrideAction action;
  final String? type; // Obrigatório para ADD
  final String? category;
  final String? title;
  final String? description;
  final int? validFromDay;
  final int? validUntilDay;
  final String? reason;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  PatientContentOverride({
    required this.id,
    required this.patientId,
    this.templateId,
    required this.action,
    this.type,
    this.category,
    this.title,
    this.description,
    this.validFromDay,
    this.validUntilDay,
    this.reason,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory PatientContentOverride.fromJson(Map<String, dynamic> json) {
    return PatientContentOverride(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      templateId: json['templateId'] as String?,
      action: OverrideAction.fromString(json['action'] as String? ?? 'ADD'),
      type: json['type'] as String?,
      category: json['category'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      validFromDay: json['validFromDay'] as int?,
      validUntilDay: json['validUntilDay'] as int?,
      reason: json['reason'] as String?,
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
        'patientId': patientId,
        if (templateId != null) 'templateId': templateId,
        'action': action.toJsonString(),
        if (type != null) 'type': type,
        if (category != null) 'category': category,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
        if (reason != null) 'reason': reason,
        'isActive': isActive,
      };

  PatientContentOverride copyWith({
    String? templateId,
    OverrideAction? action,
    String? type,
    String? category,
    String? title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
    String? reason,
    bool? isActive,
  }) {
    return PatientContentOverride(
      id: id,
      patientId: patientId,
      templateId: templateId ?? this.templateId,
      action: action ?? this.action,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      validFromDay: validFromDay ?? this.validFromDay,
      validUntilDay: validUntilDay ?? this.validUntilDay,
      reason: reason ?? this.reason,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
    );
  }

  /// Retorna label legível para a ação
  String get actionLabel {
    switch (action) {
      case OverrideAction.add:
        return 'Adicionado';
      case OverrideAction.disable:
        return 'Desabilitado';
      case OverrideAction.modify:
        return 'Modificado';
    }
  }
}
