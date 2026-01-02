import '../../domain/entities/appointment.dart';

/// Modelo de dados para Appointment (conversão JSON)
class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
    required super.title,
    super.doctorName,
    required super.date,
    required super.time,
    required super.location,
    required super.status,
    required super.type,
    super.notifications,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      doctorName: json['doctorName'] as String?,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      location: json['location'] as String? ?? 'Local a definir',
      status: AppointmentStatus.fromApi(json['status'] as String? ?? 'PENDING'),
      type: AppointmentType.fromApi(json['type'] as String? ?? 'CONSULTATION'),
      notifications: _parseNotifications(json['notifications']),
      notes: json['notes'] as String? ?? json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'doctorName': doctorName,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'location': location,
      'status': status.apiValue,
      'type': type.apiValue,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<NotificationConfig> _parseNotifications(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];

    return data.map((item) {
      if (item is Map<String, dynamic>) {
        return NotificationConfig(
          id: item['id'] as String? ?? '',
          before: Duration(minutes: item['beforeMinutes'] as int? ?? 60),
          label: item['label'] as String? ?? '',
        );
      }
      return NotificationConfig.defaults.first;
    }).toList();
  }

  Appointment toEntity() {
    return Appointment(
      id: id,
      title: title,
      doctorName: doctorName,
      date: date,
      time: time,
      location: location,
      status: status,
      type: type,
      notifications: notifications,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AppointmentModel.fromEntity(Appointment entity) {
    return AppointmentModel(
      id: entity.id,
      title: entity.title,
      doctorName: entity.doctorName,
      date: entity.date,
      time: entity.time,
      location: entity.location,
      status: entity.status,
      type: entity.type,
      notifications: entity.notifications,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Modelo de dados para ExternalEvent (conversão JSON)
class ExternalEventModel extends ExternalEvent {
  const ExternalEventModel({
    required super.id,
    required super.title,
    required super.date,
    required super.time,
    super.location,
    super.notes,
    super.notifications,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ExternalEventModel.fromJson(Map<String, dynamic> json) {
    return ExternalEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      location: json['location'] as String?,
      notes: json['notes'] as String? ?? json['description'] as String?,
      notifications: _parseNotifications(json['notifications']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'location': location,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<NotificationConfig> _parseNotifications(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];

    return data.map((item) {
      if (item is Map<String, dynamic>) {
        return NotificationConfig(
          id: item['id'] as String? ?? '',
          before: Duration(minutes: item['beforeMinutes'] as int? ?? 60),
          label: item['label'] as String? ?? '',
        );
      }
      return NotificationConfig.defaults.first;
    }).toList();
  }

  ExternalEvent toEntity() {
    return ExternalEvent(
      id: id,
      title: title,
      date: date,
      time: time,
      location: location,
      notes: notes,
      notifications: notifications,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ExternalEventModel.fromEntity(ExternalEvent entity) {
    return ExternalEventModel(
      id: entity.id,
      title: entity.title,
      date: entity.date,
      time: entity.time,
      location: entity.location,
      notes: entity.notes,
      notifications: entity.notifications,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
