/// Representa um slot de horário disponível para agendamento
class TimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String appointmentType;
  final SlotStatus status;
  final String? blockedReason;
  final Map<String, dynamic>? appointment;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.appointmentType,
    required this.status,
    this.blockedReason,
    this.appointment,
  });

  bool get isAvailable => status == SlotStatus.available;

  String get timeString {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      appointmentType: json['appointmentType'] ?? '',
      status: SlotStatus.fromString(json['status'] ?? 'available'),
      blockedReason: json['blockedReason'],
      appointment: json['appointment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'appointmentType': appointmentType,
      'status': status.value,
      'blockedReason': blockedReason,
      'appointment': appointment,
    };
  }
}

/// Status de um slot de horário
enum SlotStatus {
  available('available'),
  occupied('occupied'),
  blocked('blocked'),
  outsideHours('outsideHours'),
  pastTime('pastTime');

  final String value;
  const SlotStatus(this.value);

  static SlotStatus fromString(String value) {
    return SlotStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SlotStatus.available,
    );
  }
}

/// Representa um dia com informações de disponibilidade
class AvailableDay {
  final DateTime date;
  final bool hasAvailableSlots;
  final int totalSlots;
  final int availableSlots;
  final int occupiedSlots;
  final Map<String, int> slotsByType;

  AvailableDay({
    required this.date,
    required this.hasAvailableSlots,
    this.totalSlots = 0,
    this.availableSlots = 0,
    this.occupiedSlots = 0,
    this.slotsByType = const {},
  });

  factory AvailableDay.fromJson(Map<String, dynamic> json) {
    return AvailableDay(
      date: DateTime.parse(json['date']),
      hasAvailableSlots: json['hasAvailableSlots'] ?? false,
      totalSlots: json['totalSlots'] ?? 0,
      availableSlots: json['availableSlots'] ?? 0,
      occupiedSlots: json['occupiedSlots'] ?? 0,
      slotsByType: Map<String, int>.from(json['slotsByType'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'hasAvailableSlots': hasAvailableSlots,
      'totalSlots': totalSlots,
      'availableSlots': availableSlots,
      'occupiedSlots': occupiedSlots,
      'slotsByType': slotsByType,
    };
  }
}
