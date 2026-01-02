import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/config/api_config.dart';
import '../models/appointment_model.dart';
import '../../domain/entities/appointment.dart';
import 'agenda_datasource.dart';

/// Exceção customizada para erros da API de agenda
class AgendaApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  AgendaApiException({
    required this.message,
    this.statusCode,
    this.errorType,
  });

  @override
  String toString() =>
      'AgendaApiException: $message (status: $statusCode, type: $errorType)';

  String get userFriendlyMessage {
    if (statusCode == 401 || statusCode == 403) {
      return 'Sessão expirada. Por favor, faça login novamente.';
    }
    if (statusCode == 404) {
      return 'Recurso não encontrado.';
    }
    if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
      return 'Serviço temporariamente indisponível. Tente novamente.';
    }
    if (errorType == 'network') {
      return 'Sem conexão com a internet. Verifique sua rede.';
    }
    return 'Ocorreu um erro. Por favor, tente novamente.';
  }

  /// Verifica se é um erro de feature não disponível (404 em endpoint opcional)
  bool get isFeatureUnavailable => statusCode == 404;
}

/// Implementação do datasource usando a API real
class AgendaApiDatasource implements AgendaDatasource {
  final ApiService _apiService;

  /// Flag para indicar se external-events está disponível no backend
  bool _externalEventsAvailable = true;

  AgendaApiDatasource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  void _log(String message) {
    if (kDebugMode) {
      print('[AgendaAPI] $message');
    }
  }

  @override
  Future<List<AppointmentModel>> getAppointments({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        ApiConfig.appointmentsEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data as List<dynamic>;
      return data
          .map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<AppointmentModel>> getUpcomingAppointments({int limit = 5}) async {
    try {
      final response = await _apiService.get(
        ApiConfig.appointmentsUpcomingEndpoint,
        queryParameters: {'limit': limit},
      );

      final data = response.data as List<dynamic>;
      return data
          .map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AppointmentModel?> getAppointmentById(String id) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.appointmentsEndpoint}/$id',
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<AppointmentModel> createAppointment({
    required String title,
    required DateTime date,
    required String time,
    required String location,
    required AppointmentType type,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.appointmentsEndpoint,
        data: {
          'title': title,
          'date': date.toIso8601String().split('T')[0],
          'time': time,
          'location': location,
          'type': type.apiValue,
          'description': notes,
        },
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AppointmentModel> updateAppointmentStatus(
    String id,
    AppointmentStatus status,
  ) async {
    try {
      final response = await _apiService.patch(
        '${ApiConfig.appointmentsEndpoint}/$id/status',
        data: {'status': status.apiValue},
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AppointmentModel> confirmAppointment(String id) async {
    try {
      final response = await _apiService.patch(
        '${ApiConfig.appointmentsEndpoint}/$id/confirm',
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AppointmentModel> cancelAppointment(String id) async {
    try {
      final response = await _apiService.patch(
        '${ApiConfig.appointmentsEndpoint}/$id/cancel',
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== EXTERNAL EVENTS (FEATURE OPCIONAL) ====================

  @override
  Future<List<ExternalEventModel>> getExternalEvents() async {
    // Se já sabemos que não está disponível, retorna lista vazia
    if (!_externalEventsAvailable) {
      _log('External events feature não disponível, retornando lista vazia');
      return [];
    }

    try {
      final response = await _apiService.get(ApiConfig.externalEventsEndpoint);
      final data = response.data as List<dynamic>;
      return data
          .map((item) => ExternalEventModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // Se 404, marcar feature como indisponível e retornar lista vazia
      if (e.response?.statusCode == 404) {
        _log('External events endpoint não existe (404), desabilitando feature');
        _externalEventsAvailable = false;
        return [];
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<ExternalEventModel?> getExternalEventById(String id) async {
    if (!_externalEventsAvailable) {
      return null;
    }

    try {
      final response = await _apiService.get(
        '${ApiConfig.externalEventsEndpoint}/$id',
      );
      return ExternalEventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<ExternalEventModel> createExternalEvent({
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  }) async {
    if (!_externalEventsAvailable) {
      throw AgendaApiException(
        message: 'Eventos externos não disponíveis',
        statusCode: 404,
        errorType: 'feature_unavailable',
      );
    }

    try {
      final response = await _apiService.post(
        ApiConfig.externalEventsEndpoint,
        data: {
          'title': title,
          'date': date.toIso8601String().split('T')[0],
          'time': time,
          'location': location,
          'notes': notes,
        },
      );
      return ExternalEventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _externalEventsAvailable = false;
        throw AgendaApiException(
          message: 'Eventos externos não disponíveis',
          statusCode: 404,
          errorType: 'feature_unavailable',
        );
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<ExternalEventModel> updateExternalEvent({
    required String id,
    required String title,
    required DateTime date,
    required String time,
    String? location,
    String? notes,
  }) async {
    if (!_externalEventsAvailable) {
      throw AgendaApiException(
        message: 'Eventos externos não disponíveis',
        statusCode: 404,
        errorType: 'feature_unavailable',
      );
    }

    try {
      final response = await _apiService.put(
        '${ApiConfig.externalEventsEndpoint}/$id',
        data: {
          'title': title,
          'date': date.toIso8601String().split('T')[0],
          'time': time,
          'location': location,
          'notes': notes,
        },
      );
      return ExternalEventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _externalEventsAvailable = false;
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteExternalEvent(String id) async {
    if (!_externalEventsAvailable) {
      throw AgendaApiException(
        message: 'Eventos externos não disponíveis',
        statusCode: 404,
        errorType: 'feature_unavailable',
      );
    }

    try {
      await _apiService.delete('${ApiConfig.externalEventsEndpoint}/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _externalEventsAvailable = false;
      }
      throw _handleDioError(e);
    }
  }

  /// Verifica se a feature de eventos externos está disponível
  bool get isExternalEventsAvailable => _externalEventsAvailable;

  /// Reseta o flag de disponibilidade (útil para retry)
  void resetExternalEventsAvailability() {
    _externalEventsAvailable = true;
  }

  AgendaApiException _handleDioError(DioException error) {
    _log('DioError: ${error.type} - ${error.message}');

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return AgendaApiException(
        message: 'Timeout na conexão',
        errorType: 'timeout',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return AgendaApiException(
        message: 'Erro de conexão com a internet',
        errorType: 'network',
      );
    }

    final statusCode = error.response?.statusCode;
    final errorData = error.response?.data;
    String errorMessage = 'Erro desconhecido';
    String? errorType;

    if (errorData is Map<String, dynamic>) {
      errorMessage = errorData['message'] as String? ?? errorMessage;
      errorType = errorData['error'] as String?;
    }

    return AgendaApiException(
      message: errorMessage,
      statusCode: statusCode,
      errorType: errorType,
    );
  }
}
