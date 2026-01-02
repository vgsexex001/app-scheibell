import 'package:flutter/foundation.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/agenda_repository.dart';
import '../../data/repositories/agenda_repository_impl.dart';
import '../../data/datasources/agenda_api_datasource.dart';

/// Estado da agenda
enum AgendaStatus {
  initial,
  loading,
  success,
  empty,
  error,
}

/// Controller da agenda usando ChangeNotifier (Provider)
class AgendaController extends ChangeNotifier {
  final AgendaRepositoryImpl _repository;

  AgendaController({AgendaRepository? repository})
      : _repository = (repository as AgendaRepositoryImpl?) ?? AgendaRepositoryImpl();

  // Estado
  AgendaStatus _status = AgendaStatus.initial;
  String? _errorMessage;
  String? _warningMessage;
  DateTime _selectedDate = DateTime.now();
  DateTime _visibleMonth = DateTime.now();
  List<AgendaItem> _allEvents = [];
  Map<DateTime, List<AgendaItem>> _eventsByDay = {};

  // Getters
  AgendaStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get warningMessage => _warningMessage;
  DateTime get selectedDate => _selectedDate;
  DateTime get visibleMonth => _visibleMonth;
  List<AgendaItem> get allEvents => _allEvents;
  Map<DateTime, List<AgendaItem>> get eventsByDay => _eventsByDay;

  bool get isLoading => _status == AgendaStatus.loading;
  bool get hasError => _status == AgendaStatus.error;
  bool get isEmpty => _status == AgendaStatus.empty;
  bool get hasData => _status == AgendaStatus.success;
  bool get hasWarning => _warningMessage != null;

  /// Verifica se eventos externos estão disponíveis
  bool get isExternalEventsAvailable => _repository.isExternalEventsAvailable;

  /// Eventos do dia selecionado
  List<AgendaItem> get eventsForSelectedDate {
    final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _eventsByDay[dateKey] ?? [];
  }

  /// Próximos eventos (máximo 5)
  List<AgendaItem> get upcomingEvents {
    final now = DateTime.now();
    return _allEvents
        .where((e) => e.dateTime.isAfter(now))
        .take(5)
        .toList();
  }

