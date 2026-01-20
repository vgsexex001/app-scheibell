import 'api_service.dart';

/// Categorias de conteúdo de recuperação
enum RecoveryCategory {
  symptoms,
  care,
  activities,
  diet,
}

/// Subcategorias de sintomas
enum SymptomSeverity {
  normal,
  warning,
  emergency,
}

/// Subcategorias de atividades e dieta
enum ContentClassification {
  allowed,
  restricted,
  prohibited,
}

/// Serviço para buscar conteúdos de recuperação via API Backend
///
/// Fluxo de dados:
/// 1. Usa a API backend (/content/patient/clinic/all)
/// 2. Backend já aplica filtros de clinicId e dias válidos
/// 3. Backend já aplica personalizações do paciente
/// 4. Retorna conteúdos prontos para exibição
class RecoveryContentService {
  final ApiService _apiService = ApiService();

  /// Buscar conteúdos por tipo (SYMPTOMS, CARE, ACTIVITIES, DIET)
  Future<List<Map<String, dynamic>>> getConteudosPorTipo(String type) async {
    try {
      print('');
      print('========== DEBUG RECOVERY CONTENT SERVICE ==========');
      print('Buscando conteúdos do tipo: $type via API Backend');

      // Usa a API do backend que já faz todo o processamento
      final response = await _apiService.getPatientClinicContentByType(type);

      print('Conteúdos recebidos do backend: ${response.length}');
      for (var c in response) {
        print('  - [${c['category']}] ${c['title']}');
      }
      print('====================================================');
      print('');

      return response;
    } catch (e, stackTrace) {
      print('');
      print('!!!!! ERRO ao carregar conteúdos de $type: $e');
      print('StackTrace: $stackTrace');
      print('');
      return [];
    }
  }

  // ==================== MÉTODOS ESPECÍFICOS POR CATEGORIA ====================

  /// Buscar sintomas organizados por severidade
  Future<Map<String, List<Map<String, dynamic>>>> getSintomasPorSeveridade() async {
    final sintomas = await getConteudosPorTipo('SYMPTOMS');

    return {
      'NORMAL': sintomas.where((s) => s['category'] == 'NORMAL').toList(),
      'WARNING': sintomas.where((s) => s['category'] == 'WARNING').toList(),
      'EMERGENCY': sintomas.where((s) => s['category'] == 'EMERGENCY').toList(),
    };
  }

  /// Buscar cuidados
  Future<List<Map<String, dynamic>>> getCuidados() async {
    return getConteudosPorTipo('CARE');
  }

  /// Buscar atividades organizadas por classificação
  Future<Map<String, List<Map<String, dynamic>>>> getAtividadesPorClassificacao() async {
    final atividades = await getConteudosPorTipo('ACTIVITIES');

    return {
      'ALLOWED': atividades.where((a) => a['category'] == 'ALLOWED').toList(),
      'RESTRICTED': atividades.where((a) => a['category'] == 'RESTRICTED').toList(),
      'PROHIBITED': atividades.where((a) => a['category'] == 'PROHIBITED').toList(),
    };
  }

  /// Buscar dieta organizada por classificação
  Future<Map<String, List<Map<String, dynamic>>>> getDietaPorClassificacao() async {
    final dieta = await getConteudosPorTipo('DIET');

    return {
      'ALLOWED': dieta.where((d) => d['category'] == 'ALLOWED').toList(),
      'RESTRICTED': dieta.where((d) => d['category'] == 'RESTRICTED').toList(),
      'PROHIBITED': dieta.where((d) => d['category'] == 'PROHIBITED').toList(),
    };
  }

  /// Buscar dias pós-operatório do paciente atual
  Future<int> getDiasPosOperatorio() async {
    try {
      final protocol = await _apiService.getTrainingProtocol();
      return protocol['daysSinceSurgery'] as int? ?? 0;
    } catch (e) {
      print('Erro ao buscar dias pós-operatório: $e');
      return 0;
    }
  }

  /// Buscar data da cirurgia do paciente
  Future<DateTime?> getDataCirurgia() async {
    try {
      final profile = await _apiService.getProfile();
      final patient = profile['patient'] as Map<String, dynamic>?;
      final surgeryDateStr = patient?['surgeryDate'] as String?;
      if (surgeryDateStr == null) return null;
      return DateTime.tryParse(surgeryDateStr);
    } catch (e) {
      print('Erro ao buscar data da cirurgia: $e');
      return null;
    }
  }
}
