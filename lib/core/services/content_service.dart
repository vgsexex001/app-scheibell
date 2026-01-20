import 'api_service.dart';

/// Tipos de conteúdo disponíveis (espelha o enum do backend)
enum ContentType {
  symptoms,
  diet,
  activities,
  care,
  training,
  exams,
  documents,
  medications,
  diary,
}

/// Categorias de conteúdo (espelha o enum do backend)
enum ContentCategory {
  normal,     // Verde - esperado
  warning,    // Amarelo - avisar
  emergency,  // Vermelho - emergência
  allowed,    // Permitido/Recomendado
  restricted, // Evitar/Com moderação
  prohibited, // Proibido
  info,       // Informativo
}

/// Modelo de conteúdo
class ContentItem {
  final String id;
  final ContentType type;
  final ContentCategory category;
  final String title;
  final String? description;
  final int? validFromDay;
  final int? validUntilDay;
  final int sortOrder;
  final bool isActive;
  final bool isCustom;

  ContentItem({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    this.description,
    this.validFromDay,
    this.validUntilDay,
    this.sortOrder = 0,
    this.isActive = true,
    this.isCustom = false,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] as String,
      type: _parseContentType(json['type'] as String?),
      category: _parseCategory(json['category'] as String?),
      title: json['title'] as String,
      description: json['description'] as String?,
      validFromDay: json['validFromDay'] as int?,
      validUntilDay: json['validUntilDay'] as int?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  static ContentType _parseContentType(String? type) {
    if (type == null) return ContentType.symptoms;
    switch (type.toUpperCase()) {
      case 'SYMPTOMS':
        return ContentType.symptoms;
      case 'DIET':
        return ContentType.diet;
      case 'ACTIVITIES':
        return ContentType.activities;
      case 'CARE':
        return ContentType.care;
      case 'TRAINING':
        return ContentType.training;
      case 'EXAMS':
        return ContentType.exams;
      case 'DOCUMENTS':
        return ContentType.documents;
      case 'MEDICATIONS':
        return ContentType.medications;
      case 'DIARY':
        return ContentType.diary;
      default:
        return ContentType.symptoms;
    }
  }

  static ContentCategory _parseCategory(String? category) {
    if (category == null) return ContentCategory.info;
    switch (category.toUpperCase()) {
      case 'NORMAL':
        return ContentCategory.normal;
      case 'WARNING':
        return ContentCategory.warning;
      case 'EMERGENCY':
        return ContentCategory.emergency;
      case 'ALLOWED':
        return ContentCategory.allowed;
      case 'RESTRICTED':
        return ContentCategory.restricted;
      case 'PROHIBITED':
        return ContentCategory.prohibited;
      case 'INFO':
        return ContentCategory.info;
      default:
        return ContentCategory.info;
    }
  }
}

/// Serviço para gerenciar conteúdo de recuperação
class ContentService {
  final ApiService _apiService = ApiService();

  /// Busca conteúdo da clínica por tipo (usa endpoint de paciente)
  Future<List<ContentItem>> getClinicContent({
    required ContentType type,
    ContentCategory? category,
  }) async {
    try {
      final typeStr = type.name.toUpperCase();
      final categoryStr = category?.name.toUpperCase();

      // Usar endpoint de paciente que busca conteúdo da clínica do paciente
      final data = await _apiService.getPatientClinicContent(
        type: typeStr,
        category: categoryStr,
      );

      return data.map((item) => ContentItem.fromJson(item)).toList();
    } catch (e) {
      print('Erro ao buscar conteúdo da clínica: $e');
      return [];
    }
  }

  /// Busca todo conteúdo da clínica por tipo (usa endpoint de paciente)
  Future<List<ContentItem>> getAllClinicContentByType(ContentType type) async {
    try {
      final typeStr = type.name.toUpperCase();
      // Usar endpoint de paciente
      final data = await _apiService.getAllPatientClinicContentByType(typeStr);
      return data.map((item) => ContentItem.fromJson(item)).toList();
    } catch (e) {
      print('Erro ao buscar todo conteúdo: $e');
      return [];
    }
  }

  /// Busca conteúdo personalizado do paciente
  Future<List<ContentItem>> getPatientContent({
    required ContentType type,
    int? postOpDay,
  }) async {
    try {
      final typeStr = type.name.toUpperCase();
      final data = await _apiService.getPatientContent(
        type: typeStr,
        day: postOpDay,
      );
      return data.map((item) => ContentItem.fromJson(item)).toList();
    } catch (e) {
      print('Erro ao buscar conteúdo do paciente: $e');
      return [];
    }
  }

