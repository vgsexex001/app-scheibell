import '../models/appointment_model.dart';
import '../../domain/entities/appointment.dart';
import 'agenda_datasource.dart';

/// Implementação mock do datasource para fallback offline
class AgendaMockDatasource implements AgendaDatasource {
  final List<AppointmentModel> _appointments = [];
  final List<ExternalEventModel> _externalEvents = [];

  AgendaMockDatasource() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _appointments.addAll([
      AppointmentModel(
        id: 'apt-1',
        title: 'Retorno pós-operatório',
        doctorName: 'Dr. João Silva',
        date: DateTime(now.year, now.month, now.day + 7),
        time: '14:00',
        location: 'Clínica São Paulo - Sala 302',
        status: AppointmentStatus.confirmed,
        type: AppointmentType.returnVisit,
        notifications: [
          NotificationConfig.defaults[0],
          NotificationConfig.defaults[1],
        ],
        notes: 'Levar exames recentes',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      AppointmentModel(
        id: 'apt-2',
        title: 'Avaliação 1 mês',
        doctorName: 'Dr. João Silva',
        date: DateTime(now.year, now.month + 1, 15),
        time: '10:00',
        location: 'Clínica São Paulo - Sala 302',
        status: AppointmentStatus.pending,
        type: AppointmentType.returnVisit,
        notifications: [NotificationConfig.defaults[0]],
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
      AppointmentModel(
        id: 'apt-3',
        title: 'Avaliação 3 meses',
        doctorName: 'Dr. João Silva',
        date: DateTime(now.year, now.month + 3, 10),
        time: '15:00',
        location: 'Clínica São Paulo - Sala 302',
        status: AppointmentStatus.pending,
        type: AppointmentType.returnVisit,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
    ]);

    _externalEvents.addAll([
      ExternalEventModel(
        id: 'ext-1',
        title: 'Fisioterapia',
        date: DateTime(now.year, now.month, now.day + 3),
        time: '16:00',
        location: 'Clínica Reabilitar',
        notes: 'Levar toalha e roupas confortáveis',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      ExternalEventModel(
        id: 'ext-2',
        title: 'Retirar medicamentos',
        date: DateTime(now.year, now.month, now.day + 5),
        time: '09:00',
        location: 'Farmácia Central',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  @override
  Future<List<AppointmentModel>> getAppointments({String? status}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (status == null) {
      return List.from(_appointments);
    }

    return _appointments
        .where((apt) => apt.status.apiValue == status)
        .toList();
  }

  @override
  Future<List<AppointmentModel>> getUpcomingAppointments({int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final upcoming = _appointments
        .where((apt) =>
            apt.dateTime.isAfter(now) &&
            apt.status != AppointmentStatus.cancelled)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return upcoming.take(limit).toList();
  }

  @override
  Future<AppointmentModel?> getAppointmentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return _appointments.firstWhere((apt) => apt.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppointmentModel> createAppointment({
    required String title,
    required DateTime date,
    required String time,
    required String location,
    required AppointmentType type,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final newAppointment = AppointmentModel(
      id: 'apt-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      date: date,
      time: time,
      location: location,
      status: AppointmentStatus.pending,
      type: type,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    _appointments.add(newAppointment);
    return newAppointment;
  }

  @override
  Future<AppointmentModel> updateAppointmentStatus(
    String id,
    AppointmentStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _appointments.indexWhere((apt) => apt.id == id);
    if (index == -1) {
      throw Exception('Agendamento não encontrado');
    }

    final updated = AppointmentModel(
      id: _appointments[index].id,
      title: _appointments[index].title,
      doctorName: _appointments[index].doctorName,
      date: _appointments[index].date,
      time: _appointments[index].time,
      location: _appointments[index].location,
      status: status,
      type: _appointments[index].type,
      notifications: _appointments[index].notifications,
      notes: _appointments[index].notes,
      createdAt: _appointments[index].createdAt,
      updatedAt: DateTime.now(),
    );

    _appointments[index] = updated;
    return updated;
  }

  @override
  Future<AppointmentModel> confirmAppointment(String id) async {
    return updateAppointmentStatus(id, AppointmentStatus.confirmed);
  }

  @override
  Future<AppointmentModel> cancelAppointment(String id) async {
    return updateAppointmentStatus(id, AppointmentStatus.cancelled);
  }

  @override
  Future<List<ExternalEventModel>> getExternalEvents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_externalEvents);
  }

  @override
  Future<ExternalEventModel?> getExternalEventById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return _externalEvents.firstWhere((evt) => evt.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ExternalEventModel> createExternalEvent({
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final newEvent = ExternalEventModel(
      id: 'ext-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      date: date,
      time: time,
      location: location,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    _externalEvents.add(newEvent);
    return newEvent;
  }

  @override
  Future<ExternalEventModel> updateExternalEvent({
    required String id,
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _externalEvents.indexWhere((evt) => evt.id == id);
    if (index == -1) {
      throw Exception('Evento não encontrado');
    }

    final updated = ExternalEventModel(
      id: id,
      title: title,
      date: date,
      time: time,
      location: location,
      notes: notes,
      createdAt: _externalEvents[index].createdAt,
      updatedAt: DateTime.now(),
    );

    _externalEvents[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteExternalEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _externalEvents.indexWhere((evt) => evt.id == id);
    if (index == -1) {
      throw Exception('Evento não encontrado');
    }

    _externalEvents.removeAt(index);
  }
}
