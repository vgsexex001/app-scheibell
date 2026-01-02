enum UserRole {
  patient,
  clinicAdmin,
  clinicStaff,
  thirdParty,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? cpf;
  final String? avatarUrl;
  final UserRole role;
  final String? clinicId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? surgeryDate;
  final DateTime? birthDate;
  final String? surgeryType;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.cpf,
    this.avatarUrl,
    required this.role,
    this.clinicId,
    this.createdAt,
    this.updatedAt,
    this.surgeryDate,
    this.birthDate,
    this.surgeryType,
  });

  /// Calcula os dias pós-operatório
  int get daysPostOp {
    final surgery = surgeryDate ?? createdAt ?? DateTime.now();
    return DateTime.now().difference(surgery).inDays;
  }

  /// Retorna o primeiro nome do usuário
  String get firstName {
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts.first : name;
  }

  bool get isPatient => role == UserRole.patient;
  bool get isClinicAdmin => role == UserRole.clinicAdmin;
  bool get isClinicStaff => role == UserRole.clinicStaff;
  bool get isThirdParty => role == UserRole.thirdParty;
  bool get isClinicMember => isClinicAdmin || isClinicStaff;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? cpf,
    String? avatarUrl,
    UserRole? role,
    String? clinicId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? surgeryDate,
    DateTime? birthDate,
    String? surgeryType,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cpf: cpf ?? this.cpf,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      clinicId: clinicId ?? this.clinicId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      surgeryDate: surgeryDate ?? this.surgeryDate,
      birthDate: birthDate ?? this.birthDate,
      surgeryType: surgeryType ?? this.surgeryType,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Converte role string do backend (PATIENT, CLINIC_ADMIN, etc.) para enum
    UserRole parseRole(String? roleStr) {
      if (roleStr == null) return UserRole.patient;
      switch (roleStr.toUpperCase()) {
        case 'PATIENT':
          return UserRole.patient;
        case 'CLINIC_ADMIN':
          return UserRole.clinicAdmin;
        case 'CLINIC_STAFF':
          return UserRole.clinicStaff;
        case 'THIRD_PARTY':
          return UserRole.thirdParty;
        default:
          return UserRole.patient;
      }
    }

    // Extrair dados do paciente se existirem
    final patient = json['patient'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: patient?['phone'] as String? ?? json['phone'] as String?,
      cpf: patient?['cpf'] as String? ?? json['cpf'] as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      role: parseRole(json['role'] as String?),
      clinicId: (json['clinic_id'] ?? json['clinicId']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null),
      surgeryDate: _parseDate(patient?['surgeryDate'] ?? patient?['surgery_date'] ?? json['surgeryDate'] ?? json['surgery_date']),
      birthDate: _parseDate(patient?['birthDate'] ?? patient?['birth_date'] ?? json['birthDate'] ?? json['birth_date']),
      surgeryType: patient?['surgeryType'] as String? ?? patient?['surgery_type'] as String? ?? json['surgeryType'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'cpf': cpf,
      'avatar_url': avatarUrl,
      'role': role.name,
      'clinic_id': clinicId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'surgery_date': surgeryDate?.toIso8601String(),
      'birth_date': birthDate?.toIso8601String(),
      'surgery_type': surgeryType,
    };
  }
}
