import 'package:flutter/foundation.dart';
import '../../../core/services/content_service.dart';
import '../../../core/services/api_service.dart';

/// Provider para gerenciar o estado da tela de recuperação
class RecoveryProvider extends ChangeNotifier {
  final ContentService _contentService = ContentService();
  final ApiService _apiService = ApiService();

  // Estados de carregamento
  bool _isLoading = false;
  String? _errorMessage;

  // Dados de sintomas
  List<ContentItem> _sintomasNormais = [];
  List<ContentItem> _sintomasAvisar = [];
  List<ContentItem> _sintomasEmergencia = [];

  // Dados de cuidados
  List<ContentItem> _cuidados = [];

  // Dados de atividades
  List<ContentItem> _atividadesPermitidas = [];
  List<ContentItem> _atividadesEvitar = [];
  List<ContentItem> _atividadesProibidas = [];

  // Dados de dieta
  List<ContentItem> _dietaRecomendada = [];
  List<ContentItem> _dietaEvitar = [];
  List<ContentItem> _dietaProibida = [];

  // Dados de medicamentos
  List<ContentItem> _medicamentos = [];

  // Dados de treino
  List<ContentItem> _treinos = [];

  // Dados do protocolo de treino (semanas)
  Map<String, dynamic>? _trainingProtocol;
  List<Map<String, dynamic>> _semanasProtocolo = [];
  int _semanaAtual = 1;
  int _diasDesdeCirurgia = 0;
  int _fcBasal = 65;

  // Flag para saber se já carregou dados da API
  bool _hasLoadedFromApi = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoadedFromApi => _hasLoadedFromApi;

  List<ContentItem> get sintomasNormais => _sintomasNormais;
  List<ContentItem> get sintomasAvisar => _sintomasAvisar;
  List<ContentItem> get sintomasEmergencia => _sintomasEmergencia;

  List<ContentItem> get cuidados => _cuidados;

  List<ContentItem> get atividadesPermitidas => _atividadesPermitidas;
  List<ContentItem> get atividadesEvitar => _atividadesEvitar;
  List<ContentItem> get atividadesProibidas => _atividadesProibidas;

  List<ContentItem> get dietaRecomendada => _dietaRecomendada;
  List<ContentItem> get dietaEvitar => _dietaEvitar;
  List<ContentItem> get dietaProibida => _dietaProibida;

  List<ContentItem> get medicamentos => _medicamentos;
  List<ContentItem> get treinos => _treinos;

  // Getters do protocolo de treino
  Map<String, dynamic>? get trainingProtocol => _trainingProtocol;
  List<Map<String, dynamic>> get semanasProtocolo => _semanasProtocolo;
  int get semanaAtual => _semanaAtual;
  int get diasDesdeCirurgia => _diasDesdeCirurgia;
  int get fcBasal => _fcBasal;

  /// Carrega todos os dados de recuperação
  Future<void> loadAllContent() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Carregar dados em paralelo para melhor performance
      final results = await Future.wait([
        _contentService.getSymptomsByCategory(),
        _contentService.getCareItems(),
        _contentService.getActivitiesByCategory(),
        _contentService.getDietByCategory(),
        _contentService.getMedications(),
        _contentService.getTrainingItems(),
      ]);

      // Processar sintomas
      final symptoms = results[0] as Map<ContentCategory, List<ContentItem>>;
      _sintomasNormais = symptoms[ContentCategory.normal] ?? [];
      _sintomasAvisar = symptoms[ContentCategory.warning] ?? [];
      _sintomasEmergencia = symptoms[ContentCategory.emergency] ?? [];

      // Processar cuidados
      _cuidados = results[1] as List<ContentItem>;

      // Processar atividades
      final activities = results[2] as Map<ContentCategory, List<ContentItem>>;
      _atividadesPermitidas = activities[ContentCategory.allowed] ?? [];
      _atividadesEvitar = activities[ContentCategory.restricted] ?? [];
      _atividadesProibidas = activities[ContentCategory.prohibited] ?? [];

