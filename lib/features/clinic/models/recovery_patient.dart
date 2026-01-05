class RecoveryPatient {
  final String patientId;
  final String patientName;
  final String procedureType;
  final int dayPostOp;
  final int progressPercent;
  final String? nextAppointmentAt;
  final String nextAppointmentLabel;

  RecoveryPatient({
    required this.patientId,
    required this.patientName,
    required this.procedureType,
    required this.dayPostOp,
    required this.progressPercent,
    this.nextAppointmentAt,
    required this.nextAppointmentLabel,
  });

  factory RecoveryPatient.fromJson(Map<String, dynamic> json) {
    return RecoveryPatient(
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      procedureType: json['procedureType'] ?? '',
      dayPostOp: json['dayPostOp'] ?? 0,
      progressPercent: json['progressPercent'] ?? 0,
      nextAppointmentAt: json['nextAppointmentAt'],
      nextAppointmentLabel: json['nextAppointmentLabel'] ?? 'Sem consultas',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'procedureType': procedureType,
      'dayPostOp': dayPostOp,
      'progressPercent': progressPercent,
      'nextAppointmentAt': nextAppointmentAt,
      'nextAppointmentLabel': nextAppointmentLabel,
    };
  }
}

class RecoveryPatientsResponse {
  final List<RecoveryPatient> items;
  final int page;
  final int limit;
  final int total;

  RecoveryPatientsResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory RecoveryPatientsResponse.fromJson(Map<String, dynamic> json) {
    return RecoveryPatientsResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => RecoveryPatient.fromJson(e))
              .toList() ??
          [],
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
    );
  }
}
