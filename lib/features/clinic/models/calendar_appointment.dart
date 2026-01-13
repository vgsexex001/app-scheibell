/// Model para agendamento do calendário
class CalendarAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String procedureType;
  final String consultationType;
  final DateTime date;
  final String time;
  final String status;
  final String notes;

  CalendarAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.procedureType,
    required this.consultationType,
    required this.date,
    required this.time,
    required this.status,
    required this.notes,
  });

  factory CalendarAppointment.fromJson(Map<String, dynamic> json) {
    return CalendarAppointment(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Paciente',
      procedureType: json['procedureType'] ?? 'Consulta',
      consultationType: json['consultationType'] ?? json['type'] ?? 'CONSULTATION',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      time: json['time'] ?? '00:00',
      status: json['status'] ?? 'PENDING',
      notes: json['notes'] ?? '',
    );
  }

  CalendarAppointment copyWith({
    String? patientName,
    String? procedureType,
    String? consultationType,
    String? status,
    DateTime? date,
    String? time,
    String? notes,
  }) {
    return CalendarAppointment(
      id: id,
      patientId: patientId,
      patientName: patientName ?? this.patientName,
      procedureType: procedureType ?? this.procedureType,
      consultationType: consultationType ?? this.consultationType,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

/// Response paginada de calendário
class CalendarResponse {
  final List<CalendarAppointment> items;
  final int month;
  final int year;
  final int total;

  CalendarResponse({
    required this.items,
    required this.month,
    required this.year,
    required this.total,
  });

  factory CalendarResponse.fromJson(Map<String, dynamic> json) {
    return CalendarResponse(
      items: (json['items'] as List?)
              ?.map((item) => CalendarAppointment.fromJson(item))
              .toList() ??
          [],
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      total: json['total'] ?? 0,
    );
  }
}