  /// Verifica se um dia tem eventos
  bool hasEventsOnDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _eventsByDay.containsKey(dateKey) && _eventsByDay[dateKey]!.isNotEmpty;
  }

  /// Quantidade de eventos em um dia
  int eventsCountOnDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _eventsByDay[dateKey]?.length ?? 0;
  }

  /// Seleciona uma data
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Navega para o mês anterior
  void previousMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    notifyListeners();
    loadEventsForMonth();
  }

  /// Navega para o próximo mês
  void nextMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    notifyListeners();
    loadEventsForMonth();
  }

  /// Vai para o mês atual
  void goToToday() {
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = now;
    notifyListeners();
    loadEventsForMonth();
  }

  /// Carrega eventos para o mês visível
  Future<void> loadEventsForMonth() async {
    _status = AgendaStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final startOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      final endOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

      final events = await _repository.getEventsInRange(startOfMonth, endOfMonth);

      _allEvents = events;
      _buildEventsByDay();

      // Verifica se há aviso do repository (ex: external events indisponível)
      _warningMessage = _repository.lastWarning;
      _repository.clearWarning();

      if (_allEvents.isEmpty) {
        _status = AgendaStatus.empty;
      } else {
        _status = AgendaStatus.success;
      }
    } on AgendaApiException catch (e) {
      _status = AgendaStatus.error;
      _errorMessage = e.userFriendlyMessage;
      if (kDebugMode) {
        print('[AgendaController] Error: ${e.toString()}');
      }
    } catch (e) {
      _status = AgendaStatus.error;
      _errorMessage = 'Erro ao carregar agendamentos. Tente novamente.';
      if (kDebugMode) {
        print('[AgendaController] Unexpected error: $e');
      }
    }

    notifyListeners();
  }

  /// Carrega todos os eventos
  Future<void> loadAllEvents() async {
    _status = AgendaStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final appointments = await _repository.getAppointments();
      final externalEvents = await _repository.getExternalEvents();

      _allEvents = [
        ...appointments.map((a) => AppointmentItem(a)),
        ...externalEvents.map((e) => ExternalEventItem(e)),
      ];

      _allEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _buildEventsByDay();

      // Verifica se há aviso do repository
      _warningMessage = _repository.lastWarning;
      _repository.clearWarning();

      if (_allEvents.isEmpty) {
        _status = AgendaStatus.empty;
      } else {
        _status = AgendaStatus.success;
      }
    } on AgendaApiException catch (e) {
      _status = AgendaStatus.error;
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _status = AgendaStatus.error;
      _errorMessage = 'Erro ao carregar agendamentos. Tente novamente.';
    }

    notifyListeners();
  }

  void _buildEventsByDay() {
    _eventsByDay = {};
    for (final event in _allEvents) {
      final dateKey = DateTime(event.date.year, event.date.month, event.date.day);
      if (!_eventsByDay.containsKey(dateKey)) {
        _eventsByDay[dateKey] = [];
      }
      _eventsByDay[dateKey]!.add(event);
    }
  }

  /// Confirma um agendamento
  Future<bool> confirmAppointment(String id) async {
    try {
      await _repository.confirmAppointment(id);
      await loadEventsForMonth();
      return true;
    } on AgendaApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao confirmar agendamento.';
      notifyListeners();
      return false;
    }
  }

  /// Cancela um agendamento
  Future<bool> cancelAppointment(String id) async {
    try {
      await _repository.cancelAppointment(id);
      await loadEventsForMonth();
      return true;
    } on AgendaApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao cancelar agendamento.';
      notifyListeners();
      return false;
    }
  }

  /// Cria um novo agendamento
  Future<Appointment?> createAppointment({
    required String title,
    required DateTime date,
    required String time,
    required String location,
    required AppointmentType type,
    String? notes,
  }) async {
    try {
      final appointment = await _repository.createAppointment(
        title: title,
        date: date,
        time: time,
        location: location,
        type: type,
        notes: notes,
      );
      await loadEventsForMonth();
      return appointment;
    } on AgendaApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Erro ao criar agendamento.';
      notifyListeners();
      return null;
    }
  }

  /// Cria um novo evento externo
  Future<ExternalEvent?> createExternalEvent({
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  }) async {
    // Verifica se a feature está disponível
    if (!isExternalEventsAvailable) {
      _errorMessage = 'Eventos externos não disponíveis neste momento.';
      notifyListeners();
      return null;
    }

    try {
      final event = await _repository.createExternalEvent(
        title: title,
        date: date,
        time: time,
        location: location,
        notes: notes,
      );
      await loadEventsForMonth();
      return event;
    } on AgendaApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Erro ao criar evento.';
      notifyListeners();
      return null;
    }
  }

  /// Atualiza um evento externo
  Future<ExternalEvent?> updateExternalEvent({
    required String id,
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  }) async {
    if (!isExternalEventsAvailable) {
      _errorMessage = 'Eventos externos não disponíveis neste momento.';
      notifyListeners();
      return null;
    }

    try {
      final event = await _repository.updateExternalEvent(
        id: id,
        title: title,
        date: date,
        time: time,
        location: location,
        notes: notes,
      );
      await loadEventsForMonth();
      return event;
    } on AgendaApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar evento.';
      notifyListeners();
      return null;
    }
  }

  /// Remove um evento externo
  Future<bool> deleteExternalEvent(String id) async {
    if (!isExternalEventsAvailable) {
      _errorMessage = 'Eventos externos não disponíveis neste momento.';
      notifyListeners();
      return false;
    }

    try {
      await _repository.deleteExternalEvent(id);
      await loadEventsForMonth();
      return true;
    } on AgendaApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao excluir evento.';
      notifyListeners();
      return false;
    }
  }

  /// Busca um agendamento pelo ID
  Future<Appointment?> getAppointmentById(String id) async {
    try {
      return await _repository.getAppointmentById(id);
    } on AgendaApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Erro ao buscar agendamento.';
      notifyListeners();
      return null;
    }
  }

  /// Busca um evento externo pelo ID
  Future<ExternalEvent?> getExternalEventById(String id) async {
    try {
      return await _repository.getExternalEventById(id);
    } on AgendaApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Erro ao buscar evento.';
      notifyListeners();
      return null;
    }
  }

  /// Limpa o erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpa o aviso
  void clearWarning() {
    _warningMessage = null;
    notifyListeners();
  }

  /// Recarrega os dados
  Future<void> refresh() async {
    await loadEventsForMonth();
  }
}
