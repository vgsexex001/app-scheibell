import '../../../../core/services/api_service.dart';
import '../../domain/entities/recovery_summary.dart';
import '../../domain/entities/resource.dart';
import '../../domain/entities/timeline_event.dart';
import '../../domain/entities/training_week.dart';
import '../../domain/repositories/recovery_repository.dart';

/// Implementação do repositório de recuperação usando a API real
class RecoveryApiDatasource implements RecoveryRepository {
  final ApiService _apiService;

  RecoveryApiDatasource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  @override
  Future<RecoverySummary> getRecoverySummary() async {
    try {
      // Busca o perfil do paciente para obter dias desde cirurgia
      final profile = await _apiService.getProfile();

      // Busca aderência de medicações
      final adherence = await _apiService.getMedicationAdherence(days: 7);

      // Busca protocolo para semana atual
      final protocol = await _apiService.getTrainingProtocol();

      final surgeryDateStr = profile['surgeryDate'] as String?;
      DateTime? surgeryDate;
      int daysSinceSurgery = 0;

      if (surgeryDateStr != null) {
        surgeryDate = DateTime.tryParse(surgeryDateStr);
        if (surgeryDate != null) {
          daysSinceSurgery = DateTime.now().difference(surgeryDate).inDays;
        }
      }

      // Usa dados do protocolo se disponível
      daysSinceSurgery =
          protocol['daysSinceSurgery'] as int? ?? daysSinceSurgery;

      return RecoverySummary(
        daysSinceSurgery: daysSinceSurgery,
        adherencePercentage:
            (adherence['percentage'] as num?)?.toDouble() ?? 0.0,
        completedTasks: adherence['completed'] as int? ?? 0,
        totalTasks: adherence['total'] as int? ?? 0,
        currentWeek: protocol['currentWeek'] as int? ?? 1,
        totalWeeks: 12,
        surgeryType: profile['surgeryType'] as String?,
        surgeryDate: surgeryDate,
      );
    } catch (e) {
      print('Erro ao buscar resumo da recuperação: $e');
      return RecoverySummary.empty();
    }
  }

  @override
  Future<List<TimelineEvent>> getTimelineEvents() async {
    try {
      // Busca consultas/agendamentos para montar timeline
      final appointments = await _apiService.getAppointments();
      final profile = await _apiService.getProfile();

      final events = <TimelineEvent>[];

      // Adiciona cirurgia como primeiro evento
      final surgeryDateStr = profile['surgeryDate'] as String?;
      if (surgeryDateStr != null) {
        final surgeryDate = DateTime.tryParse(surgeryDateStr);
        if (surgeryDate != null) {
          events.add(TimelineEvent(
            id: 'surgery',
            title: 'Cirurgia',
            description: profile['surgeryType'] as String? ?? 'Rinoplastia',
            date: surgeryDate,
            status: TimelineEventStatus.completed,
            type: TimelineEventType.surgery,
            dayNumber: 0,
            isImportant: true,
          ));
        }
      }

      // Adiciona consultas/agendamentos
      for (final apt in appointments) {
        final dateStr = apt['date'] as String?;
        if (dateStr == null) continue;

        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final eventDate = DateTime(date.year, date.month, date.day);

        TimelineEventStatus status;
        if (eventDate.isBefore(today)) {
          status = TimelineEventStatus.completed;
        } else if (eventDate.isAtSameMomentAs(today)) {
          status = TimelineEventStatus.current;
        } else {
          status = TimelineEventStatus.upcoming;
        }

        events.add(TimelineEvent(
          id: apt['id'] as String,
          title: apt['title'] as String? ?? 'Consulta',
          description: apt['description'] as String?,
          date: date,
          status: status,
          type: TimelineEventType.appointment,
          isImportant: apt['type'] == 'RETURN',
        ));
      }

      // Ordena por data
      events.sort((a, b) => a.date.compareTo(b.date));

      return events;
    } catch (e) {
      print('Erro ao buscar eventos da timeline: $e');
      return [];
    }
  }

  @override
  Future<ResourcesResult> getResources({
    ResourceCategory? category,
    ResourceType? type,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    // TODO: Implementar quando endpoint de recursos existir
    // Por enquanto retorna vazio - usar mock datasource
    return ResourcesResult.empty();
  }

  @override
  Future<List<Resource>> getFeaturedResources({int limit = 5}) async {
    // TODO: Implementar quando endpoint existir
    return [];
  }

  @override
  Future<Resource?> getResourceById(String id) async {
    // TODO: Implementar quando endpoint existir
    return null;
  }

  @override
  Future<TrainingProtocol> getTrainingProtocol() async {
    try {
      final data = await _apiService.getTrainingProtocol();

      final weeks = (data['weeks'] as List<dynamic>?)
              ?.map((w) => TrainingWeek.fromMap(w as Map<String, dynamic>))
              .toList() ??
          [];

      return TrainingProtocol(
        currentWeek: data['currentWeek'] as int? ?? 1,
        daysSinceSurgery: data['daysSinceSurgery'] as int? ?? 0,
        basalHeartRate: data['basalHeartRate'] as int? ?? 65,
        weeks: weeks,
      );
    } catch (e) {
      print('Erro ao buscar protocolo de treino: $e');
      return TrainingProtocol.empty();
    }
  }

  @override
  Future<void> markResourceAsViewed(String resourceId) async {
    // TODO: Implementar quando endpoint existir
  }

  @override
  Future<ExamStats> getExamStats() async {
    try {
      final data = await _apiService.getExamStats();
      return ExamStats(
        totalExams: data['total'] as int? ?? 0,
        pendingExams: data['pending'] as int? ?? 0,
        completedExams: data['completed'] as int? ?? 0,
        newResults: data['newResults'] as int? ?? 0,
      );
    } catch (e) {
      print('Erro ao buscar estatísticas de exames: $e');
      return ExamStats.empty();
    }
  }

  @override
  Future<List<PatientDocument>> getDocuments() async {
    // TODO: Implementar quando endpoint existir
    return [];
  }
}
