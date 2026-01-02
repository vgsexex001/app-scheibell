import '../entities/recovery_summary.dart';
import '../entities/resource.dart';
import '../entities/timeline_event.dart';
import '../entities/training_week.dart';

/// Interface abstrata para o repositório de recuperação
///
/// Esta interface define o contrato para buscar dados relacionados
/// à recuperação do paciente. A implementação pode ser:
/// - RecoveryApiDatasource (produção - conecta ao backend)
/// - RecoveryMockDatasource (desenvolvimento/testes)
abstract class RecoveryRepository {
  /// Busca o resumo da recuperação do paciente
  Future<RecoverySummary> getRecoverySummary();

  /// Busca os eventos da timeline de recuperação
  Future<List<TimelineEvent>> getTimelineEvents();

  /// Busca os recursos educacionais
  ///
  /// [category] - Filtra por categoria (opcional)
  /// [type] - Filtra por tipo (opcional)
  /// [search] - Busca por texto (opcional)
  /// [page] - Página para paginação (default: 1)
  /// [limit] - Itens por página (default: 10)
  Future<ResourcesResult> getResources({
    ResourceCategory? category,
    ResourceType? type,
    String? search,
    int page = 1,
    int limit = 10,
  });

  /// Busca recursos em destaque (para a home)
  Future<List<Resource>> getFeaturedResources({int limit = 5});

  /// Busca um recurso específico por ID
  Future<Resource?> getResourceById(String id);

  /// Busca o protocolo de treino com as semanas
  Future<TrainingProtocol> getTrainingProtocol();

  /// Marca um recurso como visualizado
  Future<void> markResourceAsViewed(String resourceId);

  /// Busca estatísticas dos exames do paciente
  Future<ExamStats> getExamStats();

  /// Busca documentos do paciente
  Future<List<PatientDocument>> getDocuments();
}

/// Resultado paginado de recursos
class ResourcesResult {
  final List<Resource> resources;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;

  const ResourcesResult({
    required this.resources,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory ResourcesResult.empty() => const ResourcesResult(
        resources: [],
        totalCount: 0,
        currentPage: 1,
        totalPages: 1,
        hasNextPage: false,
      );
}

/// Protocolo de treino com metadados
class TrainingProtocol {
  final int currentWeek;
  final int daysSinceSurgery;
  final int basalHeartRate;
  final List<TrainingWeek> weeks;

  const TrainingProtocol({
    required this.currentWeek,
    required this.daysSinceSurgery,
    required this.basalHeartRate,
    required this.weeks,
  });

  factory TrainingProtocol.empty() => const TrainingProtocol(
        currentWeek: 1,
        daysSinceSurgery: 0,
        basalHeartRate: 65,
        weeks: [],
      );
}

/// Estatísticas de exames
class ExamStats {
  final int totalExams;
  final int pendingExams;
  final int completedExams;
  final int newResults;

  const ExamStats({
    required this.totalExams,
    required this.pendingExams,
    required this.completedExams,
    required this.newResults,
  });

  factory ExamStats.empty() => const ExamStats(
        totalExams: 0,
        pendingExams: 0,
        completedExams: 0,
        newResults: 0,
      );
}

/// Documento do paciente
class PatientDocument {
  final String id;
  final String title;
  final String type;
  final String? fileUrl;
  final DateTime? uploadedAt;
  final bool isNew;

  const PatientDocument({
    required this.id,
    required this.title,
    required this.type,
    this.fileUrl,
    this.uploadedAt,
    this.isNew = false,
  });
}
