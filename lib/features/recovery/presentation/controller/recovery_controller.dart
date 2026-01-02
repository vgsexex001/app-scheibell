import 'package:flutter/foundation.dart';
import '../../data/datasources/recovery_mock_datasource.dart';
import '../../domain/entities/recovery_summary.dart';
import '../../domain/entities/resource.dart';
import '../../domain/entities/timeline_event.dart';
import '../../domain/entities/training_week.dart';
import '../../domain/repositories/recovery_repository.dart';

/// Estado de carregamento
enum LoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// Controller para a tela de Recuperação
///
/// Gerencia o estado de:
/// - Resumo da recuperação (header)
/// - Timeline de eventos
/// - Recursos educacionais
/// - Protocolo de treino
/// - Exames e documentos
class RecoveryController extends ChangeNotifier {
  /// Troque para RecoveryApiDatasource() quando o backend tiver
  /// todos os endpoints implementados
  final RecoveryRepository _repository = RecoveryMockDatasource();

  // Estados de carregamento por seção
  LoadingState _summaryState = LoadingState.initial;
  LoadingState _timelineState = LoadingState.initial;
  LoadingState _resourcesState = LoadingState.initial;
  LoadingState _trainingState = LoadingState.initial;
  LoadingState _examsState = LoadingState.initial;
  LoadingState _docsState = LoadingState.initial;

  // Dados
  RecoverySummary _summary = RecoverySummary.empty();
  List<TimelineEvent> _timelineEvents = [];
  List<Resource> _featuredResources = [];
  List<Resource> _allResources = [];
  TrainingProtocol _trainingProtocol = TrainingProtocol.empty();
  ExamStats _examStats = ExamStats.empty();
  List<PatientDocument> _documents = [];

  // Paginação de recursos
  int _resourcesPage = 1;
  bool _hasMoreResources = false;
  int _totalResourcesCount = 0;

  // Filtros de recursos
  ResourceCategory? _selectedCategory;
  ResourceType? _selectedType;
  String _searchQuery = '';

  // Mensagem de erro
  String? _errorMessage;

  // Tab selecionada
  int _selectedTabIndex = 0;

  // Getters
  LoadingState get summaryState => _summaryState;
  LoadingState get timelineState => _timelineState;
  LoadingState get resourcesState => _resourcesState;
  LoadingState get trainingState => _trainingState;
  LoadingState get examsState => _examsState;
  LoadingState get docsState => _docsState;

  RecoverySummary get summary => _summary;
  List<TimelineEvent> get timelineEvents => _timelineEvents;
  List<Resource> get featuredResources => _featuredResources;
  List<Resource> get allResources => _allResources;
  TrainingProtocol get trainingProtocol => _trainingProtocol;
  ExamStats get examStats => _examStats;
  List<PatientDocument> get documents => _documents;

  bool get hasMoreResources => _hasMoreResources;
  int get totalResourcesCount => _totalResourcesCount;
  ResourceCategory? get selectedCategory => _selectedCategory;
  ResourceType? get selectedType => _selectedType;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  int get selectedTabIndex => _selectedTabIndex;

  // Helpers de estado
  bool get isLoadingSummary => _summaryState == LoadingState.loading;
  bool get isLoadingTimeline => _timelineState == LoadingState.loading;
  bool get isLoadingResources => _resourcesState == LoadingState.loading;
  bool get isLoadingTraining => _trainingState == LoadingState.loading;
  bool get isLoadingExams => _examsState == LoadingState.loading;
  bool get isLoadingDocs => _docsState == LoadingState.loading;

  bool get hasError => _errorMessage != null;
  bool get isEmpty =>
      _timelineEvents.isEmpty &&
      _featuredResources.isEmpty &&
      _trainingProtocol.weeks.isEmpty;

  /// Inicializa carregando todos os dados
  Future<void> initialize() async {
    await Future.wait([
      loadSummary(),
      loadTimeline(),
      loadFeaturedResources(),
      loadTrainingProtocol(),
      loadExamStats(),
      loadDocuments(),
    ]);
  }

  /// Carrega o resumo da recuperação
  Future<void> loadSummary() async {
    _summaryState = LoadingState.loading;
    notifyListeners();

    try {
      _summary = await _repository.getRecoverySummary();
      _summaryState = LoadingState.loaded;
    } catch (e) {
      _summaryState = LoadingState.error;
      _errorMessage = 'Erro ao carregar resumo: $e';
      debugPrint('RecoveryController.loadSummary: $e');
    }
    notifyListeners();
  }

  /// Carrega eventos da timeline
  Future<void> loadTimeline() async {
    _timelineState = LoadingState.loading;
    notifyListeners();

    try {
      _timelineEvents = await _repository.getTimelineEvents();
      _timelineState = LoadingState.loaded;
    } catch (e) {
      _timelineState = LoadingState.error;
      _errorMessage = 'Erro ao carregar timeline: $e';
      debugPrint('RecoveryController.loadTimeline: $e');
    }
    notifyListeners();
  }

  /// Carrega recursos em destaque
  Future<void> loadFeaturedResources() async {
    _resourcesState = LoadingState.loading;
    notifyListeners();

    try {
      _featuredResources = await _repository.getFeaturedResources(limit: 5);
      _resourcesState = LoadingState.loaded;
    } catch (e) {
      _resourcesState = LoadingState.error;
      _errorMessage = 'Erro ao carregar recursos: $e';
      debugPrint('RecoveryController.loadFeaturedResources: $e');
    }
    notifyListeners();
  }

