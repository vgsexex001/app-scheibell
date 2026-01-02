import '../../domain/entities/recovery_summary.dart';
import '../../domain/entities/resource.dart';
import '../../domain/entities/timeline_event.dart';
import '../../domain/entities/training_week.dart';
import '../../domain/repositories/recovery_repository.dart';

/// Implementação mock do repositório de recuperação para desenvolvimento/testes
///
/// Para trocar para o mock:
/// No arquivo recovery_controller.dart, mude:
/// ```dart
/// // De:
/// final RecoveryRepository _repository = RecoveryApiDatasource();
/// // Para:
/// final RecoveryRepository _repository = RecoveryMockDatasource();
/// ```
class RecoveryMockDatasource implements RecoveryRepository {
  // Simula delay de rede
  static const _networkDelay = Duration(milliseconds: 800);

  @override
  Future<RecoverySummary> getRecoverySummary() async {
    await Future.delayed(_networkDelay);

    return RecoverySummary(
      daysSinceSurgery: 14,
      adherencePercentage: 87.5,
      completedTasks: 42,
      totalTasks: 48,
      currentWeek: 2,
      totalWeeks: 12,
      surgeryType: 'Rinoplastia',
      surgeryDate: DateTime.now().subtract(const Duration(days: 14)),
    );
  }

  @override
  Future<List<TimelineEvent>> getTimelineEvents() async {
    await Future.delayed(_networkDelay);

    final now = DateTime.now();
    final surgeryDate = now.subtract(const Duration(days: 14));

    return [
      TimelineEvent(
        id: '1',
        title: 'Cirurgia',
        description: 'Rinoplastia - Dr. Scheibell',
        date: surgeryDate,
        status: TimelineEventStatus.completed,
        type: TimelineEventType.surgery,
        dayNumber: 0,
        isImportant: true,
      ),
      TimelineEvent(
        id: '2',
        title: 'Retirada do tampão',
        description: 'Procedimento ambulatorial',
        date: surgeryDate.add(const Duration(days: 3)),
        status: TimelineEventStatus.completed,
        type: TimelineEventType.milestone,
        dayNumber: 3,
      ),
      TimelineEvent(
        id: '3',
        title: 'Primeira consulta de retorno',
        description: 'Avaliação pós-operatória',
        date: surgeryDate.add(const Duration(days: 7)),
        status: TimelineEventStatus.completed,
        type: TimelineEventType.appointment,
        dayNumber: 7,
        isImportant: true,
      ),
      TimelineEvent(
        id: '4',
        title: 'Retirada do gesso',
        description: 'Marco importante da recuperação',
        date: surgeryDate.add(const Duration(days: 14)),
        status: TimelineEventStatus.current,
        type: TimelineEventType.milestone,
        dayNumber: 14,
        isImportant: true,
      ),
      TimelineEvent(
        id: '5',
        title: 'Segunda consulta de retorno',
        description: 'Avaliação da cicatrização',
        date: surgeryDate.add(const Duration(days: 21)),
        status: TimelineEventStatus.upcoming,
        type: TimelineEventType.appointment,
        dayNumber: 21,
      ),
      TimelineEvent(
        id: '6',
        title: 'Liberação para exercícios leves',
        description: 'Caminhadas e atividades leves',
        date: surgeryDate.add(const Duration(days: 30)),
        status: TimelineEventStatus.upcoming,
        type: TimelineEventType.milestone,
        dayNumber: 30,
      ),
      TimelineEvent(
        id: '7',
        title: 'Consulta de 60 dias',
        description: 'Avaliação de resultado parcial',
        date: surgeryDate.add(const Duration(days: 60)),
        status: TimelineEventStatus.upcoming,
        type: TimelineEventType.appointment,
        dayNumber: 60,
        isImportant: true,
      ),
    ];
  }

  @override
  Future<ResourcesResult> getResources({
    ResourceCategory? category,
    ResourceType? type,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    await Future.delayed(_networkDelay);

    var resources = _mockResources;

    // Filtro por categoria
    if (category != null) {
      resources = resources.where((r) => r.category == category).toList();
    }

    // Filtro por tipo
    if (type != null) {
      resources = resources.where((r) => r.type == type).toList();
    }

    // Filtro por busca
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      resources = resources.where((r) {
        return r.title.toLowerCase().contains(searchLower) ||
            (r.description?.toLowerCase().contains(searchLower) ?? false) ||
            r.tags.any((t) => t.toLowerCase().contains(searchLower));
      }).toList();
    }

    final totalCount = resources.length;
    final totalPages = (totalCount / limit).ceil();
    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, totalCount);

