/// Modelo de alergia do paciente
class PatientAllergy {
  final String id;
  final String name;
  final String? severity;
  final String? notes;
  final String createdAt;

  PatientAllergy({
    required this.id,
    required this.name,
    this.severity,
    this.notes,
    required this.createdAt,
  });

  factory PatientAllergy.fromJson(Map<String, dynamic> json) {
    return PatientAllergy(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      severity: json['severity'],
      notes: json['notes'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'severity': severity,
    'notes': notes,
    'createdAt': createdAt,
  };

  String get severityLabel {
    switch (severity) {
      case 'MILD':
        return 'Leve';
      case 'MODERATE':
        return 'Moderada';
      case 'SEVERE':
        return 'Grave';
      default:
        return 'Não especificada';
    }
  }
}

/// Modelo de nota médica do paciente
class MedicalNote {
  final String id;
  final String content;
  final String? author;
  final String? authorId;
  final String createdAt;

  MedicalNote({
    required this.id,
    required this.content,
    this.author,
    this.authorId,
    required this.createdAt,
  });

  factory MedicalNote.fromJson(Map<String, dynamic> json) {
    return MedicalNote(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      author: json['author'],
      authorId: json['authorId'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'author': author,
    'authorId': authorId,
    'createdAt': createdAt,
  };

  String get displayDate {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }
}

class PatientDetail {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? birthDate;
  final String? cpf;
  final String? address;
  final String? surgeryType;
  final String? surgeryDate;
  final String? surgeon;
  final int? dayPostOp;
  final int? weekPostOp;
  final int? adherenceRate;
  // Novos campos do banco
  final String? bloodType;
  final double? weightKg;
  final double? heightCm;
  final String? emergencyContact;
  final String? emergencyPhone;
  // Alergias como objetos
  final List<PatientAllergy> allergies;
  // Notas médicas como objetos
  final List<MedicalNote> medicalNotes;
  final List<PatientAppointment> upcomingAppointments;
  final List<PatientAppointment> pastAppointments;
  final List<PatientAlert> recentAlerts;

  PatientDetail({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.birthDate,
    this.cpf,
    this.address,
    this.surgeryType,
    this.surgeryDate,
    this.surgeon,
    this.dayPostOp,
    this.weekPostOp,
    this.adherenceRate,
    this.bloodType,
    this.weightKg,
    this.heightCm,
    this.emergencyContact,
    this.emergencyPhone,
    this.allergies = const [],
    this.medicalNotes = const [],
    this.upcomingAppointments = const [],
    this.pastAppointments = const [],
    this.recentAlerts = const [],
  });

  factory PatientDetail.fromJson(Map<String, dynamic> json) {
    return PatientDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['fullName']?.toString() ?? 'Nome não informado',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      birthDate: json['birthDate']?.toString(),
      cpf: json['cpf']?.toString(),
      address: json['address']?.toString(),
      surgeryType: json['surgeryType']?.toString(),
      surgeryDate: json['surgeryDate']?.toString(),
      surgeon: json['surgeon']?.toString(),
      dayPostOp: _parseInt(json['dayPostOp']),
      weekPostOp: _parseInt(json['weekPostOp']),
      adherenceRate: _parseInt(json['adherenceRate']),
      bloodType: json['bloodType']?.toString(),
      weightKg: _parseDouble(json['weightKg']),
      heightCm: _parseDouble(json['heightCm']),
      emergencyContact: json['emergencyContact']?.toString(),
      emergencyPhone: json['emergencyPhone']?.toString(),
      allergies: _parseList(json['allergies'], PatientAllergy.fromJson),
      medicalNotes: _parseList(json['medicalNotes'], MedicalNote.fromJson),
      upcomingAppointments: _parseList(json['upcomingAppointments'], PatientAppointment.fromJson),
      pastAppointments: _parseList(json['pastAppointments'], PatientAppointment.fromJson),
      recentAlerts: _parseList(json['recentAlerts'], PatientAlert.fromJson),
    );
  }

  // Helpers de parsing seguro
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<T> _parseList<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((e) {
          try {
            return fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }

  String get dayPostOpLabel {
    if (dayPostOp == null) return 'N/A';
    if (dayPostOp == 0) return 'D+0';
    return 'D+$dayPostOp';
  }

  String get weekPostOpLabel {
    if (weekPostOp == null) return 'N/A';
    return 'Semana $weekPostOp';
  }

  String get adherenceLabel {
    if (adherenceRate == null) return 'N/A';
    return '$adherenceRate%';
  }

  String get surgeryDateFormatted {
    if (surgeryDate == null) return 'Não informada';
    try {
      final dt = DateTime.parse(surgeryDate!);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return surgeryDate!;
    }
  }

  /// Calcula o IMC (Índice de Massa Corporal)
  double? get imc {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  /// Retorna o IMC formatado
  String get imcFormatted {
    final value = imc;
    if (value == null) return '-';
    return value.toStringAsFixed(1);
  }

  /// Retorna a classificação do IMC
  String get imcClassification {
    final value = imc;
    if (value == null) return '-';
    if (value < 18.5) return 'Abaixo do peso';
    if (value < 25) return 'Normal';
    if (value < 30) return 'Sobrepeso';
    if (value < 35) return 'Obesidade I';
    if (value < 40) return 'Obesidade II';
    return 'Obesidade III';
  }

  /// Lista de nomes de alergias (para compatibilidade)
  List<String> get allergyNames => allergies.map((a) => a.name).toList();

  /// Verifica se paciente tem alergias
  bool get hasAllergies => allergies.isNotEmpty;

  /// Verifica se paciente tem notas médicas
  bool get hasMedicalNotes => medicalNotes.isNotEmpty;
}

class PatientAppointment {
  final String id;
  final String title;
  final String? description;
  final String date;
  final String time;
  final String type;
  final String status;
  final String? location;
  final String? notes;

  PatientAppointment({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    this.location,
    this.notes,
  });

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    return PatientAppointment(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      location: json['location'],
      notes: json['notes'],
    );
  }

  String get displayDate {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return date;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'CONFIRMED':
        return 'Confirmada';
      case 'PENDING':
        return 'Pendente';
      case 'COMPLETED':
        return 'Concluída';
      case 'CANCELLED':
        return 'Cancelada';
      default:
        return status;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'RETURN_VISIT':
        return 'Retorno';
      case 'EVALUATION':
        return 'Avaliação';
      case 'PHYSIOTHERAPY':
        return 'Fisioterapia';
      case 'EXAM':
        return 'Exame';
      case 'OTHER':
        return 'Outro';
      default:
        return type;
    }
  }
}

class PatientAlert {
  final String id;
  final String type;
  final String title;
  final String? description;
  final String createdAt;

  PatientAlert({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory PatientAlert.fromJson(Map<String, dynamic> json) {
    return PatientAlert(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

/// Modelo para item do histórico do paciente
class PatientHistoryItem {
  final String type; // 'appointment', 'medical_note', 'alert'
  final String date;
  final Map<String, dynamic> data;

  PatientHistoryItem({
    required this.type,
    required this.date,
    required this.data,
  });

  factory PatientHistoryItem.fromJson(Map<String, dynamic> json) {
    return PatientHistoryItem(
      type: json['type'] ?? '',
      date: json['date'] ?? '',
      data: json['data'] ?? {},
    );
  }

  String get displayDate {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return date;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'appointment':
        return 'Consulta';
      case 'medical_note':
        return 'Nota Médica';
      case 'alert':
        return 'Alerta';
      default:
        return type;
    }
  }
}
