class PendingAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String procedureType;
  final String startsAt;
  final String displayDate;
  final String displayTime;

  PendingAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.procedureType,
    required this.startsAt,
    required this.displayDate,
    required this.displayTime,
  });

  factory PendingAppointment.fromJson(Map<String, dynamic> json) {
    return PendingAppointment(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      procedureType: json['procedureType'] ?? '',
      startsAt: json['startsAt'] ?? '',
      displayDate: json['displayDate'] ?? '',
      displayTime: json['displayTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'procedureType': procedureType,
      'startsAt': startsAt,
      'displayDate': displayDate,
      'displayTime': displayTime,
    };
  }
}

class PendingAppointmentsResponse {
  final List<PendingAppointment> items;
  final int page;
  final int limit;
  final int total;

  PendingAppointmentsResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PendingAppointmentsResponse.fromJson(Map<String, dynamic> json) {
    return PendingAppointmentsResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PendingAppointment.fromJson(e))
              .toList() ??
          [],
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
    );
  }
}