  /// Carrega todos os recursos com paginação
  Future<void> loadAllResources({bool refresh = false}) async {
    if (refresh) {
      _resourcesPage = 1;
      _allResources = [];
    }

    _resourcesState = LoadingState.loading;
    notifyListeners();

    try {
      final result = await _repository.getResources(
        category: _selectedCategory,
        type: _selectedType,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: _resourcesPage,
        limit: 10,
      );

      if (refresh) {
        _allResources = result.resources;
      } else {
        _allResources.addAll(result.resources);
      }

      _hasMoreResources = result.hasNextPage;
      _totalResourcesCount = result.totalCount;
      _resourcesState = LoadingState.loaded;
    } catch (e) {
      _resourcesState = LoadingState.error;
      _errorMessage = 'Erro ao carregar recursos: $e';
      debugPrint('RecoveryController.loadAllResources: $e');
    }
    notifyListeners();
  }

  /// Carrega mais recursos (paginação)
  Future<void> loadMoreResources() async {
    if (!_hasMoreResources || _resourcesState == LoadingState.loading) return;

    _resourcesPage++;
    await loadAllResources();
  }

  /// Define filtro de categoria
  void setResourceCategory(ResourceCategory? category) {
    _selectedCategory = category;
    loadAllResources(refresh: true);
  }

  /// Define filtro de tipo
  void setResourceType(ResourceType? type) {
    _selectedType = type;
    loadAllResources(refresh: true);
  }

  /// Define busca por texto
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadAllResources(refresh: true);
  }

  /// Limpa filtros de recursos
  void clearResourceFilters() {
    _selectedCategory = null;
    _selectedType = null;
    _searchQuery = '';
    loadAllResources(refresh: true);
  }

  /// Carrega protocolo de treino
  Future<void> loadTrainingProtocol() async {
    _trainingState = LoadingState.loading;
    notifyListeners();

    try {
      _trainingProtocol = await _repository.getTrainingProtocol();
      _trainingState = LoadingState.loaded;
    } catch (e) {
      _trainingState = LoadingState.error;
      _errorMessage = 'Erro ao carregar protocolo de treino: $e';
      debugPrint('RecoveryController.loadTrainingProtocol: $e');
    }
    notifyListeners();
  }

  /// Carrega estatísticas de exames
  Future<void> loadExamStats() async {
    _examsState = LoadingState.loading;
    notifyListeners();

    try {
      _examStats = await _repository.getExamStats();
      _examsState = LoadingState.loaded;
    } catch (e) {
      _examsState = LoadingState.error;
      _errorMessage = 'Erro ao carregar exames: $e';
      debugPrint('RecoveryController.loadExamStats: $e');
    }
    notifyListeners();
  }

  /// Carrega documentos
  Future<void> loadDocuments() async {
    _docsState = LoadingState.loading;
    notifyListeners();

    try {
      _documents = await _repository.getDocuments();
      _docsState = LoadingState.loaded;
    } catch (e) {
      _docsState = LoadingState.error;
      _errorMessage = 'Erro ao carregar documentos: $e';
      debugPrint('RecoveryController.loadDocuments: $e');
    }
    notifyListeners();
  }

  /// Atualiza todos os dados (pull-to-refresh)
  Future<void> refresh() async {
    _errorMessage = null;
    await initialize();
  }

  /// Define a tab selecionada
  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  /// Busca um recurso por ID
  Future<Resource?> getResourceById(String id) async {
    return _repository.getResourceById(id);
  }

  /// Marca recurso como visualizado
  Future<void> markResourceAsViewed(String resourceId) async {
    await _repository.markResourceAsViewed(resourceId);
  }

  /// Retorna eventos da timeline filtrados por status
  List<TimelineEvent> getTimelineByStatus(TimelineEventStatus status) {
    return _timelineEvents.where((e) => e.status == status).toList();
  }

  /// Retorna a semana atual do protocolo
  TrainingWeek? get currentTrainingWeek {
    try {
      return _trainingProtocol.weeks.firstWhere((w) => w.isCurrent);
    } catch (e) {
      return _trainingProtocol.weeks.isNotEmpty
          ? _trainingProtocol.weeks.first
          : null;
    }
  }

  /// Limpa estado (usar no logout)
  void reset() {
    _summaryState = LoadingState.initial;
    _timelineState = LoadingState.initial;
    _resourcesState = LoadingState.initial;
    _trainingState = LoadingState.initial;
    _examsState = LoadingState.initial;
    _docsState = LoadingState.initial;

    _summary = RecoverySummary.empty();
    _timelineEvents = [];
    _featuredResources = [];
    _allResources = [];
    _trainingProtocol = TrainingProtocol.empty();
    _examStats = ExamStats.empty();
    _documents = [];

    _resourcesPage = 1;
    _hasMoreResources = false;
    _totalResourcesCount = 0;
    _selectedCategory = null;
    _selectedType = null;
    _searchQuery = '';
    _errorMessage = null;
    _selectedTabIndex = 0;

    notifyListeners();
  }
}
