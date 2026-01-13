import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../domain/entities/appointment.dart';
import '../data/models/appointment_model.dart';

/// Provider para gerenciar agendamentos do paciente
/// Usa o ApiService existente para comunicação com o backend
class AppointmentProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Appointment> _upcomingAppointments = [];
  bool _isLoading = false;
  String? _error;

  AppointmentProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Getters
  List<Appointment> get upcomingAppointments => _upcomingAppointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _upcomingAppointments.isEmpty;

  /// Carrega próximos agendamentos do paciente
  Future<void> loadUpcomingAppointments({int limit = 5}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getUpcomingAppointments(limit: limit);

      _upcomingAppointments = response.map((json) {
        return AppointmentModel.fromJson(json as Map<String, dynamic>).toEntity();
      }).toList();

      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar agendamentos: ${e.toString()}';
      debugPrint('[AppointmentProvider] Erro: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria um novo agendamento
  Future<bool> createAppointment({
    required String title,
    required DateTime date,
    required String time,
    required AppointmentType type,
    String? location,
    String? description,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Formata a data para ISO string (YYYY-MM-DD)
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // DEBUG: Log de tudo que está sendo enviado
      debugPrint('========================================');
      debugPrint('CRIANDO AGENDAMENTO - DEBUG');
      debugPrint('========================================');
      debugPrint('title: $title');
      debugPrint('date (DateTime): $date');
      debugPrint('date (String ISO): $dateStr');
      debugPrint('time: $time');
      debugPrint('type (enum): $type');
      debugPrint('type (apiValue): ${type.apiValue}');
      debugPrint('location: $location');
      debugPrint('description: $description');
      debugPrint('notes: $notes');
      debugPrint('========================================');

      await _apiService.createAppointment(
        title: title,
        date: dateStr,
        time: time,
        type: type.apiValue,
        location: location,
        description: description,
        notes: notes,
      );

      // Recarrega a lista após criar
      await loadUpcomingAppointments();

      return true;
    } catch (e) {
      _error = 'Erro ao criar agendamento: ${e.toString()}';
      debugPrint('[AppointmentProvider] Erro ao criar: $_error');
      notifyListeners();
      return false;
    }
  }

  /// Cancela um agendamento
  Future<bool> cancelAppointment(String id) async {
    try {
      await _apiService.cancelAppointment(id);

      // Remove da lista local
      _upcomingAppointments.removeWhere((a) => a.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Erro ao cancelar: ${e.toString()}';
      debugPrint('[AppointmentProvider] Erro ao cancelar: $_error');
      notifyListeners();
      return false;
    }
  }

  /// Confirma um agendamento
  Future<bool> confirmAppointment(String id) async {
    try {
      await _apiService.confirmAppointment(id);

      // Atualiza status local
      final index = _upcomingAppointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _upcomingAppointments[index] = _upcomingAppointments[index].copyWith(
          status: AppointmentStatus.confirmed,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Erro ao confirmar: ${e.toString()}';
      debugPrint('[AppointmentProvider] Erro ao confirmar: $_error');
      notifyListeners();
      return false;
    }
  }

  /// Atualiza a lista de agendamentos (refresh)
  Future<void> refresh() async {
    await loadUpcomingAppointments();
  }

  /// Limpa erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Limpa todos os dados (logout)
  void clear() {
    _upcomingAppointments = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
