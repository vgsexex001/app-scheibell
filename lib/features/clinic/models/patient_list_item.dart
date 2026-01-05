class PatientListItem {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? surgeryType;
  final String? surgeryDate;
  final int? dayPostOp;
  final String status;
  final PatientNextAppointment? nextAppointment;

  PatientListItem({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.surgeryType,
    this.surgeryDate,
    this.dayPostOp,
    required this.status,
    this.nextAppointment,
  });

  factory PatientListItem.fromJson(Map<String, dynamic> json) {
    return PatientListItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Nome não informado',
      email: json['email'] ?? '',
      phone: json['phone'],
      surgeryType: json['surgeryType'],
      surgeryDate: json['surgeryDate'],
      dayPostOp: json['dayPostOp'],
      status: json['status'] ?? 'ACTIVE',
      nextAppointment: json['nextAppointment'] != null
          ? PatientNextAppointment.fromJson(json['nextAppointment'])
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'RECOVERY':
        return 'Em Recuperação';
      case 'COMPLETED':
        return 'Concluído';
      case 'ACTIVE':
      default:
        return 'Ativo';
    }
  }

  String get dayPostOpLabel {
    if (dayPostOp == null) return '';
    if (dayPostOp == 0) return 'D+0';
    return 'D+$dayPostOp';
  }
}

class PatientNextAppointment {
  final String id;
  final String date;
  final String time;
  final String title;

  PatientNextAppointment({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
  });

  factory PatientNextAppointment.fromJson(Map<String, dynamic> json) {
    return PatientNextAppointment(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      title: json['title'] ?? '',
    );
  }

  String get displayDate {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }
}

class PatientsListResponse {
  final List<PatientListItem> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PatientsListResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PatientsListResponse.fromJson(Map<String, dynamic> json) {
    return PatientsListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PatientListItem.fromJson(e))
              .toList() ??
          [],
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
