import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/models.dart';

class ClinicDashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estado
  DashboardSummary? _summary;
  List<PendingAppointment> _pendingAppointments = [];
  List<RecoveryPatient> _recoveryPatients = [];
  List<ClinicAlert> _alerts = [];

  // Paginação
  int _pendingPage = 1;
  int _pendingTotal = 0;
  int _recoveryPage = 1;
  int _recoveryTotal = 0;
  int _alertsPage = 1;
  int _alertsTotal = 0;

  // Estado de carregamento
  bool _isLoadingSummary = false;
  bool _isLoadingPending = false;
  bool _isLoadingRecovery = false;
  bool _isLoadingAlerts = false;
  bool _isApproving = false;
  bool _isRejecting = false;

  // Erros
  String? _error;

  // Getters
  DashboardSummary? get summary => _summary;
  List<PendingAppointment> get pendingAppointments => _pendingAppointments;
  List<RecoveryPatient> get recoveryPatients => _recoveryPatients;
  List<ClinicAlert> get alerts => _alerts;

  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingPending => _isLoadingPending;
  bool get isLoadingRecovery => _isLoadingRecovery;
  bool get isLoadingAlerts => _isLoadingAlerts;
  bool get isApproving => _isApproving;
  bool get isRejecting => _isRejecting;
  bool get isLoading =>
      _isLoadingSummary || _isLoadingPending || _isLoadingRecovery;

  int get pendingTotal => _pendingTotal;
  int get recoveryTotal => _recoveryTotal;
  int get alertsTotal => _alertsTotal;

  String? get error => _error;

  /// Carrega todos os dados do dashboard
  Future<void> loadDashboard() async {
    _error = null;
    notifyListeners();

    await Future.wait([
      loadSummary(),
      loadPendingAppointments(),
      loadRecoveryPatients(),
      loadAlerts(),
    ]);
  }

  /// Carrega o resumo (indicadores)
  Future<void> loadSummary() async {
    _isLoadingSummary = true;
    notifyListeners();

    try {
      final data = await _apiService.getAdminDashboardSummary();
      _summary = DashboardSummary.fromJson(data);
      _error = null;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[ClinicDashboardProvider] Erro ao carregar summary: $_error');
    } catch (e) {
      _error = 'Erro ao carregar indicadores';
      debugPrint('[ClinicDashboardProvider] Erro inesperado: $e');
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  /// Carrega consultas pendentes de aprovação
  Future<void> loadPendingAppointments({int page = 1, int limit = 10}) async {
    _isLoadingPending = true;
    notifyListeners();

    try {
      final data = await _apiService.getAdminPendingAppointments(
        page: page,
        limit: limit,
      );
      final response = PendingAppointmentsResponse.fromJson(data);
      _pendingAppointments = response.items;
      _pendingPage = response.page;
      _pendingTotal = response.total;
      _error = null;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint(
          '[ClinicDashboardProvider] Erro ao carregar pendentes: $_error');
    } catch (e) {
      _error = 'Erro ao carregar consultas pendentes';
      debugPrint('[ClinicDashboardProvider] Erro inesperado: $e');
    } finally {
      _isLoadingPending = false;
      notifyListeners();
    }
  }

  /// Aprova uma consulta
  Future<bool> approveAppointment(String appointmentId, {String? notes}) async {
    _isApproving = true;
    notifyListeners();

    try {
      await _apiService.approveAppointment(appointmentId, notes: notes);

      // Remover da lista local
      _pendingAppointments.removeWhere((a) => a.id == appointmentId);
      _pendingTotal = (_pendingTotal > 0) ? _pendingTotal - 1 : 0;

      // Atualizar summary
      if (_summary != null) {
        _summary = DashboardSummary(
          consultationsToday: _summary!.consultationsToday + 1,
          pendingApprovals:
              (_summary!.pendingApprovals > 0) ? _summary!.pendingApprovals - 1 : 0,
          activeAlerts: _summary!.activeAlerts,
          adherenceRate: _summary!.adherenceRate,
        );
      }

      _error = null;
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[ClinicDashboardProvider] Erro ao aprovar: $_error');
      return false;
    } catch (e) {
      _error = 'Erro ao aprovar consulta';
      debugPrint('[ClinicDashboardProvider] Erro inesperado: $e');
      return false;
    } finally {
      _isApproving = false;
      notifyListeners();
    }
  }

  /// Rejeita uma consulta
  Future<bool> rejectAppointment(String appointmentId,
      {String? reason}) async {
    _isRejecting = true;
    notifyListeners();

    try {
      await _apiService.rejectAppointment(appointmentId, reason: reason);

      // Remover da lista local
      _pendingAppointments.removeWhere((a) => a.id == appointmentId);
      _pendingTotal = (_pendingTotal > 0) ? _pendingTotal - 1 : 0;

      // Atualizar summary
      if (_summary != null) {
        _summary = DashboardSummary(
          consultationsToday: _summary!.consultationsToday,
          pendingApprovals:
              (_summary!.pendingApprovals > 0) ? _summary!.pendingApprovals - 1 : 0,
          activeAlerts: _summary!.activeAlerts,
          adherenceRate: _summary!.adherenceRate,
        );
      }

      _error = null;
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[ClinicDashboardProvider] Erro ao rejeitar: $_error');
      return false;
    } catch (e) {
      _error = 'Erro ao rejeitar consulta';
      debugPrint('[ClinicDashboardProvider] Erro inesperado: $e');
      return false;
    } finally {
      _isRejecting = false;
      notifyListeners();
    }
  }

  /// Carrega pacientes em recuperação
  Future<void> loadRecoveryPatients({int page = 1, int limit = 10}) async {
    _isLoadingRecovery = true;
    notifyListeners();

    try {
      final data = await _apiService.getAdminRecoveryPatients(
        page: page,
        limit: limit,
      );
      final response = RecoveryPatientsResponse.fromJson(data);
      _recoveryPatients = response.items;
      _recoveryPage = response.page;
      _recoveryTotal = response.total;
      _error = null;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint(
          '[ClinicDashboardProvider] Erro ao carregar pacientes: $_error');
    } catch (e) {
      _error = 'Erro ao carregar pacientes em recuperação';
      debugPrint('[ClinicDashboardProvider] Erro inesperado: $e');
    } finally {
      _isLoadingRecovery = false;
      notifyListeners();
    }
  }

  /// Carrega alertas
  Future<void> loadAlerts({int page = 1, int limit = 10, String? status}) async {
    _isLoadingAlerts = true;
    notifyListeners();

    try {
      final data = await _apiService.getAdminAlerts(
        page: page,
        limit: limit,
        status: status,
      );
      final response = AlertsResponse.fromJson(data);
      _alerts = response.items;
      _alertsPage = response.page;
      _alertsTotal = response.total;
      _error = null;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[ClinicDashboardProvider] Erro ao carregar alertas: $_error');
    } catch (e) {
      _error = 'Erro ao carregar alertas';
      debugPrint('[ClinicDashboardProvider] Erro inesperado: $e');
    } finally {
      _isLoadingAlerts = false;
      notifyListeners();
    }
  }

  /// Resolve um alerta
  Future<bool> resolveAlert(String alertId) async {
    try {
      await _apiService.resolveAlert(alertId);

      // Atualizar lista local
      _alerts.removeWhere((a) => a.id == alertId);
      _alertsTotal = (_alertsTotal > 0) ? _alertsTotal - 1 : 0;

      // Atualizar summary
      if (_summary != null) {
        _summary = DashboardSummary(
          consultationsToday: _summary!.consultationsToday,
          pendingApprovals: _summary!.pendingApprovals,
          activeAlerts:
              (_summary!.activeAlerts > 0) ? _summary!.activeAlerts - 1 : 0,
          adherenceRate: _summary!.adherenceRate,
        );
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[ClinicDashboardProvider] Erro ao resolver alerta: $_error');
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erro ao resolver alerta';
      debugPrint('[ClinicDashboardProvider] Erro inesperado: $e');
      notifyListeners();
      return false;
    }
  }

  /// Dispensa um alerta
  Future<bool> dismissAlert(String alertId) async {
    try {
      await _apiService.dismissAlert(alertId);

      // Atualizar lista local
      _alerts.removeWhere((a) => a.id == alertId);
      _alertsTotal = (_alertsTotal > 0) ? _alertsTotal - 1 : 0;

      // Atualizar summary
      if (_summary != null) {
        _summary = DashboardSummary(
          consultationsToday: _summary!.consultationsToday,
          pendingApprovals: _summary!.pendingApprovals,
          activeAlerts:
              (_summary!.activeAlerts > 0) ? _summary!.activeAlerts - 1 : 0,
          adherenceRate: _summary!.adherenceRate,
        );
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      final apiError = _apiService.mapDioError(e);
      _error = apiError.message;
      debugPrint('[ClinicDashboardProvider] Erro ao dispensar alerta: $_error');
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erro ao dispensar alerta';
      debugPrint('[ClinicDashboardProvider] Erro inesperado: $e');
      notifyListeners();
      return false;
    }
  }

  /// Limpa os erros
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reseta o estado
  void reset() {
    _summary = null;
    _pendingAppointments = [];
    _recoveryPatients = [];
    _alerts = [];
    _pendingTotal = 0;
    _recoveryTotal = 0;
    _alertsTotal = 0;
    _error = null;
    notifyListeners();
  }
}