  /// Busca sintomas por categoria
  Future<Map<ContentCategory, List<ContentItem>>> getSymptomsByCategory() async {
    final symptoms = await getAllClinicContentByType(ContentType.symptoms);

    return {
      ContentCategory.normal: symptoms
          .where((s) => s.category == ContentCategory.normal)
          .toList(),
      ContentCategory.warning: symptoms
          .where((s) => s.category == ContentCategory.warning)
          .toList(),
      ContentCategory.emergency: symptoms
          .where((s) => s.category == ContentCategory.emergency)
          .toList(),
    };
  }

  /// Busca cuidados organizados
  Future<List<ContentItem>> getCareItems() async {
    return getAllClinicContentByType(ContentType.care);
  }

  /// Busca atividades por categoria
  Future<Map<ContentCategory, List<ContentItem>>> getActivitiesByCategory() async {
    final activities = await getAllClinicContentByType(ContentType.activities);

    return {
      ContentCategory.allowed: activities
          .where((a) => a.category == ContentCategory.allowed)
          .toList(),
      ContentCategory.restricted: activities
          .where((a) => a.category == ContentCategory.restricted)
          .toList(),
      ContentCategory.prohibited: activities
          .where((a) => a.category == ContentCategory.prohibited)
          .toList(),
    };
  }

  /// Busca dieta por categoria
  Future<Map<ContentCategory, List<ContentItem>>> getDietByCategory() async {
    final diet = await getAllClinicContentByType(ContentType.diet);

    return {
      ContentCategory.allowed: diet
          .where((d) => d.category == ContentCategory.allowed)
          .toList(),
      ContentCategory.restricted: diet
          .where((d) => d.category == ContentCategory.restricted)
          .toList(),
      ContentCategory.prohibited: diet
          .where((d) => d.category == ContentCategory.prohibited)
          .toList(),
    };
  }

  /// Busca treinos/exercícios
  Future<List<ContentItem>> getTrainingItems() async {
    return getAllClinicContentByType(ContentType.training);
  }

  /// Busca medicamentos do paciente (apenas medicamentos adicionados pelo paciente ou pelo médico)
  Future<List<ContentItem>> getMedications() async {
    try {
      // Usar endpoint que retorna apenas medicamentos específicos do paciente
      // (adicionados pelo próprio paciente ou pelo médico/admin)
      final data = await _apiService.getPatientContent(
        type: 'MEDICATIONS',
      );

      return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Erro ao buscar medicamentos: $e');
      return [];
    }
  }

  /// Busca medicamentos por categoria (Permitido, Evitar, Proibido)
  /// Retorna mapa organizado por categoria usando ALLOWED, RESTRICTED, PROHIBITED do backend
  Future<Map<String, List<ContentItem>>> getMedicationsByCategory() async {
    try {
      // Buscar todos os medicamentos da clínica
      final medications = await getAllClinicContentByType(ContentType.medications);

      // Organizar por categoria
      return {
        'allowed': medications
            .where((m) => m.category == ContentCategory.allowed)
            .toList(),
        'restricted': medications
            .where((m) => m.category == ContentCategory.restricted)
            .toList(),
        'prohibited': medications
            .where((m) => m.category == ContentCategory.prohibited)
            .toList(),
      };
    } catch (e) {
      print('Erro ao buscar medicamentos por categoria: $e');
      return {
        'allowed': [],
        'restricted': [],
        'prohibited': [],
      };
    }
  }

  /// Busca medicamentos permitidos
  Future<List<ContentItem>> getAllowedMedications() async {
    try {
      final medications = await getAllClinicContentByType(ContentType.medications);
      return medications.where((m) => m.category == ContentCategory.allowed).toList();
    } catch (e) {
      print('Erro ao buscar medicamentos permitidos: $e');
      return [];
    }
  }

  /// Busca medicamentos a evitar (RESTRICTED)
  Future<List<ContentItem>> getRestrictedMedications() async {
    try {
      final medications = await getAllClinicContentByType(ContentType.medications);
      return medications.where((m) => m.category == ContentCategory.restricted).toList();
    } catch (e) {
      print('Erro ao buscar medicamentos a evitar: $e');
      return [];
    }
  }

  /// Busca medicamentos proibidos
  Future<List<ContentItem>> getProhibitedMedications() async {
    try {
      final medications = await getAllClinicContentByType(ContentType.medications);
      return medications.where((m) => m.category == ContentCategory.prohibited).toList();
    } catch (e) {
      print('Erro ao buscar medicamentos proibidos: $e');
      return [];
    }
  }
}
