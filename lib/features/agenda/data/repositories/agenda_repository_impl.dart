import 'package:flutter/foundation.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/agenda_repository.dart';
import '../datasources/agenda_datasource.dart';
import '../datasources/agenda_api_datasource.dart';
import '../datasources/agenda_mock_datasource.dart';

/// Resultado do carregamento com informações sobre features disponíveis
class AgendaLoadResult {
  final List<Appointment> appointments;
  final List<ExternalEvent> externalEvents;
  final bool externalEventsAvailable;
  final String? warningMessage;

  AgendaLoadResult({
    required this.appointments,
    required this.externalEvents,
    this.externalEventsAvailable = true,
    this.warningMessage,
  });
}

/// Implementação do AgendaRepository com fallback para mock
class AgendaRepositoryImpl implements AgendaRepository {
  final AgendaDatasource _apiDatasource;
  final AgendaDatasource _mockDatasource;
  bool _useMock = false;
  bool _externalEventsAvailable = true;
  String? _lastWarning;

  AgendaRepositoryImpl({
    AgendaDatasource? apiDatasource,
    AgendaDatasource? mockDatasource,
  })  : _apiDatasource = apiDatasource ?? AgendaApiDatasource(),
        _mockDatasource = mockDatasource ?? AgendaMockDatasource();

  AgendaDatasource get _datasource => _useMock ? _mockDatasource : _apiDatasource;

  /// Verifica se external events está disponível
  bool get isExternalEventsAvailable => _externalEventsAvailable;

  /// Último aviso (feature indisponível, etc)
  String? get lastWarning => _lastWarning;

  /// Limpa o aviso
  void clearWarning() => _lastWarning = null;

  void _log(String message) {
    if (kDebugMode) {
      print('[AgendaRepository] $message');
    }
  }

  Future<T> _executeWithFallback<T>(Future<T> Function() operation) async {
    if (_useMock) {
      return operation();
    }

    try {
      return await operation();
    } on AgendaApiException catch (e) {
      _log('AgendaApiException: ${e.message}');
      if (e.errorType == 'network' || e.errorType == 'timeout') {
        _log('Switching to mock datasource');
        _useMock = true;
        return operation();
      }
      rethrow;
    } catch (e) {
      _log('Unknown error: $e, switching to mock');
      _useMock = true;
      return operation();
    }
  }

  @override
  Future<List<AgendaItem>> getEventsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Carrega appointments (obrigatório)
    final appointments = await getAppointments();

    // Carrega external events (opcional - não falha se indisponível)
    final externalEvents = await _getExternalEventsSafe();

    final items = <AgendaItem>[];

    for (final apt in appointments) {
      if (_isDateInRange(apt.date, startDate, endDate)) {
        items.add(AppointmentItem(apt));
      }
    }

    for (final evt in externalEvents) {
      if (_isDateInRange(evt.date, startDate, endDate)) {
        items.add(ExternalEventItem(evt));
      }
    }

    items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return items;
  }

  /// Busca external events de forma segura (não lança exceção)
  Future<List<ExternalEvent>> _getExternalEventsSafe() async {
    try {
      final models = await _datasource.getExternalEvents();
      _externalEventsAvailable = true;
      return models.map((m) => m.toEntity()).toList();
    } on AgendaApiException catch (e) {
      if (e.statusCode == 404 || e.errorType == 'feature_unavailable') {
        _log('External events não disponível: ${e.message}');
        _externalEventsAvailable = false;
        _lastWarning = 'Compromissos externos indisponíveis no momento.';
        return [];
      }
      // Outros erros também retornam lista vazia, mas sem mudar flag
      _log('Erro ao carregar external events: ${e.message}');
      return [];
    } catch (e) {
      _log('Erro inesperado em external events: $e');
      return [];
    }
  }

  bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);

    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  @override
  Future<List<Appointment>> getAppointments({AppointmentStatus? status}) async {
    return _executeWithFallback(() async {
      final models = await _datasource.getAppointments(
        status: status?.apiValue,
      );
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<List<Appointment>> getUpcomingAppointments({int limit = 5}) async {
    return _executeWithFallback(() async {
      final models = await _datasource.getUpcomingAppointments(limit: limit);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    return _executeWithFallback(() async {
      final model = await _datasource.getAppointmentById(id);
      return model?.toEntity();
    });
  }

  @override
  Future<Appointment> createAppointment({
    required String title,
    required DateTime date,
    required String time,
    required String location,
    required AppointmentType type,
    String? notes,
  }) async {
    return _executeWithFallback(() async {
      final model = await _datasource.createAppointment(
        title: title,
        date: date,
        time: time,
        location: location,
        type: type,
        notes: notes,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Appointment> updateAppointmentStatus(
    String id,
    AppointmentStatus status,
  ) async {
    return _executeWithFallback(() async {
      final model = await _datasource.updateAppointmentStatus(id, status);
      return model.toEntity();
    });
  }

  @override
  Future<Appointment> confirmAppointment(String id) async {
    return _executeWithFallback(() async {
      final model = await _datasource.confirmAppointment(id);
      return model.toEntity();
    });
  }

  @override
  Future<Appointment> cancelAppointment(String id) async {
    return _executeWithFallback(() async {
      final model = await _datasource.cancelAppointment(id);
      return model.toEntity();
    });
  }

  @override
  Future<List<ExternalEvent>> getExternalEvents() async {
    // Usa a versão segura que não lança exceção
    return _getExternalEventsSafe();
  }

  @override
  Future<ExternalEvent?> getExternalEventById(String id) async {
    if (!_externalEventsAvailable) {
      return null;
    }

    try {
      final model = await _datasource.getExternalEventById(id);
      return model?.toEntity();
    } on AgendaApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<ExternalEvent> createExternalEvent({
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  }) async {
    if (!_externalEventsAvailable) {
      throw AgendaApiException(
        message: 'Eventos externos não disponíveis neste momento.',
        statusCode: 404,
        errorType: 'feature_unavailable',
      );
    }

    return _executeWithFallback(() async {
      final model = await _datasource.createExternalEvent(
        title: title,
        date: date,
        time: time,
        location: location,
        notes: notes,
      );
      return model.toEntity();
    });
  }

  @override
  Future<ExternalEvent> updateExternalEvent({
    required String id,
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  }) async {
    if (!_externalEventsAvailable) {
      throw AgendaApiException(
        message: 'Eventos externos não disponíveis neste momento.',
        statusCode: 404,
        errorType: 'feature_unavailable',
      );
    }

    return _executeWithFallback(() async {
      final model = await _datasource.updateExternalEvent(
        id: id,
        title: title,
        date: date,
        time: time,
        location: location,
        notes: notes,
      );
      return model.toEntity();
    });
  }

  @override
  Future<void> deleteExternalEvent(String id) async {
    if (!_externalEventsAvailable) {
      throw AgendaApiException(
        message: 'Eventos externos não disponíveis neste momento.',
        statusCode: 404,
        errorType: 'feature_unavailable',
      );
    }

    return _executeWithFallback(() async {
      await _datasource.deleteExternalEvent(id);
    });
  }
}
