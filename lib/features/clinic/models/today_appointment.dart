/// Model para agendamento de hoje
class TodayAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String procedureType;
  final String time;
  final String status;

  TodayAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.procedureType,
    required this.time,
    required this.status,
  });

  factory TodayAppointment.fromJson(Map<String, dynamic> json) {
    return TodayAppointment(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Paciente',
      procedureType: json['procedureType'] ?? 'Consulta',
      time: json['time'] ?? '00:00',
      status: json['status'] ?? 'PENDING',
    );
  }
}

/// Response de agendamentos de hoje
class TodayAppointmentsResponse {
  final List<TodayAppointment> items;
  final int total;

  TodayAppointmentsResponse({
    required this.items,
    required this.total,
  });

  factory TodayAppointmentsResponse.fromJson(Map<String, dynamic> json) {
    return TodayAppointmentsResponse(
      items: (json['items'] as List?)
              ?.map((item) => TodayAppointment.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}
