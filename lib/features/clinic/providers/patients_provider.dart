  import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../../../core/services/api_service.dart';

class PatientsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estado da lista de pacientes
  List<PatientListItem> _patients = [];
  bool _isLoadingList = false;
  int _currentPage = 1;
  int _totalPatients = 0;
  int _totalPages = 1;
  String? _currentSearch;
  String? _currentStatus;

  // Estado do paciente selecionado
  PatientDetail? _selectedPatient;
  bool _isLoadingDetail = false;

  // Estado do histórico
  List<PatientHistoryItem> _historyItems = [];
  bool _isLoadingHistory = false;
  int _historyPage = 1;
  int _historyTotal = 0;
  int _historyTotalPages = 1;

  // Erro
  String? _error;

  // Estado de operações
  bool _isOperating = false;

  // Getters
  List<PatientListItem> get patients => _patients;
  bool get isLoadingList => _isLoadingList;
  int get currentPage => _currentPage;
  int get totalPatients => _totalPatients;
  int get totalPages => _totalPages;
  bool get hasMore => _currentPage < _totalPages;

  PatientDetail? get selectedPatient => _selectedPatient;
  bool get isLoadingDetail => _isLoadingDetail;

  List<PatientHistoryItem> get historyItems => _historyItems;
  bool get isLoadingHistory => _isLoadingHistory;
  int get historyPage => _historyPage;
  int get historyTotal => _historyTotal;
  bool get hasMoreHistory => _historyPage < _historyTotalPages;

  String? get error => _error;
  bool get isOperating => _isOperating;

  /// Carrega lista de pacientes
  Future<void> loadPatients({
    String? search,
    String? status,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _patients = [];
    }

    _currentSearch = search;
    _currentStatus = status;
    _isLoadingList = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getPatients(
        page: _currentPage,
        limit: 20,
        search: search,
        status: status,
      );

      final response = PatientsListResponse.fromJson(data);

      if (refresh || _currentPage == 1) {
        _patients = response.items;
      } else {
        _patients = [..._patients, ...response.items];
      }

      _totalPatients = response.total;
      _totalPages = response.totalPages;

      if (kDebugMode) {
        debugPrint(
          '[PatientsProvider] Carregados ${response.items.length} pacientes',
        );
        debugPrint(
          '[PatientsProvider] Total: $_totalPatients, Página: $_currentPage/$_totalPages',
        );
        if (response.items.isNotEmpty) {
          debugPrint(
            '[PatientsProvider] Primeiro ID: ${response.items.first.id}',
          );
        }
      }
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[PatientsProvider] Erro ao carregar pacientes: $_error');
    } catch (e) {
      _error = 'Erro inesperado ao carregar pacientes';
      debugPrint('[PatientsProvider] Erro: $e');
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  /// Carrega mais pacientes (paginação)
  Future<void> loadMore() async {
    if (_isLoadingList || !hasMore) return;

    _currentPage++;
    await loadPatients(search: _currentSearch, status: _currentStatus);
  }

  /// Atualiza lista (refresh)
  Future<void> refresh() async {
    await loadPatients(
      search: _currentSearch,
      status: _currentStatus,
      refresh: true,
    );
  }

  /// Carrega detalhes de um paciente
  Future<void> loadPatientDetail(String patientId) async {
    _isLoadingDetail = true;
    _error = null;
    _selectedPatient = null;
    notifyListeners();

    // Log obrigatório: patientId recebido
    debugPrint('[PATIENT_DETAILS] patientId=$patientId');
    debugPrint('[PATIENT_DETAILS] patientId.length=${patientId.length}');
    debugPrint('[PATIENT_DETAILS] patientId.runtimeType=${patientId.runtimeType}');

    // Validação expandida de patientId
    if (patientId.isEmpty) {
      _error = 'ID do paciente inválido (vazio)';
      debugPrint('[PATIENT_DETAILS] ERROR: patientId está vazio!');
      _isLoadingDetail = false;
      notifyListeners();
      return;
    }

    // Detectar placeholders locais que não existem no backend
    if (patientId == 'new' ||
        patientId == 'novo' ||
        patientId.startsWith('local-') ||
        patientId.startsWith('temp-') ||
        patientId == 'undefined' ||
        patientId == 'null') {
      _error = 'Este paciente ainda não foi salvo no servidor';
      debugPrint('[PATIENT_DETAILS] ERROR: patientId é placeholder local: "$patientId"');
      _isLoadingDetail = false;
      notifyListeners();
      return;
    }

    try {
      final data = await _apiService.getPatientById(patientId);

      // Log do JSON cru (limitado a 500 chars para debug)
      if (kDebugMode) {
        final jsonStr = data.toString();
        debugPrint('[PATIENT_DETAILS] JSON recebido (${jsonStr.length} chars):');
        debugPrint(jsonStr.length > 500 ? '${jsonStr.substring(0, 500)}...' : jsonStr);
      }

      // Parsing com try-catch específico para identificar erros de parsing
      try {
        _selectedPatient = PatientDetail.fromJson(data);
      } catch (parseError, parseStack) {
        debugPrint('[PATIENT_DETAILS] PARSE ERROR: $parseError');
        debugPrint('[PATIENT_DETAILS] JSON keys: ${data.keys.toList()}');
        final jsonPreview = data.toString();
        debugPrint('[PATIENT_DETAILS] JSON preview: ${jsonPreview.length > 500 ? jsonPreview.substring(0, 500) : jsonPreview}');
        debugPrintStack(stackTrace: parseStack, maxFrames: 8);
        _error = 'Erro ao processar dados do paciente: ${parseError.runtimeType}';
        _isLoadingDetail = false;
        notifyListeners();
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '[PatientsProvider] Carregado paciente: ${_selectedPatient?.name}',
        );
        debugPrint('[PatientsProvider] ID: ${_selectedPatient?.id}');
        debugPrint('[PatientsProvider] D+ ${_selectedPatient?.dayPostOp}');
        debugPrint(
          '[PatientsProvider] Alergias: ${_selectedPatient?.allergies.length ?? 0}',
        );
        debugPrint(
          '[PatientsProvider] Notas: ${_selectedPatient?.medicalNotes.length ?? 0}',
        );
      }
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[PATIENT_DETAILS] DioException type=${e.type}');
      debugPrint('[PATIENT_DETAILS] DioException status=${e.response?.statusCode}');
      debugPrint('[PATIENT_DETAILS] DioException message=$_error');
    } catch (e, stackTrace) {
      // CRÍTICO: Log detalhado do erro real
      debugPrint('[PATIENT_DETAILS] ERROR type=${e.runtimeType}');
      debugPrint('[PATIENT_DETAILS] ERROR message=$e');
      debugPrint('[PATIENT_DETAILS] STACK TRACE:');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 10);

      // Mapear erro específico para mensagem amigável
      if (e is TypeError) {
        _error = 'Erro ao processar dados do paciente (tipo inválido)';
      } else if (e is FormatException) {
        _error = 'Erro ao processar resposta do servidor (formato inválido)';
      } else {
        _error = 'Erro inesperado ao carregar detalhes do paciente';
      }
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Limpa paciente selecionado
  void clearSelectedPatient() {
    _selectedPatient = null;
    notifyListeners();
  }

  /// Limpa erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ==================== ALERGIAS ====================

  /// Adiciona uma alergia ao paciente
  Future<bool> addAllergy(
    String patientId, {
    required String name,
    String? severity,
    String? notes,
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.addPatientAllergy(
        patientId,
        name: name,
        severity: severity,
        notes: notes,
      );

      // Atualiza a lista local se o paciente está carregado
      if (_selectedPatient != null && _selectedPatient!.id == patientId) {
        final newAllergy = PatientAllergy.fromJson(result);
        final updatedAllergies = [newAllergy, ..._selectedPatient!.allergies];
        _selectedPatient = PatientDetail(
          id: _selectedPatient!.id,
          name: _selectedPatient!.name,
          email: _selectedPatient!.email,
          phone: _selectedPatient!.phone,
          birthDate: _selectedPatient!.birthDate,
          cpf: _selectedPatient!.cpf,
          address: _selectedPatient!.address,
          surgeryType: _selectedPatient!.surgeryType,
          surgeryDate: _selectedPatient!.surgeryDate,
          surgeon: _selectedPatient!.surgeon,
          dayPostOp: _selectedPatient!.dayPostOp,
          weekPostOp: _selectedPatient!.weekPostOp,
          adherenceRate: _selectedPatient!.adherenceRate,
          bloodType: _selectedPatient!.bloodType,
          weightKg: _selectedPatient!.weightKg,
          heightCm: _selectedPatient!.heightCm,
          emergencyContact: _selectedPatient!.emergencyContact,
          emergencyPhone: _selectedPatient!.emergencyPhone,
          allergies: updatedAllergies,
          medicalNotes: _selectedPatient!.medicalNotes,
          upcomingAppointments: _selectedPatient!.upcomingAppointments,
          pastAppointments: _selectedPatient!.pastAppointments,
          recentAlerts: _selectedPatient!.recentAlerts,
        );
      }

      debugPrint('[PatientsProvider] Alergia adicionada: $name');
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[PatientsProvider] Erro ao adicionar alergia: $_error');
      return false;
    } catch (e) {
      _error = 'Erro ao adicionar alergia';
      debugPrint('[PatientsProvider] Erro: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Remove uma alergia do paciente
  Future<bool> removeAllergy(String patientId, String allergyId) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.removePatientAllergy(patientId, allergyId);

      // Atualiza a lista local se o paciente está carregado
      if (_selectedPatient != null && _selectedPatient!.id == patientId) {
        final updatedAllergies = _selectedPatient!.allergies
            .where((a) => a.id != allergyId)
            .toList();
        _selectedPatient = PatientDetail(
          id: _selectedPatient!.id,
          name: _selectedPatient!.name,
          email: _selectedPatient!.email,
          phone: _selectedPatient!.phone,
          birthDate: _selectedPatient!.birthDate,
          cpf: _selectedPatient!.cpf,
          address: _selectedPatient!.address,
          surgeryType: _selectedPatient!.surgeryType,
          surgeryDate: _selectedPatient!.surgeryDate,
          surgeon: _selectedPatient!.surgeon,
          dayPostOp: _selectedPatient!.dayPostOp,
          weekPostOp: _selectedPatient!.weekPostOp,
          adherenceRate: _selectedPatient!.adherenceRate,
          bloodType: _selectedPatient!.bloodType,
          weightKg: _selectedPatient!.weightKg,
          heightCm: _selectedPatient!.heightCm,
          emergencyContact: _selectedPatient!.emergencyContact,
          emergencyPhone: _selectedPatient!.emergencyPhone,
          allergies: updatedAllergies,
          medicalNotes: _selectedPatient!.medicalNotes,
          upcomingAppointments: _selectedPatient!.upcomingAppointments,
          pastAppointments: _selectedPatient!.pastAppointments,
          recentAlerts: _selectedPatient!.recentAlerts,
        );
      }

      debugPrint('[PatientsProvider] Alergia removida: $allergyId');
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[PatientsProvider] Erro ao remover alergia: $_error');
      return false;
    } catch (e) {
      _error = 'Erro ao remover alergia';
      debugPrint('[PatientsProvider] Erro: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // ==================== NOTAS MÉDICAS ====================

  /// Adiciona uma nota médica ao paciente
  Future<bool> addMedicalNote(
    String patientId, {
    required String content,
    String? author,
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.addPatientMedicalNote(
        patientId,
        content: content,
        author: author,
      );

      // Atualiza a lista local se o paciente está carregado
      if (_selectedPatient != null && _selectedPatient!.id == patientId) {
        final newNote = MedicalNote.fromJson(result);
        final updatedNotes = [newNote, ..._selectedPatient!.medicalNotes];
        _selectedPatient = PatientDetail(
          id: _selectedPatient!.id,
          name: _selectedPatient!.name,
          email: _selectedPatient!.email,
          phone: _selectedPatient!.phone,
          birthDate: _selectedPatient!.birthDate,
          cpf: _selectedPatient!.cpf,
          address: _selectedPatient!.address,
          surgeryType: _selectedPatient!.surgeryType,
          surgeryDate: _selectedPatient!.surgeryDate,
          surgeon: _selectedPatient!.surgeon,
          dayPostOp: _selectedPatient!.dayPostOp,
          weekPostOp: _selectedPatient!.weekPostOp,
          adherenceRate: _selectedPatient!.adherenceRate,
          bloodType: _selectedPatient!.bloodType,
          weightKg: _selectedPatient!.weightKg,
          heightCm: _selectedPatient!.heightCm,
          emergencyContact: _selectedPatient!.emergencyContact,
          emergencyPhone: _selectedPatient!.emergencyPhone,
          allergies: _selectedPatient!.allergies,
          medicalNotes: updatedNotes,
          upcomingAppointments: _selectedPatient!.upcomingAppointments,
          pastAppointments: _selectedPatient!.pastAppointments,
          recentAlerts: _selectedPatient!.recentAlerts,
        );
      }

      debugPrint('[PatientsProvider] Nota médica adicionada');
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[PatientsProvider] Erro ao adicionar nota: $_error');
      return false;
    } catch (e) {
      _error = 'Erro ao adicionar nota médica';
      debugPrint('[PatientsProvider] Erro: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Remove uma nota médica do paciente
  Future<bool> removeMedicalNote(String patientId, String noteId) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.removePatientMedicalNote(patientId, noteId);

      // Atualiza a lista local se o paciente está carregado
      if (_selectedPatient != null && _selectedPatient!.id == patientId) {
        final updatedNotes = _selectedPatient!.medicalNotes
            .where((n) => n.id != noteId)
            .toList();
        _selectedPatient = PatientDetail(
          id: _selectedPatient!.id,
          name: _selectedPatient!.name,
          email: _selectedPatient!.email,
          phone: _selectedPatient!.phone,
          birthDate: _selectedPatient!.birthDate,
          cpf: _selectedPatient!.cpf,
          address: _selectedPatient!.address,
          surgeryType: _selectedPatient!.surgeryType,
          surgeryDate: _selectedPatient!.surgeryDate,
          surgeon: _selectedPatient!.surgeon,
          dayPostOp: _selectedPatient!.dayPostOp,
          weekPostOp: _selectedPatient!.weekPostOp,
          adherenceRate: _selectedPatient!.adherenceRate,
          bloodType: _selectedPatient!.bloodType,
          weightKg: _selectedPatient!.weightKg,
          heightCm: _selectedPatient!.heightCm,
          emergencyContact: _selectedPatient!.emergencyContact,
          emergencyPhone: _selectedPatient!.emergencyPhone,
          allergies: _selectedPatient!.allergies,
          medicalNotes: updatedNotes,
          upcomingAppointments: _selectedPatient!.upcomingAppointments,
          pastAppointments: _selectedPatient!.pastAppointments,
          recentAlerts: _selectedPatient!.recentAlerts,
        );
      }

      debugPrint('[PatientsProvider] Nota médica removida: $noteId');
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[PatientsProvider] Erro ao remover nota: $_error');
      return false;
    } catch (e) {
      _error = 'Erro ao remover nota médica';
      debugPrint('[PatientsProvider] Erro: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // ==================== HISTÓRICO ====================

  /// Carrega histórico do paciente
  Future<void> loadPatientHistory(
    String patientId, {
    bool refresh = false,
  }) async {
    if (refresh) {
      _historyPage = 1;
      _historyItems = [];
    }

    _isLoadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getPatientHistory(
        patientId,
        page: _historyPage,
        limit: 20,
      );

      final items =
          (data['items'] as List<dynamic>?)
              ?.map(
                (e) => PatientHistoryItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [];

      if (refresh || _historyPage == 1) {
        _historyItems = items;
      } else {
        _historyItems = [..._historyItems, ...items];
      }

      _historyTotal = data['total'] ?? 0;
      _historyTotalPages = data['totalPages'] ?? 1;

      debugPrint(
        '[PatientsProvider] Carregados ${items.length} itens de histórico',
      );
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[PatientsProvider] Erro ao carregar histórico: $_error');
    } catch (e) {
      _error = 'Erro ao carregar histórico';
      debugPrint('[PatientsProvider] Erro: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Carrega mais histórico (paginação)
  Future<void> loadMoreHistory(String patientId) async {
    if (_isLoadingHistory || !hasMoreHistory) return;

    _historyPage++;
    await loadPatientHistory(patientId);
  }

  // ==================== ATUALIZAÇÃO DO PACIENTE ====================

  /// Atualiza informações da cirurgia do paciente
  Future<bool> updateSurgeryInfo(
    String patientId, {
    String? surgeryType,
    DateTime? surgeryDate,
    String? surgeon,
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (surgeryType != null) data['surgeryType'] = surgeryType;
      if (surgeryDate != null) data['surgeryDate'] = surgeryDate.toIso8601String();
      if (surgeon != null) data['surgeon'] = surgeon;

      await _apiService.updatePatient(patientId, data);

      // Atualiza a lista local se o paciente está carregado
      if (_selectedPatient != null && _selectedPatient!.id == patientId) {
        final surgeryDateStr = surgeryDate?.toIso8601String() ?? _selectedPatient!.surgeryDate;
        _selectedPatient = PatientDetail(
          id: _selectedPatient!.id,
          name: _selectedPatient!.name,
          email: _selectedPatient!.email,
          phone: _selectedPatient!.phone,
          birthDate: _selectedPatient!.birthDate,
          cpf: _selectedPatient!.cpf,
          address: _selectedPatient!.address,
          surgeryType: surgeryType ?? _selectedPatient!.surgeryType,
          surgeryDate: surgeryDateStr,
          surgeon: surgeon ?? _selectedPatient!.surgeon,
          dayPostOp: _selectedPatient!.dayPostOp,
          weekPostOp: _selectedPatient!.weekPostOp,
          adherenceRate: _selectedPatient!.adherenceRate,
          bloodType: _selectedPatient!.bloodType,
          weightKg: _selectedPatient!.weightKg,
          heightCm: _selectedPatient!.heightCm,
          emergencyContact: _selectedPatient!.emergencyContact,
          emergencyPhone: _selectedPatient!.emergencyPhone,
          allergies: _selectedPatient!.allergies,
          medicalNotes: _selectedPatient!.medicalNotes,
          upcomingAppointments: _selectedPatient!.upcomingAppointments,
          pastAppointments: _selectedPatient!.pastAppointments,
          recentAlerts: _selectedPatient!.recentAlerts,
        );
      }

      debugPrint('[PatientsProvider] Informações da cirurgia atualizadas');
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[PatientsProvider] Erro ao atualizar cirurgia: $_error');
      return false;
    } catch (e) {
      _error = 'Erro ao atualizar informações da cirurgia';
      debugPrint('[PatientsProvider] Erro: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // ==================== CONSULTAS ====================

  /// Cria uma consulta para o paciente
  Future<bool> createAppointment(
    String patientId, {
    required String title,
    required String date,
    required String time,
    required String type,
    String? description,
    String? location,
    String? notes,
  }) async {
    _isOperating = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createPatientAppointment(
        patientId,
        title: title,
        date: date,
        time: time,
        type: type,
        description: description,
        location: location,
        notes: notes,
      );

      // Recarrega os detalhes do paciente para atualizar as consultas
      if (_selectedPatient != null && _selectedPatient!.id == patientId) {
        await loadPatientDetail(patientId);
      }

      debugPrint('[PatientsProvider] Consulta criada: $title');
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[PatientsProvider] Erro ao criar consulta: $_error');
      return false;
    } catch (e) {
      _error = 'Erro ao criar consulta';
      debugPrint('[PatientsProvider] Erro: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }
}