    final paginatedResources =
        startIndex < totalCount ? resources.sublist(startIndex, endIndex) : <Resource>[];

    return ResourcesResult(
      resources: paginatedResources,
      totalCount: totalCount,
      currentPage: page,
      totalPages: totalPages,
      hasNextPage: page < totalPages,
    );
  }

  @override
  Future<List<Resource>> getFeaturedResources({int limit = 5}) async {
    await Future.delayed(_networkDelay);
    return _mockResources.where((r) => r.isFeatured).take(limit).toList();
  }

  @override
  Future<Resource?> getResourceById(String id) async {
    await Future.delayed(_networkDelay);
    try {
      return _mockResources.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<TrainingProtocol> getTrainingProtocol() async {
    await Future.delayed(_networkDelay);

    return TrainingProtocol(
      currentWeek: 2,
      daysSinceSurgery: 14,
      basalHeartRate: 65,
      weeks: [
        const TrainingWeek(
          weekNumber: 1,
          title: 'Repouso Total',
          dayRange: 'D+0 a D+7',
          status: TrainingWeekStatus.completed,
          objective: 'Repouso absoluto para cicatrização inicial',
          maxHeartRate: null,
          heartRateLabel: 'Evitar esforço',
          canDo: ['Caminhar dentro de casa', 'Atividades básicas de higiene'],
          avoid: ['Qualquer exercício', 'Subir escadas', 'Carregar peso'],
        ),
        const TrainingWeek(
          weekNumber: 2,
          title: 'Mobilidade Leve',
          dayRange: 'D+8 a D+14',
          status: TrainingWeekStatus.current,
          objective: 'Retomada gradual de atividades cotidianas',
          maxHeartRate: 100,
          heartRateLabel: 'Até 100 bpm',
          canDo: [
            'Caminhadas leves de 10-15 min',
            'Atividades domésticas leves',
            'Trabalho em home office'
          ],
          avoid: [
            'Exercícios aeróbicos',
            'Levantar peso',
            'Movimentos bruscos'
          ],
        ),
        const TrainingWeek(
          weekNumber: 3,
          title: 'Atividades Moderadas',
          dayRange: 'D+15 a D+21',
          status: TrainingWeekStatus.locked,
          objective: 'Aumento gradual da intensidade',
          maxHeartRate: 110,
          heartRateLabel: 'Até 110 bpm',
          canDo: [
            'Caminhadas de 20-30 min',
            'Alongamentos leves',
            'Retorno ao trabalho presencial'
          ],
          avoid: [
            'Corrida',
            'Musculação',
            'Atividades que aumentem pressão facial'
          ],
        ),
        const TrainingWeek(
          weekNumber: 4,
          title: 'Exercícios Leves',
          dayRange: 'D+22 a D+30',
          status: TrainingWeekStatus.locked,
          objective: 'Início de exercícios físicos leves',
          maxHeartRate: 120,
          heartRateLabel: 'Até 120 bpm',
          canDo: [
            'Bicicleta ergométrica leve',
            'Yoga (posturas sem inversão)',
            'Pilates adaptado'
          ],
          avoid: ['Exercícios de impacto', 'Natação', 'Mergulho'],
        ),
      ],
    );
  }

  @override
  Future<void> markResourceAsViewed(String resourceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Mock: não faz nada
  }

  @override
  Future<ExamStats> getExamStats() async {
    await Future.delayed(_networkDelay);
    return const ExamStats(
      totalExams: 5,
      pendingExams: 2,
      completedExams: 3,
      newResults: 1,
    );
  }

  @override
  Future<List<PatientDocument>> getDocuments() async {
    await Future.delayed(_networkDelay);
    return [
      PatientDocument(
        id: '1',
        title: 'Atestado Médico',
        type: 'PDF',
        uploadedAt: DateTime.now().subtract(const Duration(days: 14)),
        isNew: false,
      ),
      PatientDocument(
        id: '2',
        title: 'Receita de Medicamentos',
        type: 'PDF',
        uploadedAt: DateTime.now().subtract(const Duration(days: 14)),
        isNew: false,
      ),
      PatientDocument(
        id: '3',
        title: 'Orientações Pós-Operatórias',
        type: 'PDF',
        uploadedAt: DateTime.now().subtract(const Duration(days: 14)),
        isNew: true,
      ),
    ];
  }

  // Dados mock de recursos educacionais
  static final List<Resource> _mockResources = [
    Resource(
      id: '1',
      title: 'Cuidados essenciais nos primeiros 7 dias',
      description:
          'Guia completo sobre os cuidados necessários na primeira semana após a rinoplastia.',
      type: ResourceType.article,
      category: ResourceCategory.recovery,
      readTimeMinutes: 8,
      tags: ['pós-operatório', 'cuidados', 'primeira semana'],
      isFeatured: true,
      publishedAt: DateTime.now().subtract(const Duration(days: 30)),
      viewCount: 1250,
    ),
    Resource(
      id: '2',
      title: 'Como fazer a limpeza nasal corretamente',
      description: 'Vídeo demonstrativo da técnica correta de limpeza nasal.',
      type: ResourceType.video,
      category: ResourceCategory.recovery,
      durationMinutes: 5,
      thumbnailUrl: 'https://example.com/thumb1.jpg',
      contentUrl: 'https://example.com/video1.mp4',
      tags: ['limpeza', 'nariz', 'técnica'],
      isFeatured: true,
      publishedAt: DateTime.now().subtract(const Duration(days: 25)),
      viewCount: 890,
    ),
    Resource(
      id: '3',
      title: 'Alimentação para acelerar a cicatrização',
      description:
          'Descubra quais alimentos ajudam na recuperação e quais evitar.',
      type: ResourceType.article,
      category: ResourceCategory.nutrition,
      readTimeMinutes: 6,
      tags: ['alimentação', 'cicatrização', 'dieta'],
      isFeatured: true,
      publishedAt: DateTime.now().subtract(const Duration(days: 20)),
      viewCount: 750,
    ),
    Resource(
      id: '4',
      title: 'Drenagem linfática facial: quando iniciar?',
      description:
          'Tudo sobre drenagem linfática no pós-operatório de rinoplastia.',
      type: ResourceType.article,
      category: ResourceCategory.skinCare,
      readTimeMinutes: 5,
      tags: ['drenagem', 'inchaço', 'recuperação'],
      isFeatured: false,
      publishedAt: DateTime.now().subtract(const Duration(days: 15)),
      viewCount: 520,
    ),
    Resource(
      id: '5',
      title: 'Exercícios respiratórios pós-rinoplastia',
      description: 'Técnicas de respiração para melhorar o conforto.',
      type: ResourceType.video,
      category: ResourceCategory.exercise,
      durationMinutes: 8,
      tags: ['respiração', 'exercícios', 'conforto'],
      isFeatured: true,
      publishedAt: DateTime.now().subtract(const Duration(days: 10)),
      viewCount: 680,
    ),
    Resource(
      id: '6',
      title: 'Ansiedade no pós-operatório: como lidar',
      description: 'Dicas para gerenciar a ansiedade durante a recuperação.',
      type: ResourceType.article,
      category: ResourceCategory.mentalHealth,
      readTimeMinutes: 7,
      tags: ['ansiedade', 'saúde mental', 'bem-estar'],
      isFeatured: false,
      publishedAt: DateTime.now().subtract(const Duration(days: 8)),
      viewCount: 420,
    ),
    Resource(
      id: '7',
      title: 'FAQ: Perguntas frequentes sobre rinoplastia',
      description: 'Respostas para as dúvidas mais comuns dos pacientes.',
      type: ResourceType.faq,
      category: ResourceCategory.general,
      readTimeMinutes: 10,
      tags: ['dúvidas', 'FAQ', 'perguntas'],
      isFeatured: true,
      publishedAt: DateTime.now().subtract(const Duration(days: 5)),
      viewCount: 1100,
    ),
    Resource(
      id: '8',
      title: 'Dica: Posição correta para dormir',
      description: 'Mantenha a cabeça elevada com 2-3 travesseiros.',
      type: ResourceType.tip,
      category: ResourceCategory.recovery,
      tags: ['sono', 'posição', 'dica'],
      isFeatured: false,
      publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      viewCount: 320,
    ),
    Resource(
      id: '9',
      title: 'Infográfico: Linha do tempo da recuperação',
      description: 'Visualize as etapas da sua recuperação semana a semana.',
      type: ResourceType.infographic,
      category: ResourceCategory.recovery,
      tags: ['timeline', 'etapas', 'visual'],
      isFeatured: false,
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      viewCount: 580,
    ),
    Resource(
      id: '10',
      title: 'Proteção solar: quando e como usar',
      description: 'Guia sobre proteção solar após procedimentos faciais.',
      type: ResourceType.article,
      category: ResourceCategory.skinCare,
      readTimeMinutes: 4,
      tags: ['sol', 'proteção', 'pele'],
      isFeatured: false,
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      viewCount: 290,
    ),
  ];
}
