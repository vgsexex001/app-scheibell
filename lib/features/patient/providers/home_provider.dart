import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/content_service.dart';
import '../../home/domain/entities/entities.dart';
import '../../home/data/storage/home_progress_storage.dart';

/// Estados possíveis da tela Home
enum HomeStatus { initial, loading, success, error }

/// Dados dinâmicos da Home vindos da API
class DynamicHomeData {
  final String greeting;
  final int dayPostOp;
  final DynamicHomeSummary summary;
  final List<DynamicHomeItem> items;
  final DynamicNextAppointment? nextAppointment;

  DynamicHomeData({
    required this.greeting,
    required this.dayPostOp,
    required this.summary,
    required this.items,
    this.nextAppointment,
  });

  factory DynamicHomeData.fromJson(Map<String, dynamic> json) {
    return DynamicHomeData(
      greeting: json['greeting'] as String? ?? 'Olá!',
      dayPostOp: json['dayPostOp'] as int? ?? 0,
      summary: DynamicHomeSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => DynamicHomeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextAppointment: json['nextAppointment'] != null
          ? DynamicNextAppointment.fromJson(json['nextAppointment'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DynamicHomeSummary {
  final int medicationsPending;
  final int tasksPending;
  final int videosIncomplete;

  DynamicHomeSummary({
    required this.medicationsPending,
    required this.tasksPending,
    required this.videosIncomplete,
  });

  factory DynamicHomeSummary.fromJson(Map<String, dynamic> json) {
    return DynamicHomeSummary(
      medicationsPending: json['medicationsPending'] as int? ?? 0,
      tasksPending: json['tasksPending'] as int? ?? 0,
      videosIncomplete: json['videosIncomplete'] as int? ?? 0,
    );
  }
}

class DynamicHomeItem {
  final String id;
  final String type; // 'MEDICATION', 'VIDEO', 'TASK', 'APPOINTMENT'
  final int priority;
  final String status; // 'PENDING', 'IN_PROGRESS', 'OVERDUE', 'UPCOMING'
  final String title;
  final String? subtitle;
  final String? scheduledTime;
  final DynamicHomeAction? action;
  final Map<String, dynamic>? metadata;

  DynamicHomeItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.status,
    required this.title,
    this.subtitle,
    this.scheduledTime,
    this.action,
    this.metadata,
  });

  factory DynamicHomeItem.fromJson(Map<String, dynamic> json) {
    return DynamicHomeItem(
      id: json['id'] as String,
      type: json['type'] as String,
      priority: json['priority'] as int? ?? 0,
      status: json['status'] as String? ?? 'PENDING',
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      scheduledTime: json['scheduledTime'] as String?,
      action: json['action'] != null
          ? DynamicHomeAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  bool get isOverdue => status == 'OVERDUE';
  bool get isPending => status == 'PENDING';
  bool get isUpcoming => status == 'UPCOMING';
  bool get isMedication => type == 'MEDICATION';
  bool get isVideo => type == 'VIDEO';
  bool get isTask => type == 'TASK';
}

class DynamicHomeAction {
  final String type; // 'TAKE', 'WATCH', 'COMPLETE', 'VIEW'
  final String label;

  DynamicHomeAction({required this.type, required this.label});

  factory DynamicHomeAction.fromJson(Map<String, dynamic> json) {
    return DynamicHomeAction(
      type: json['type'] as String? ?? 'VIEW',
      label: json['label'] as String? ?? 'Ver',
    );
  }
}

class DynamicNextAppointment {
  final String id;
  final String date;
  final String type;
  final String title;

  DynamicNextAppointment({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
  });

  factory DynamicNextAppointment.fromJson(Map<String, dynamic> json) {
    return DynamicNextAppointment(
      id: json['id'] as String,
      date: json['date'] as String,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }
}

/// Estados de loading por seção
class HomeSectionLoading {
  final bool consultas;
  final bool medicacoes;
  final bool cuidados;
  final bool tarefas;

  const HomeSectionLoading({
    this.consultas = false,
    this.medicacoes = false,
    this.cuidados = false,
    this.tarefas = false,
  });

  bool get any => consultas || medicacoes || cuidados || tarefas;

  HomeSectionLoading copyWith({
    bool? consultas,
    bool? medicacoes,
    bool? cuidados,
    bool? tarefas,
  }) {
    return HomeSectionLoading(
      consultas: consultas ?? this.consultas,
      medicacoes: medicacoes ?? this.medicacoes,
      cuidados: cuidados ?? this.cuidados,
      tarefas: tarefas ?? this.tarefas,
    );
  }
}

/// Provider para gerenciar o estado da tela Home
class HomeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ContentService _contentService = ContentService();
  final HomeProgressStorage _storage = HomeProgressStorage();

  HomeStatus _status = HomeStatus.initial;
  String? _errorMessage;
  HomeSectionLoading _sectionLoading = const HomeSectionLoading();
  DateTime _selectedDate = DateTime.now();

  // Dados das consultas
  List<Map<String, dynamic>> _consultas = [];

  // Dados estruturados com novas entidades
  List<Medication> _medications = [];
  List<CareItem> _careItems = [];
  List<TaskVideoItem> _taskVideos = [];

  // Dados brutos do backend para compatibilidade
  List<ContentItem> _medicacoesRaw = [];
  List<ContentItem> _cuidadosRaw = [];
  List<ContentItem> _tarefasRaw = [];
  List<dynamic> _logsHoje = [];
  Map<String, dynamic> _adesaoData = {};

  // Dados dinâmicos da Home (novo endpoint)
  DynamicHomeData? _dynamicHomeData;
  List<DynamicHomeItem> _dynamicItems = [];

  // ==================== GETTERS DE ESTADO ====================

  HomeStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == HomeStatus.loading;
  bool get hasError => _status == HomeStatus.error;
  bool get isSuccess => _status == HomeStatus.success;
  HomeSectionLoading get sectionLoading => _sectionLoading;
  DateTime get selectedDate => _selectedDate;

  // ==================== GETTERS DE DADOS ====================

  List<Map<String, dynamic>> get consultas => _consultas;
  List<Medication> get medications => _medications;
  List<CareItem> get careItems => _careItems;
  List<TaskVideoItem> get taskVideos => _taskVideos;

  // Getters de compatibilidade com código antigo
  List<ContentItem> get medicacoes => _medicacoesRaw;
  List<ContentItem> get cuidados => _cuidadosRaw;
  List<ContentItem> get tarefas => _tarefasRaw;
  List<dynamic> get logsHoje => _logsHoje;
  Map<String, dynamic> get adesaoData => _adesaoData;

  bool get carregandoConsultas => _sectionLoading.consultas;
  bool get carregandoConteudo =>
      _sectionLoading.medicacoes ||
      _sectionLoading.cuidados ||
      _sectionLoading.tarefas;

  // ==================== GETTERS DA HOME DINÂMICA ====================

  DynamicHomeData? get dynamicHomeData => _dynamicHomeData;
  List<DynamicHomeItem> get dynamicItems => _dynamicItems;
  String get dynamicGreeting => _dynamicHomeData?.greeting ?? 'Olá!';
  int get dynamicDayPostOp => _dynamicHomeData?.dayPostOp ?? 0;
  DynamicHomeSummary? get dynamicSummary => _dynamicHomeData?.summary;
  DynamicNextAppointment? get dynamicNextAppointment => _dynamicHomeData?.nextAppointment;

  // Filtros por tipo nos itens dinâmicos
  List<DynamicHomeItem> get dynamicMedications =>
      _dynamicItems.where((i) => i.isMedication).toList();
  List<DynamicHomeItem> get dynamicVideos =>
      _dynamicItems.where((i) => i.isVideo).toList();
  List<DynamicHomeItem> get dynamicTasks =>
      _dynamicItems.where((i) => i.isTask).toList();

  // Itens urgentes (OVERDUE)
  List<DynamicHomeItem> get urgentItems =>
      _dynamicItems.where((i) => i.isOverdue).toList();

  // Verifica se tem itens pendentes da API dinâmica
  bool get hasDynamicData => _dynamicHomeData != null && _dynamicItems.isNotEmpty;

  /// Verifica se não há dados para exibir
  bool get isEmpty =>
      _consultas.isEmpty &&
      _medications.isEmpty &&
      _careItems.isEmpty &&
      _taskVideos.isEmpty;

  /// Verifica se há dados parciais
  bool get hasData =>
      _consultas.isNotEmpty ||
      _medications.isNotEmpty ||
      _careItems.isNotEmpty ||
      _taskVideos.isNotEmpty;

  // ==================== CONTADORES (BADGES) ====================

  /// Total de doses tomadas hoje
  int get medicationDosesTaken {
    int count = 0;
    for (final med in _medications) {
      count += med.dosesTakenToday;
    }
    return count;
  }

  /// Total de doses para hoje
  int get medicationDosesTotal {
    int count = 0;
    for (final med in _medications) {
      count += med.totalDosesToday;
    }
    return count;
  }

  /// Cuidados completados hoje
  int get careItemsCompleted => _careItems.where((c) => c.completed).length;
  int get careItemsTotal => _careItems.length;

  /// Tarefas/vídeos completados hoje
  int get taskVideosCompleted => _taskVideos.where((t) => t.completed).length;
  int get taskVideosTotal => _taskVideos.length;

  // Aliases para compatibilidade
  int get medicacoesTomadas => medicationDosesTaken;
  int get totalMedicacoes => medicationDosesTotal;
  int get totalCuidados => careItemsTotal;
  int get totalTarefas => taskVideosTotal;

  // ==================== SCORE E PROGRESSO ====================

  double get scoreSaude {
    if (_adesaoData.isEmpty) return 8.5;
    final adesao = _adesaoData['adherence'] as int? ?? 85;
    return (adesao / 10).clamp(0.0, 10.0);
  }

  String get mensagemScore {
    final score = scoreSaude;
    if (score >= 9) {
      return 'Excelente! Continue seguindo as orientações médicas.';
    }
    if (score >= 7) {
      return 'Muito bom! Mantenha o ritmo de recuperação.';
    }
    if (score >= 5) {
      return 'Bom progresso. Tente não esquecer as medicações.';
    }
    return 'Atenção: Siga as orientações para melhorar sua recuperação.';
  }

  /// Progresso diário geral (medicações + cuidados + tarefas)
  double get progressoDiario {
    final totalItems = medicationDosesTotal + careItemsTotal + taskVideosTotal;
    if (totalItems == 0) return 0.75;

    final completedItems =
        medicationDosesTaken + careItemsCompleted + taskVideosCompleted;
    return (completedItems / totalItems).clamp(0.0, 1.0);
  }

  // ==================== COMPATIBILIDADE ====================

  bool foiTomadoHoje(String contentId) {
    return _logsHoje.any((log) => log['contentId'] == contentId);
  }

  String? extrairProximoHorario(String? descricao) {
    if (descricao == null) return null;
    final horariosMatch =
        RegExp(r'Horários:\s*([0-9:,\s]+)').firstMatch(descricao);
    if (horariosMatch != null) {
      final horariosStr = horariosMatch.group(1) ?? '';
      final horarios = horariosStr.split(',').map((h) => h.trim()).toList();
      final agora = DateTime.now();
      for (final h in horarios) {
        final partes = h.split(':');
        if (partes.length >= 2) {
          final hora = int.tryParse(partes[0]) ?? 0;
          final minuto = int.tryParse(partes[1]) ?? 0;
          if (hora > agora.hour ||
              (hora == agora.hour && minuto > agora.minute)) {
            return h;
          }
        }
      }
      return horarios.isNotEmpty ? horarios.first : null;
    }
    return null;
  }

  String? extrairDosagem(String? descricao) {
    if (descricao == null) return null;
    final dosagemMatch = RegExp(r'Dosagem:\s*([^|]+)').firstMatch(descricao);
    if (dosagemMatch != null) {
      return dosagemMatch.group(1)?.trim();
    }
    final partes = descricao.split('|');
    return partes.isNotEmpty ? partes.first.trim() : null;
  }

  // ==================== CARREGAMENTO DE DADOS ====================

  Future<void> loadAll() async {
    if (_status == HomeStatus.loading) return;

    _status = HomeStatus.loading;
    _errorMessage = null;
    _sectionLoading = const HomeSectionLoading(
      consultas: true,
      medicacoes: true,
      cuidados: true,
      tarefas: true,
    );
    notifyListeners();

    try {
      // Inicializa storage
      await _storage.init();

      // Carrega dados em paralelo
      await Future.wait([
        _carregarConsultas(),
        _carregarConteudo(),
        _carregarHomeDinamica(),
      ]);

      // Aplica progresso salvo localmente
      await _aplicarProgressoLocal();

      _status = HomeStatus.success;
    } catch (e) {
      _status = HomeStatus.error;
      _errorMessage = 'Erro ao carregar dados. Tente novamente.';
      debugPrint('HomeProvider Error: $e');
    }

    notifyListeners();
  }

  Future<void> _carregarConsultas() async {
    _sectionLoading = _sectionLoading.copyWith(consultas: true);
    try {
      // Carrega 3 consultas para exibir na Home
      final consultas = await _apiService.getUpcomingAppointments(limit: 3);
      _consultas = consultas.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Erro ao carregar consultas: $e');
    } finally {
      _sectionLoading = _sectionLoading.copyWith(consultas: false);
    }
  }

  Future<void> _carregarConteudo() async {
    _sectionLoading = _sectionLoading.copyWith(
      medicacoes: true,
      cuidados: true,
      tarefas: true,
    );

    try {
      final results = await Future.wait([
        _contentService.getMedications(),
        _contentService.getCareItems(),
        _contentService.getTrainingItems(),
        _apiService.getTodayMedicationLogs().catchError((_) => <dynamic>[]),
        _apiService
            .getMedicationAdherence(days: 7)
            .catchError((_) => <String, dynamic>{}),
      ]);

      _medicacoesRaw = results[0] as List<ContentItem>;
      _cuidadosRaw = results[1] as List<ContentItem>;
      _tarefasRaw = results[2] as List<ContentItem>;
      _logsHoje = results[3] as List<dynamic>;
      _adesaoData = results[4] as Map<String, dynamic>;

      // Converte para novas entidades
      _medications = _converterMedicacoes(_medicacoesRaw);
      _careItems = _converterCuidados(_cuidadosRaw);
      _taskVideos = _converterTarefas(_tarefasRaw);
    } catch (e) {
      debugPrint('Erro ao carregar conteúdo: $e');
      rethrow;
    } finally {
      _sectionLoading = _sectionLoading.copyWith(
        medicacoes: false,
        cuidados: false,
        tarefas: false,
      );
    }
  }

  /// Carrega dados da Home dinâmica (novo endpoint)
  Future<void> _carregarHomeDinamica() async {
    try {
      final response = await _apiService.get('/patient/home');

      if (response.statusCode == 200 && response.data != null) {
        _dynamicHomeData = DynamicHomeData.fromJson(response.data as Map<String, dynamic>);
        _dynamicItems = _dynamicHomeData?.items ?? [];
        debugPrint('✅ Home dinâmica carregada: ${_dynamicItems.length} itens');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar home dinâmica (usando dados locais): $e');
      // Não lança erro - fallback para dados locais
    }
  }

  /// Converte ContentItem para Medication com doses
  List<Medication> _converterMedicacoes(List<ContentItem> items) {
    return items.map((item) {
      // Extrai horários da descrição
      final times = _extrairHorarios(item.description);
      final json = {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'category': item.category.name.toUpperCase(),
      };
      return Medication.fromContentItem(json, times);
    }).toList();
  }

  /// Extrai horários da descrição (formato "Horários: 08:00, 14:00, 20:00")
  List<String> _extrairHorarios(String? descricao) {
    if (descricao == null) return ['08:00']; // Default

    final horariosMatch =
        RegExp(r'Horários:\s*([0-9:,\s]+)').firstMatch(descricao);
    if (horariosMatch != null) {
      final horariosStr = horariosMatch.group(1) ?? '';
      return horariosStr.split(',').map((h) => h.trim()).toList();
    }

    // Tenta extrair formato "8/8h"
    final freqMatch = RegExp(r'(\d+)/(\d+)h').firstMatch(descricao);
    if (freqMatch != null) {
      final interval = int.tryParse(freqMatch.group(2) ?? '8') ?? 8;
      final times = <String>[];
      for (int hour = 8; hour < 24; hour += interval) {
        times.add('${hour.toString().padLeft(2, '0')}:00');
      }
      return times.isNotEmpty ? times : ['08:00'];
    }

    return ['08:00']; // Default
  }

  /// Converte ContentItem para CareItem
  List<CareItem> _converterCuidados(List<ContentItem> items) {
    return items.map((item) {
      final json = {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'category': item.category.name.toUpperCase(),
        'validFromDay': item.validFromDay,
        'validUntilDay': item.validUntilDay,
        'sortOrder': item.sortOrder,
      };
      return CareItem.fromContentItem(json);
    }).toList();
  }

  /// Converte ContentItem para TaskVideoItem
  List<TaskVideoItem> _converterTarefas(List<ContentItem> items) {
    return items.map((item) {
      final json = {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'validFromDay': item.validFromDay,
        'validUntilDay': item.validUntilDay,
        'sortOrder': item.sortOrder,
      };
      return TaskVideoItem.fromContentItem(json);
    }).toList();
  }

  /// Aplica progresso salvo localmente
  Future<void> _aplicarProgressoLocal() async {
    final allProgress = await _storage.loadAllProgress(date: _selectedDate);

    // Aplica progresso das medicações
    final medProgress = allProgress['medications'] ?? {};
    _medications = _medications.map((med) {
      final updatedDoses = med.doses.map((dose) {
        final doseData = medProgress[dose.id];
        if (doseData != null && doseData['taken'] == true) {
          return dose.copyWith(
            taken: true,
            takenAt: doseData['takenAt'] != null
                ? DateTime.tryParse(doseData['takenAt'])
                : null,
          );
        }
        return dose;
      }).toList();
      return med.copyWith(doses: updatedDoses);
    }).toList();

    // Aplica progresso dos cuidados
    final careProgress = allProgress['care'] ?? {};
    _careItems = _careItems.map((care) {
      final careData = careProgress[care.id];
      if (careData != null && careData['completed'] == true) {
        return care.copyWith(
          completed: true,
          completedAt: careData['completedAt'] != null
              ? DateTime.tryParse(careData['completedAt'])
              : null,
        );
      }
      return care;
    }).toList();

    // Aplica progresso das tarefas/vídeos
    final taskProgress = allProgress['taskVideos'] ?? {};
    _taskVideos = _taskVideos.map((task) {
      final taskData = taskProgress[task.id];
      if (taskData != null && taskData['completed'] == true) {
        return task.copyWith(
          completed: true,
          completedAt: taskData['completedAt'] != null
              ? DateTime.tryParse(taskData['completedAt'])
              : null,
        );
      }
      return task;
    }).toList();
  }

  // ==================== TOGGLE METHODS ====================

  /// Marca/desmarca uma dose de medicação
  Future<void> toggleMedicationDose(String medicationId, String doseId) async {
    // Encontra a medicação e dose
    final medIndex = _medications.indexWhere((m) => m.id == medicationId);
    if (medIndex == -1) return;

    final medication = _medications[medIndex];
    final doseIndex = medication.doses.indexWhere((d) => d.id == doseId);
    if (doseIndex == -1) return;

    final dose = medication.doses[doseIndex];
    final newTaken = !dose.taken;

    // Atualiza localmente
    final updatedDoses = List<MedicationDose>.from(medication.doses);
    updatedDoses[doseIndex] = dose.copyWith(
      taken: newTaken,
      takenAt: newTaken ? DateTime.now() : null,
    );

    _medications[medIndex] = medication.copyWith(doses: updatedDoses);
    notifyListeners();

    // Salva progresso
    await _storage.saveMedicationProgress(
      medicationId,
      doseId,
      newTaken,
      date: _selectedDate,
    );

    // Tenta registrar no backend (se marcou como tomado)
    if (newTaken) {
      try {
        await _apiService.logMedication(
          contentId: medicationId,
          scheduledTime: dose.time,
        );
        debugPrint('✅ Medicação registrada no backend');
      } catch (e) {
        debugPrint('⚠️ Erro ao registrar no backend (salvo localmente): $e');
      }
    }
  }

  /// Marca/desmarca um item de cuidado
  Future<void> toggleCareItem(String careId) async {
    final index = _careItems.indexWhere((c) => c.id == careId);
    if (index == -1) return;

    final care = _careItems[index];
    final newCompleted = !care.completed;

    // Atualiza localmente
    _careItems[index] = care.copyWith(
      completed: newCompleted,
      completedAt: newCompleted ? DateTime.now() : null,
    );
    notifyListeners();

    // Salva progresso
    await _storage.saveCareProgress(
      careId,
      newCompleted,
      date: _selectedDate,
    );
  }

  /// Marca/desmarca uma tarefa ou vídeo
  Future<void> toggleTaskVideo(String itemId) async {
    final index = _taskVideos.indexWhere((t) => t.id == itemId);
    if (index == -1) return;

    final task = _taskVideos[index];
    final newCompleted = !task.completed;

    // Atualiza localmente
    _taskVideos[index] = task.copyWith(
      completed: newCompleted,
      completedAt: newCompleted ? DateTime.now() : null,
    );
    notifyListeners();

    // Salva progresso
    await _storage.saveTaskVideoProgress(
      itemId,
      newCompleted,
      date: _selectedDate,
    );
  }

  // ==================== AÇÕES DA HOME DINÂMICA ====================

  /// Marca medicação como tomada (via Home dinâmica)
  Future<bool> takeDynamicMedication(DynamicHomeItem item) async {
    if (!item.isMedication) return false;

    final contentId = item.metadata?['contentId'] as String?;
    final scheduledTime = item.metadata?['scheduledTime'] as String? ?? item.scheduledTime;

    if (contentId == null || scheduledTime == null) {
      debugPrint('⚠️ Dados incompletos para tomar medicação');
      return false;
    }

    try {
      await _apiService.post('/patient/home/medication/take', data: {
        'contentId': contentId,
        'scheduledTime': scheduledTime,
      });

      // Remove item localmente (atualização otimista)
      _dynamicItems = _dynamicItems.where((i) => i.id != item.id).toList();
      notifyListeners();

      debugPrint('✅ Medicação tomada: ${item.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao tomar medicação: $e');
      return false;
    }
  }

  /// Completa uma tarefa (via Home dinâmica)
  Future<bool> completeDynamicTask(DynamicHomeItem item, {String? notes}) async {
    if (!item.isTask) return false;

    final taskId = item.metadata?['taskId'] as String?;

    if (taskId == null) {
      debugPrint('⚠️ TaskId não encontrado');
      return false;
    }

    try {
      await _apiService.post('/patient/home/task/complete', data: {
        'taskId': taskId,
        if (notes != null) 'notes': notes,
      });

      // Remove item localmente
      _dynamicItems = _dynamicItems.where((i) => i.id != item.id).toList();
      notifyListeners();

      debugPrint('✅ Tarefa completada: ${item.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao completar tarefa: $e');
      return false;
    }
  }

  /// Atualiza progresso de vídeo (via Home dinâmica)
  Future<bool> updateDynamicVideoProgress(
    DynamicHomeItem item, {
    required int watchedSeconds,
    required int totalSeconds,
    bool? isCompleted,
  }) async {
    if (!item.isVideo) return false;

    final contentId = item.metadata?['contentId'] as String?;

    if (contentId == null) {
      debugPrint('⚠️ ContentId não encontrado para vídeo');
      return false;
    }

    try {
      await _apiService.post('/patient/home/video/progress', data: {
        'contentId': contentId,
        'watchedSeconds': watchedSeconds,
        'totalSeconds': totalSeconds,
        if (isCompleted != null) 'isCompleted': isCompleted,
      });

      // Se completou, remove da lista
      if (isCompleted == true || (watchedSeconds / totalSeconds) >= 0.9) {
        _dynamicItems = _dynamicItems.where((i) => i.id != item.id).toList();
        notifyListeners();
      }

      debugPrint('✅ Progresso do vídeo atualizado: ${item.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar progresso do vídeo: $e');
      return false;
    }
  }

  /// Executa ação de um item dinâmico baseado no tipo
  Future<bool> executeDynamicAction(DynamicHomeItem item) async {
    switch (item.type) {
      case 'MEDICATION':
        return takeDynamicMedication(item);
      case 'TASK':
        return completeDynamicTask(item);
      case 'VIDEO':
        // Vídeo requer parâmetros adicionais, retorna false
        debugPrint('⚠️ Para vídeo, use updateDynamicVideoProgress');
        return false;
      default:
        debugPrint('⚠️ Tipo de item não suportado: ${item.type}');
        return false;
    }
  }

  // ==================== REFRESH E RESET ====================

  Future<void> refresh() async {
    _errorMessage = null;

    try {
      await Future.wait([
        _carregarConsultas(),
        _carregarConteudo(),
        _carregarHomeDinamica(),
      ]);

      // Reaplicar progresso local
      await _aplicarProgressoLocal();

      _status = HomeStatus.success;
    } catch (e) {
      if (!hasData) {
        _status = HomeStatus.error;
        _errorMessage = 'Erro ao atualizar dados. Tente novamente.';
      }
      debugPrint('HomeProvider Refresh Error: $e');
    }

    notifyListeners();
  }

  void reset() {
    _status = HomeStatus.initial;
    _errorMessage = null;
    _sectionLoading = const HomeSectionLoading();
    _consultas = [];
    _medications = [];
    _careItems = [];
    _taskVideos = [];
    _medicacoesRaw = [];
    _cuidadosRaw = [];
    _tarefasRaw = [];
    _logsHoje = [];
    _adesaoData = {};
    _dynamicHomeData = null;
    _dynamicItems = [];

    // Limpa progresso local
    _storage.clearAllProgress();

    notifyListeners();
  }

  /// Muda a data selecionada e recarrega progresso
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await _aplicarProgressoLocal();
    notifyListeners();
  }
}
