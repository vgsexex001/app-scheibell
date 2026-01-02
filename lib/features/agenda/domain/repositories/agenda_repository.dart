import '../entities/appointment.dart';

/// Interface abstrata do repositório de agenda
abstract class AgendaRepository {
  /// Busca todos os eventos em um intervalo de datas
  /// [startDate] - Data inicial (inclusive)
  /// [endDate] - Data final (inclusive)
  Future<List<AgendaItem>> getEventsInRange(DateTime startDate, DateTime endDate);

  /// Busca agendamentos da clínica
  Future<List<Appointment>> getAppointments({AppointmentStatus? status});

  /// Busca próximos agendamentos
  Future<List<Appointment>> getUpcomingAppointments({int limit = 5});

  /// Busca um agendamento pelo ID
  Future<Appointment?> getAppointmentById(String id);

  /// Cria um novo agendamento
  Future<Appointment> createAppointment({
    required String title,
    required DateTime date,
    required String time,
    required String location,
    required AppointmentType type,
    String? notes,
  });

  /// Atualiza o status de um agendamento
  Future<Appointment> updateAppointmentStatus(
    String id,
    AppointmentStatus status,
  );

  /// Confirma um agendamento
  Future<Appointment> confirmAppointment(String id);

  /// Cancela um agendamento
  Future<Appointment> cancelAppointment(String id);

  /// Busca eventos externos do usuário
  Future<List<ExternalEvent>> getExternalEvents();

  /// Busca um evento externo pelo ID
  Future<ExternalEvent?> getExternalEventById(String id);

  /// Cria um novo evento externo
  Future<ExternalEvent> createExternalEvent({
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  });

  /// Atualiza um evento externo
  Future<ExternalEvent> updateExternalEvent({
    required String id,
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  });

  /// Remove um evento externo
  Future<void> deleteExternalEvent(String id);
}
