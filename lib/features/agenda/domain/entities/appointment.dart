import 'package:flutter/material.dart';

/// Status de um agendamento (Supabase enum)
enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  String get apiValue {
    switch (this) {
      case AppointmentStatus.pending:
        return 'PENDING';
      case AppointmentStatus.confirmed:
        return 'CONFIRMED';
      case AppointmentStatus.inProgress:
        return 'IN_PROGRESS';
      case AppointmentStatus.completed:
        return 'COMPLETED';
      case AppointmentStatus.cancelled:
        return 'CANCELLED';
      case AppointmentStatus.noShow:
        return 'NO_SHOW';
    }
  }

  static AppointmentStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return AppointmentStatus.pending;
      case 'CONFIRMED':
        return AppointmentStatus.confirmed;
      case 'IN_PROGRESS':
        return AppointmentStatus.inProgress;
      case 'COMPLETED':
        return AppointmentStatus.completed;
      case 'CANCELLED':
        return AppointmentStatus.cancelled;
      case 'NO_SHOW':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Aguardando';
      case AppointmentStatus.confirmed:
        return 'Confirmado';
      case AppointmentStatus.inProgress:
        return 'Em andamento';
      case AppointmentStatus.completed:
        return 'Concluído';
      case AppointmentStatus.cancelled:
        return 'Cancelado';
      case AppointmentStatus.noShow:
        return 'Não compareceu';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return const Color(0xFFFF9800);
      case AppointmentStatus.confirmed:
        return const Color(0xFF4CAF50);
      case AppointmentStatus.inProgress:
        return const Color(0xFF2196F3);
      case AppointmentStatus.completed:
        return const Color(0xFF9E9E9E);
      case AppointmentStatus.cancelled:
        return const Color(0xFFF44336);
      case AppointmentStatus.noShow:
        return const Color(0xFF795548);
    }
  }

  bool get canCancel => this == pending || this == confirmed;
}

/// Tipo de agendamento (Prisma enum)
/// Backend enum: SPLINT_REMOVAL, CONSULTATION, RETURN_VISIT, EVALUATION, PHYSIOTHERAPY, EXAM, OTHER
enum AppointmentType {
  splintRemoval,
  consultation,
  returnVisit,
  evaluation,
  physiotherapy,
  exam,
  other;

  String get apiValue {
    switch (this) {
      case AppointmentType.splintRemoval:
        return 'SPLINT_REMOVAL';
      case AppointmentType.consultation:
        return 'CONSULTATION';
      case AppointmentType.returnVisit:
        return 'RETURN_VISIT';
      case AppointmentType.evaluation:
        return 'EVALUATION';
      case AppointmentType.physiotherapy:
        return 'PHYSIOTHERAPY';
      case AppointmentType.exam:
        return 'EXAM';
      case AppointmentType.other:
        return 'OTHER';
    }
  }

  static AppointmentType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'SPLINT_REMOVAL':
        return AppointmentType.splintRemoval;
      case 'CONSULTATION':
        return AppointmentType.consultation;
      case 'RETURN_VISIT':
        return AppointmentType.returnVisit;
      case 'EVALUATION':
        return AppointmentType.evaluation;
      case 'PHYSIOTHERAPY':
        return AppointmentType.physiotherapy;
      case 'EXAM':
        return AppointmentType.exam;
      case 'OTHER':
        return AppointmentType.other;
      default:
        return AppointmentType.other;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentType.splintRemoval:
        return 'Retirada de Splint';
      case AppointmentType.consultation:
        return 'Consulta';
      case AppointmentType.returnVisit:
        return 'Retorno';
      case AppointmentType.evaluation:
        return 'Avaliação';
      case AppointmentType.physiotherapy:
        return 'Fisioterapia';
      case AppointmentType.exam:
        return 'Exame';
      case AppointmentType.other:
        return 'Outro';
    }
  }

  /// Gradiente de cor para cada tipo
  List<Color> get gradientColors {
    switch (this) {
      case AppointmentType.splintRemoval:
        return const [Color(0xFFFF9800), Color(0xFFF57C00)]; // Laranja
      case AppointmentType.consultation:
        return const [Color(0xFF2B7FFF), Color(0xFF155CFB)]; // Azul
      case AppointmentType.returnVisit:
        return const [Color(0xFF00C850), Color(0xFF00A63D)]; // Verde
      case AppointmentType.evaluation:
        return const [Color(0xFF795548), Color(0xFF5D4037)]; // Marrom
      case AppointmentType.physiotherapy:
        return const [Color(0xFFAC46FF), Color(0xFF980FFA)]; // Roxo
      case AppointmentType.exam:
        return const [Color(0xFF00BCD4), Color(0xFF0097A7)]; // Ciano
      case AppointmentType.other:
        return const [Color(0xFF9E9E9E), Color(0xFF757575)]; // Cinza
    }
  }

  /// Ícone para cada tipo
  IconData get icon {
    switch (this) {
      case AppointmentType.splintRemoval:
        return Icons.healing;
      case AppointmentType.consultation:
        return Icons.medical_services_outlined;
      case AppointmentType.returnVisit:
        return Icons.event_repeat;
      case AppointmentType.evaluation:
        return Icons.assignment;
      case AppointmentType.physiotherapy:
        return Icons.spa;
      case AppointmentType.exam:
        return Icons.science;
      case AppointmentType.other:
        return Icons.event_note;
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

  bool get isSplintRemoval => type == AppointmentType.splintRemoval;
  bool get isConsultation => type == AppointmentType.consultation;
  bool get isReturnVisit => type == AppointmentType.returnVisit;
  bool get isEvaluation => type == AppointmentType.evaluation;
  bool get isPhysiotherapy => type == AppointmentType.physiotherapy;
  bool get isExam => type == AppointmentType.exam;
  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isInProgress => status == AppointmentStatus.inProgress;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isNoShow => status == AppointmentStatus.noShow;
  bool get canCancel => status.canCancel;

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
