import '../models/appointment_model.dart';
import '../../domain/entities/appointment.dart';

/// Interface abstrata do datasource de agenda
abstract class AgendaDatasource {
  /// Busca agendamentos da clínica
  Future<List<AppointmentModel>> getAppointments({String? status});

  /// Busca próximos agendamentos
  Future<List<AppointmentModel>> getUpcomingAppointments({int limit = 5});

  /// Busca um agendamento pelo ID
  Future<AppointmentModel?> getAppointmentById(String id);

  /// Cria um novo agendamento
  Future<AppointmentModel> createAppointment({
    required String title,
    required DateTime date,
    required String time,
    required String location,
    required AppointmentType type,
    String? notes,
  });

  /// Atualiza o status de um agendamento
  Future<AppointmentModel> updateAppointmentStatus(
    String id,
    AppointmentStatus status,
  );

  /// Confirma um agendamento
  Future<AppointmentModel> confirmAppointment(String id);

  /// Cancela um agendamento
  Future<AppointmentModel> cancelAppointment(String id);

  /// Busca eventos externos do usuário
  Future<List<ExternalEventModel>> getExternalEvents();

  /// Busca um evento externo pelo ID
  Future<ExternalEventModel?> getExternalEventById(String id);

  /// Cria um novo evento externo
  Future<ExternalEventModel> createExternalEvent({
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  });

  /// Atualiza um evento externo
  Future<ExternalEventModel> updateExternalEvent({
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
