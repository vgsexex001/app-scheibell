import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/api_service.dart';
import '../models/calendar_appointment.dart';

/// Provider para gerenciar estado do calendário admin
class CalendarProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CalendarAppointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'ALL';

  // Getters
  List<CalendarAppointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get currentMonth => _currentMonth;
  DateTime get selectedDate => _selectedDate;
  String get statusFilter => _statusFilter;

  // Contadores
  int get totalCount => _appointments.length;
  int get confirmedCount => _appointments.where((a) => a.status == 'CONFIRMED').length;
  int get pendingCount => _appointments.where((a) => a.status == 'PENDING').length;
  int get completedCount => _appointments.where((a) => a.status == 'COMPLETED').length;

  /// Retorna agendamentos filtrados para a data selecionada
  List<CalendarAppointment> get appointmentsForSelectedDate {
    var filtered = _appointments.where((a) =>
      a.date.year == _selectedDate.year &&
      a.date.month == _selectedDate.month &&
      a.date.day == _selectedDate.day
    ).toList();

    if (_statusFilter != 'ALL') {
      filtered = filtered.where((a) => a.status == _statusFilter).toList();
    }

    filtered.sort((a, b) => a.time.compareTo(b.time));
    return filtered;
  }

  /// Retorna status dos agendamentos para um dia específico
  List<String> getStatusesForDay(DateTime day) {
    return _appointments
      .where((a) => a.date.year == day.year && a.date.month == day.month && a.date.day == day.day)
      .map((a) => a.status)
      .toSet()
      .toList();
  }

  /// Define o mês atual e carrega os agendamentos
  void setCurrentMonth(DateTime month) {
    _currentMonth = month;
    loadMonthAppointments();
  }

  /// Define a data selecionada
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Define o filtro de status
  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  /// Carrega agendamentos do mês atual
  Future<void> loadMonthAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[ADMIN_CAL] Loading appointments for ${_currentMonth.month}/${_currentMonth.year}');
      final data = await _apiService.getAdminCalendar(
        month: _currentMonth.month,
        year: _currentMonth.year,
      );
      final response = CalendarResponse.fromJson(data);
      _appointments = response.items;
      debugPrint('[ADMIN_CAL] Loaded ${_appointments.length} appointments from API');
    } catch (e) {
      debugPrint('[ADMIN_CAL] Error loading appointments: $e');
      _error = e.toString();
      _appointments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Atualiza um agendamento
  Future<bool> updateAppointment(
    String id, {
    String? status,
    String? notes,
    String? consultationType,
  }) async {
    try {
      debugPrint('[ADMIN_CAL] Updating appointment $id');
      await _apiService.updateAdminAppointment(
        id,
        status: status,
        notes: notes,
        type: consultationType,
      );
      // Recarrega os agendamentos para refletir a mudança
      await loadMonthAppointments();
      return true;
    } catch (e) {
      debugPrint('[ADMIN_CAL] Error updating appointment: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cancela um agendamento
  Future<bool> cancelAppointment(String id, {String? reason}) async {
    try {
      debugPrint('[ADMIN_CAL] Cancelling appointment $id');
      await _apiService.cancelAdminAppointment(id, reason: reason);
      // Recarrega os agendamentos para refletir a mudança
      await loadMonthAppointments();
      return true;
    } catch (e) {
      debugPrint('[ADMIN_CAL] Error cancelling appointment: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Limpa o erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Cria um novo agendamento
  Future<bool> createAppointment({
    required String patientId,
    required String title,
    required DateTime date,
    required String time,
    required String type,
    String? status,
    String? location,
    String? notes,
    String? description,
  }) async {
    try {
      debugPrint('[ADMIN_CREATE_APPT] Creating for patient=$patientId');
      await _apiService.createAdminAppointment(
        patientId: patientId,
        title: title,
        date: date.toIso8601String().split('T')[0],
        time: time,
        type: type,
        status: status,
        location: location,
        notes: notes,
        description: description,
      );
      // Recarrega os agendamentos para refletir a mudança
      await loadMonthAppointments();
      debugPrint('[ADMIN_CREATE_APPT] success');
      return true;
    } catch (e) {
      debugPrint('[ADMIN_CREATE_APPT] error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Exporta agendamentos do mês atual em CSV
  Future<String?> exportAppointments() async {
    try {
      final from = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final to = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

      debugPrint('[ADMIN_EXPORT] Exporting ${from.toIso8601String()} to ${to.toIso8601String()}');

      final bytes = await _apiService.exportAdminAppointments(
        from: from.toIso8601String().split('T')[0],
        to: to.toIso8601String().split('T')[0],
        status: _statusFilter != 'ALL' ? _statusFilter : null,
      );

      // Salvar arquivo
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'agendamentos_${from.month}_${from.year}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      debugPrint('[ADMIN_EXPORT] rows=${bytes.length} bytes saved to ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[ADMIN_EXPORT] error: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