      // Processar dieta
      final diet = results[3] as Map<ContentCategory, List<ContentItem>>;
      _dietaRecomendada = diet[ContentCategory.allowed] ?? [];
      _dietaEvitar = diet[ContentCategory.restricted] ?? [];
      _dietaProibida = diet[ContentCategory.prohibited] ?? [];

      // Processar medicamentos e treinos
      _medicamentos = results[4] as List<ContentItem>;
      _treinos = results[5] as List<ContentItem>;

      // Carregar protocolo de treino (semanas) separadamente
      await _loadTrainingProtocol();

      _hasLoadedFromApi = true;
    } catch (e) {
      _errorMessage = 'Erro ao carregar dados: $e';
      debugPrint('RecoveryProvider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega o protocolo de treino com as semanas da API
  Future<void> _loadTrainingProtocol() async {
    try {
      final protocol = await _apiService.getTrainingProtocol();
      _trainingProtocol = protocol;
      _semanaAtual = protocol['currentWeek'] as int? ?? 1;
      _diasDesdeCirurgia = protocol['daysSinceSurgery'] as int? ?? 0;
      _fcBasal = protocol['basalHeartRate'] as int? ?? 65;

      // Processar semanas
      final weeks = protocol['weeks'] as List<dynamic>? ?? [];
      _semanasProtocolo = weeks.map((week) {
        final weekMap = week as Map<String, dynamic>;
        // Converter status da API para formato do app (0=concluída, 1=atual, 2=futura)
        int estado;
        switch (weekMap['status']) {
          case 'COMPLETED':
            estado = 0;
            break;
          case 'CURRENT':
            estado = 1;
            break;
          case 'FUTURE':
          default:
            estado = 2;
            break;
        }

        return {
          'numero': weekMap['weekNumber'] as int,
          'titulo': weekMap['title'] as String,
          'periodo': weekMap['dayRange'] as String,
          'estado': estado,
          'objetivo': weekMap['objective'] as String,
          'fcMaxima': weekMap['maxHeartRate'] != null
              ? '${weekMap['maxHeartRate']} bpm'
              : 'Sem limite',
          'fcDetalhe': weekMap['heartRateLabel'] as String? ?? '',
          'podeFazer': List<String>.from(weekMap['canDo'] ?? []),
          'aindaProibido': List<String>.from(weekMap['avoid'] ?? []),
          'criteriosSeguranca': <String>[],
          'icone': estado == 0 ? 'check' : (estado == 1 ? 'fitness' : 'lock'),
        };
      }).toList();

      debugPrint('Protocolo carregado: semana atual = $_semanaAtual, dias = $_diasDesdeCirurgia');
    } catch (e) {
      debugPrint('Erro ao carregar protocolo de treino: $e');
      // Se falhar, mantém os dados padrão/vazios
    }
  }

  /// Recarrega todos os dados
  Future<void> refresh() async {
    _hasLoadedFromApi = false;
    await loadAllContent();
  }

  /// Retorna true se há dados disponíveis (da API ou fallback)
  bool get hasData {
    return _sintomasNormais.isNotEmpty ||
        _sintomasAvisar.isNotEmpty ||
        _sintomasEmergencia.isNotEmpty ||
        _cuidados.isNotEmpty ||
        _atividadesPermitidas.isNotEmpty ||
        _dietaRecomendada.isNotEmpty;
  }

  /// Limpa todos os dados do provider (usar no logout)
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _hasLoadedFromApi = false;

    // Limpar sintomas
    _sintomasNormais = [];
    _sintomasAvisar = [];
    _sintomasEmergencia = [];

    // Limpar cuidados
    _cuidados = [];

    // Limpar atividades
    _atividadesPermitidas = [];
    _atividadesEvitar = [];
    _atividadesProibidas = [];

    // Limpar dieta
    _dietaRecomendada = [];
    _dietaEvitar = [];
    _dietaProibida = [];

    // Limpar medicamentos e treinos
    _medicamentos = [];
    _treinos = [];

    // Limpar protocolo de treino
    _trainingProtocol = null;
    _semanasProtocolo = [];
    _semanaAtual = 1;
    _diasDesdeCirurgia = 0;
    _fcBasal = 65;

    notifyListeners();
  }
}
