/// Status de um agendamento
enum AppointmentStatus {
  confirmed,
  pending,
  cancelled,
  completed;

  String get apiValue {
    switch (this) {
      case AppointmentStatus.confirmed:
        return 'CONFIRMED';
      case AppointmentStatus.pending:
        return 'PENDING';
      case AppointmentStatus.cancelled:
        return 'CANCELLED';
      case AppointmentStatus.completed:
        return 'COMPLETED';
    }
  }

  static AppointmentStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'CONFIRMED':
        return AppointmentStatus.confirmed;
      case 'PENDING':
        return AppointmentStatus.pending;
      case 'CANCELLED':
        return AppointmentStatus.cancelled;
      case 'COMPLETED':
        return AppointmentStatus.completed;
      default:
        return AppointmentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.confirmed:
        return 'Confirmado';
      case AppointmentStatus.pending:
        return 'Pendente';
      case AppointmentStatus.cancelled:
        return 'Cancelado';
      case AppointmentStatus.completed:
        return 'Realizado';
    }
  }
}

/// Tipo de agendamento
enum AppointmentType {
  consultation,
  external;

  String get apiValue {
    switch (this) {
      case AppointmentType.consultation:
        return 'CONSULTATION';
      case AppointmentType.external:
        return 'EXTERNAL';
    }
  }

  static AppointmentType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'CONSULTATION':
      case 'RETURN':
      case 'FOLLOW_UP':
        return AppointmentType.consultation;
      case 'EXTERNAL':
      case 'PHYSIOTHERAPY':
        return AppointmentType.external;
      default:
        return AppointmentType.consultation;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentType.consultation:
        return 'Consulta';
      case AppointmentType.external:
        return 'Evento Externo';
    }
  }
}

/// Configuração de notificação
class NotificationConfig {
  final String id;
  final Duration before;
  final String label;

  const NotificationConfig({
    required this.id,
    required this.before,
    required this.label,
  });

  static const List<NotificationConfig> defaults = [
    NotificationConfig(
      id: '1w',
      before: Duration(days: 7),
      label: '1 semana antes',
    ),
    NotificationConfig(
      id: '1d',
      before: Duration(days: 1),
      label: '1 dia antes',
    ),
    NotificationConfig(
      id: '1h',
      before: Duration(hours: 1),
      label: '1 hora antes',
    ),
    NotificationConfig(
      id: '30m',
      before: Duration(minutes: 30),
      label: '30 minutos antes',
    ),
  ];
}

/// Entidade de Agendamento (Consulta da clínica)
class Appointment {
  final String id;
  final String title;
  final String? doctorName;
  final DateTime date;
  final String time;
  final String location;
  final AppointmentStatus status;
  final AppointmentType type;
  final List<NotificationConfig> notifications;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Appointment({
    required this.id,
    required this.title,
    this.doctorName,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
    required this.type,
    this.notifications = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isConsultation => type == AppointmentType.consultation;
  bool get isExternal => type == AppointmentType.external;
  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isCompleted => status == AppointmentStatus.completed;

  DateTime get dateTime {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Appointment copyWith({
    String? id,
    String? title,
    String? doctorName,
    DateTime? date,
    String? time,
    String? location,
    AppointmentStatus? status,
    AppointmentType? type,
    List<NotificationConfig>? notifications,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      doctorName: doctorName ?? this.doctorName,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      status: status ?? this.status,
      type: type ?? this.type,
      notifications: notifications ?? this.notifications,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Appointment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Entidade de Evento Externo (criado pelo usuário)
class ExternalEvent {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  final String? location;
  final String? notes;
  final List<NotificationConfig> notifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExternalEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.location,
    this.notes,
    this.notifications = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime get dateTime {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  ExternalEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? time,
    String? location,
    String? notes,
    List<NotificationConfig>? notifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExternalEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      notifications: notifications ?? this.notifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Item genérico de agenda (pode ser Appointment ou ExternalEvent)
sealed class AgendaItem {
  String get id;
  String get title;
  DateTime get date;
  String get time;
  String? get location;
  String? get notes;
  DateTime get dateTime;
  bool get isPast;
  bool get isToday;
}

/// Wrapper para Appointment como AgendaItem
class AppointmentItem implements AgendaItem {
  final Appointment appointment;

  const AppointmentItem(this.appointment);

  @override
  String get id => appointment.id;
  @override
  String get title => appointment.title;
  @override
  DateTime get date => appointment.date;
  @override
  String get time => appointment.time;
  @override
  String? get location => appointment.location;
  @override
  String? get notes => appointment.notes;
  @override
  DateTime get dateTime => appointment.dateTime;
  @override
  bool get isPast => appointment.isPast;
  @override
  bool get isToday => appointment.isToday;
}

/// Wrapper para ExternalEvent como AgendaItem
class ExternalEventItem implements AgendaItem {
  final ExternalEvent event;

  const ExternalEventItem(this.event);

  @override
  String get id => event.id;
  @override
  String get title => event.title;
  @override
  DateTime get date => event.date;
  @override
  String get time => event.time;
  @override
  String? get location => event.location;
  @override
  String? get notes => event.notes;
  @override
  DateTime get dateTime => event.dateTime;
  @override
  bool get isPast => event.isPast;
  @override
  bool get isToday => event.isToday;
}
