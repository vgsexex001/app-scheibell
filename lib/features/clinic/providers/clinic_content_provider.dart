import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/models.dart';

/// Provider para gerenciamento de conteúdos da clínica (admin/staff)
class ClinicContentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // === Estados de estatísticas (para o grid principal) ===
  ContentStats? _stats;
  bool _isLoadingStats = false;

  // === Estados de lista de conteúdos ===
  List<ClinicContent> _contents = [];
  bool _isLoadingContents = false;
  String? _currentType;

  // === Estados de operação (CRUD) ===
  bool _isOperating = false;

  // === Erro global ===
  String? _error;

  // === Getters ===
  ContentStats? get stats => _stats;
  bool get isLoadingStats => _isLoadingStats;

  List<ClinicContent> get contents => _contents;
  bool get isLoadingContents => _isLoadingContents;
  String? get currentType => _currentType;

  bool get isOperating => _isOperating;
  String? get error => _error;

  // === Filtrar por categoria ===
  List<ClinicContent> getByCategory(String category) {
    return _contents.where((c) => c.category == category).toList();
  }

  // === Carregar estatísticas para o grid ===
  Future<void> loadStats() async {
    _isLoadingStats = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getContentStats();
      _stats = ContentStats.fromJson(data);
      if (kDebugMode) {
        debugPrint(
            '[ClinicContentProvider] Stats carregadas: ${_stats?.countByType}');
      }
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro ao carregar stats: $_error');
      }
    } catch (e) {
      _error = 'Erro ao carregar estatísticas';
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro: $e');
      }
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  // === Carregar conteúdos por tipo ===
  Future<void> loadContentsByType(String type) async {
    _isLoadingContents = true;
    _currentType = type;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getAllClinicContentByType(type);
      _contents = data
          .map((item) => ClinicContent.fromJson(item as Map<String, dynamic>))
          .toList();

      // Ordenar por sortOrder
      _contents.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (kDebugMode) {
        debugPrint(
            '[ClinicContentProvider] Carregados ${_contents.length} itens de $type');
      }
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      if (kDebugMode) {
        debugPrint(
            '[ClinicContentProvider] Erro ao carregar conteúdos: $_error');
      }
    } catch (e) {
      _error = 'Erro ao carregar conteúdos';
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro: $e');
      }
    } finally {
      _isLoadingContents = false;
      notifyListeners();
    }
  }

  // === Criar conteúdo ===
  Future<bool> createContent({
    required String type,
    required String category,
    required String title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createClinicContent(
        type: type,
        category: category,
        title: title,
        description: description,
        validFromDay: validFromDay,
        validUntilDay: validUntilDay,
      );

      // Adicionar na lista local
      final newContent = ClinicContent.fromJson(result);
      _contents.add(newContent);

      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Conteúdo criado: ${newContent.id}');
      }
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro ao criar: $_error');
      }
      return false;
    } catch (e) {
      _error = 'Erro ao criar conteúdo';
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro: $e');
      }
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // === Atualizar conteúdo ===
  Future<bool> updateContent(
    String contentId, {
    String? title,
    String? description,
    String? category,
    int? validFromDay,
    int? validUntilDay,
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.updateClinicContent(
        contentId,
        title: title,
        description: description,
        category: category,
        validFromDay: validFromDay,
        validUntilDay: validUntilDay,
      );

      // Atualizar na lista local
      final idx = _contents.indexWhere((c) => c.id == contentId);
      if (idx != -1) {
        _contents[idx] = ClinicContent.fromJson(result);
      }

      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Conteúdo atualizado: $contentId');
      }
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro ao atualizar: $_error');
      }
      return false;
    } catch (e) {
      _error = 'Erro ao atualizar conteúdo';
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro: $e');
      }
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // === Toggle ativo/inativo ===
  Future<bool> toggleContent(String contentId) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.toggleClinicContent(contentId);

      // Atualizar na lista local
      final idx = _contents.indexWhere((c) => c.id == contentId);
      if (idx != -1) {
        _contents[idx] = ClinicContent.fromJson(result);
      }

      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Toggle: $contentId');
      }
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro ao toggle: $_error');
      }
      return false;
    } catch (e) {
      _error = 'Erro ao alternar estado';
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro: $e');
      }
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // === Deletar conteúdo ===
  Future<bool> deleteContent(String contentId) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteClinicContent(contentId);

      // Remover da lista local
      _contents.removeWhere((c) => c.id == contentId);

      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Deletado: $contentId');
      }
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro ao deletar: $_error');
      }
      return false;
    } catch (e) {
      _error = 'Erro ao deletar conteúdo';
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro: $e');
      }
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // === Reordenar conteúdos ===
  Future<bool> reorderContents(List<String> contentIds) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.reorderClinicContents(contentIds);

      // Reordenar lista local
      final reordered = <ClinicContent>[];
      for (final id in contentIds) {
        final item = _contents.firstWhere(
          (c) => c.id == id,
          orElse: () => _contents.first,
        );
        if (!reordered.contains(item)) {
          reordered.add(item);
        }
      }
      _contents = reordered;

      if (kDebugMode) {
        debugPrint(
            '[ClinicContentProvider] Reordenados ${contentIds.length} itens');
      }
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro ao reordenar: $_error');
      }
      return false;
    } catch (e) {
      _error = 'Erro ao reordenar';
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro: $e');
      }
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // === Atualizar item local (para UI otimista) ===
  void updateLocalItem(String id, ClinicContent updated) {
    final idx = _contents.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _contents[idx] = updated;
      notifyListeners();
    }
  }

  // === Limpar erro ===
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // === Limpar conteúdos ===
  void clearContents() {
    _contents = [];
    _currentType = null;
    notifyListeners();
  }

  // ==================== CONTENT TEMPLATES ====================

  List<ContentTemplate> _templates = [];
  bool _isLoadingTemplates = false;

  List<ContentTemplate> get templates => _templates;
  bool get isLoadingTemplates => _isLoadingTemplates;

  /// Carregar templates por tipo (opcional)
  Future<void> loadTemplates({String? type}) async {
    _isLoadingTemplates = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getContentTemplates(type: type);
      _templates = data
          .map((item) => ContentTemplate.fromJson(item as Map<String, dynamic>))
          .toList();
      _templates.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (kDebugMode) {
        debugPrint(
            '[ClinicContentProvider] Templates carregados: ${_templates.length}');
      }
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
    } catch (e) {
      _error = 'Erro ao carregar templates';
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro templates: $e');
      }
    } finally {
      _isLoadingTemplates = false;
      notifyListeners();
    }
  }

  /// Criar template
  Future<bool> createTemplate({
    required String type,
    required String category,
    required String title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createContentTemplate(
        type: type,
        category: category,
        title: title,
        description: description,
        validFromDay: validFromDay,
        validUntilDay: validUntilDay,
      );

      final newTemplate = ContentTemplate.fromJson(result);
      _templates.add(newTemplate);

      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Template criado: ${newTemplate.id}');
      }
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      return false;
    } catch (e) {
      _error = 'Erro ao criar template';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Atualizar template
  Future<bool> updateTemplate(
    String templateId, {
    String? title,
    String? description,
    String? category,
    int? validFromDay,
    int? validUntilDay,
    bool? isActive,
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.updateContentTemplate(
        templateId,
        title: title,
        description: description,
        category: category,
        validFromDay: validFromDay,
        validUntilDay: validUntilDay,
        isActive: isActive,
      );

      final idx = _templates.indexWhere((t) => t.id == templateId);
      if (idx != -1) {
        _templates[idx] = ContentTemplate.fromJson(result);
      }

      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      return false;
    } catch (e) {
      _error = 'Erro ao atualizar template';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Toggle template ativo/inativo
  Future<bool> toggleTemplate(String templateId) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.toggleContentTemplate(templateId);

      final idx = _templates.indexWhere((t) => t.id == templateId);
      if (idx != -1) {
        _templates[idx] = ContentTemplate.fromJson(result);
      }

      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      return false;
    } catch (e) {
      _error = 'Erro ao alternar template';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Deletar template
  Future<bool> deleteTemplate(String templateId) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteContentTemplate(templateId);
      _templates.removeWhere((t) => t.id == templateId);

      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      return false;
    } catch (e) {
      _error = 'Erro ao deletar template';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // ==================== PATIENT CONTENT OVERRIDES ====================

  List<PatientContentOverride> _patientOverrides = [];
  String? _selectedPatientId;
  bool _isLoadingOverrides = false;

  List<PatientContentOverride> get patientOverrides => _patientOverrides;
  String? get selectedPatientId => _selectedPatientId;
  bool get isLoadingOverrides => _isLoadingOverrides;

  /// Carregar overrides de um paciente
  Future<void> loadPatientOverrides(String patientId) async {
    _selectedPatientId = patientId;
    _isLoadingOverrides = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getPatientContentOverrides(patientId);
      _patientOverrides = data
          .map((item) =>
              PatientContentOverride.fromJson(item as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        debugPrint(
            '[ClinicContentProvider] Overrides carregados: ${_patientOverrides.length}');
      }
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
    } catch (e) {
      _error = 'Erro ao carregar overrides';
      if (kDebugMode) {
        debugPrint('[ClinicContentProvider] Erro overrides: $e');
      }
    } finally {
      _isLoadingOverrides = false;
      notifyListeners();
    }
  }

  /// Criar override para paciente
  /// action: 'ADD' | 'DISABLE' | 'MODIFY'
  Future<bool> createPatientOverride({
    required String patientId,
    String? templateId,
    required String action,
    String? type,
    String? category,
    String? title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
    String? reason,
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createPatientContentOverride(
        patientId: patientId,
        templateId: templateId,
        action: action,
        type: type,
        category: category,
        title: title,
        description: description,
        validFromDay: validFromDay,
        validUntilDay: validUntilDay,
        reason: reason,
      );

      final newOverride = PatientContentOverride.fromJson(result);
      _patientOverrides.add(newOverride);

      if (kDebugMode) {
        debugPrint(
            '[ClinicContentProvider] Override criado: ${newOverride.id}');
      }
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      return false;
    } catch (e) {
      _error = 'Erro ao criar override';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Deletar override de paciente
  Future<bool> deletePatientOverride(
      String patientId, String overrideId) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deletePatientContentOverride(patientId, overrideId);
      _patientOverrides.removeWhere((o) => o.id == overrideId);

      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      return false;
    } catch (e) {
      _error = 'Erro ao deletar override';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Limpar overrides
  void clearOverrides() {
    _patientOverrides = [];
    _selectedPatientId = null;
    notifyListeners();
  }
}
