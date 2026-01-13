import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'secure_storage_service.dart';

/// Tipos de erro de rede para mapeamento preciso
enum NetworkErrorType {
  noInternet,
  connectionTimeout,
  receiveTimeout,
  sendTimeout,
  serverError,
  clientError,
  unauthorized,
  notFound,
  conflict,
  badRequest,
  sslHandshake,
  dnsLookup,
  connectionRefused,
  unknown,
}

/// Exceção customizada com tipo de erro e mensagem amigável
class ApiException implements Exception {
  final NetworkErrorType type;
  final String message;
  final String? technicalDetails;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Mensagem amigável para exibir ao usuário
  String get userMessage => message;
}

/// Serviço centralizado para comunicação com a API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  String? _authToken;

  // Secure Storage para tokens
  final SecureStorageService _secureStorage = SecureStorageService();

  // Controle de refresh token
  bool _isRefreshing = false;
  final List<Completer<String>> _refreshQueue = [];

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
        sendTimeout: Duration(seconds: ApiConfig.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor para adicionar token, logging e auto-refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Carrega token do SecureStorage se não estiver em memória
          if (_authToken == null) {
            _authToken = await _secureStorage.getAccessToken();
          }

          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          // Log detalhado apenas em debug
          _logRequest(options);

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          return handler.next(response);
        },
        onError: (error, handler) async {
          _logError(error);

          // Se for 401 e não é uma requisição de refresh, tenta refresh
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/refresh') &&
              !error.requestOptions.path.contains('/auth/login')) {
            try {
              final newToken = await _handleTokenRefresh();
              if (newToken != null) {
                // Refaz a requisição original com o novo token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              }
            } catch (e) {
              // Refresh falhou - limpa tokens
              debugPrint('🔴 Refresh token failed: $e');
              await clearAllTokens();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Tenta fazer refresh do token com controle de concorrência
  Future<String?> _handleTokenRefresh() async {
    // Se já está fazendo refresh, aguarda na fila
    if (_isRefreshing) {
      final completer = Completer<String>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        return null;
      }

      debugPrint('🔄 Attempting token refresh...');

      // Faz a requisição de refresh (sem passar pelo interceptor normal)
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {}), // Sem Authorization header
      );

      final data = response.data;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;
      final expiresIn = data['expiresIn'] as int;

      // Salva novos tokens
      await _secureStorage.saveTokenPair(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresIn: expiresIn,
      );

      _authToken = newAccessToken;

      debugPrint('✅ Token refresh successful');

      // Notifica todos na fila
      for (final completer in _refreshQueue) {
        completer.complete(newAccessToken);
      }
      _refreshQueue.clear();

      return newAccessToken;
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');

      // Notifica erro para todos na fila
      for (final completer in _refreshQueue) {
        completer.completeError(e);
      }
      _refreshQueue.clear();

      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Log de request (apenas em debug)
  void _logRequest(RequestOptions options) {
    if (!kDebugMode) return;

    final uri = options.uri;
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 📤 REQUEST');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ Method: ${options.method}');
    debugPrint('║ URL: $uri');
    debugPrint('║ Base URL: ${options.baseUrl}');
    debugPrint('║ Path: ${options.path}');
    debugPrint('║ Connect Timeout: ${options.connectTimeout?.inSeconds}s');
    debugPrint('║ Receive Timeout: ${options.receiveTimeout?.inSeconds}s');
    debugPrint('║ Headers: ${_sanitizeHeaders(options.headers)}');
    if (options.data != null) {
      debugPrint('║ Body: ${_sanitizeBody(options.data)}');
    }
    debugPrint('╚══════════════════════════════════════════════════════════════');
  }

  /// Log de response (apenas em debug)
  void _logResponse(Response response) {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 📥 RESPONSE');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ Status: ${response.statusCode}');
    debugPrint('║ Path: ${response.requestOptions.path}');

    // Log adicional para validar dados reais
    final data = response.data;
    if (data is Map) {
      if (data['items'] != null && data['items'] is List) {
        final items = data['items'] as List;
        debugPrint('║ Items Count: ${items.length}');
        if (items.isNotEmpty) {
          final firstItem = items.first;
          if (firstItem is Map && firstItem['id'] != null) {
            debugPrint('║ Sample ID: ${firstItem['id']}');
          }
          if (firstItem is Map && firstItem['name'] != null) {
            debugPrint('║ Sample Name: ${firstItem['name']}');
          }
        }
      }
      if (data['total'] != null) {
        debugPrint('║ Total: ${data['total']}');
      }
    } else if (data is List) {
      debugPrint('║ Items Count: ${data.length}');
      if (data.isNotEmpty && data.first is Map) {
        final firstItem = data.first as Map;
        if (firstItem['id'] != null) {
          debugPrint('║ Sample ID: ${firstItem['id']}');
        }
      }
    }

    debugPrint('║ Data: ${_truncate(response.data.toString(), 500)}');
    debugPrint('╚══════════════════════════════════════════════════════════════');
  }

  /// Log de erro (apenas em debug)
  void _logError(DioException error) {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ ❌ ERROR');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ Type: ${error.type}');
    debugPrint('║ Path: ${error.requestOptions.path}');
    debugPrint('║ URL: ${error.requestOptions.uri}');
    debugPrint('║ Status Code: ${error.response?.statusCode ?? "N/A"}');
    debugPrint('║ Message: ${error.message}');
    if (error.error != null) {
      debugPrint('║ Inner Error: ${error.error.runtimeType} - ${error.error}');
    }
    if (error.response?.data != null) {
      debugPrint('║ Response Data: ${error.response?.data}');
    }
    debugPrint('╚══════════════════════════════════════════════════════════════');
  }

  /// Sanitiza headers para não vazar token completo
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      final auth = sanitized['Authorization'] as String;
      if (auth.length > 20) {
        sanitized['Authorization'] = '${auth.substring(0, 20)}...';
      }
    }
    return sanitized;
  }

  /// Sanitiza body para não vazar senha
  dynamic _sanitizeBody(dynamic data) {
    if (data is Map) {
      final sanitized = Map<String, dynamic>.from(data);
      if (sanitized.containsKey('password')) {
        sanitized['password'] = '***';
      }
      if (sanitized.containsKey('currentPassword')) {
        sanitized['currentPassword'] = '***';
      }
      if (sanitized.containsKey('newPassword')) {
        sanitized['newPassword'] = '***';
      }
      return sanitized;
    }
    return data;
  }

  /// Trunca strings longas
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Mapeia erros Dio para tipos específicos com mensagens amigáveis
  ApiException mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;

    // Erros de timeout
    if (e.type == DioExceptionType.connectionTimeout) {
      return ApiException(
        type: NetworkErrorType.connectionTimeout,
        message: 'Não foi possível conectar ao servidor. Verifique sua conexão.',
        technicalDetails: 'Connection timeout after ${e.requestOptions.connectTimeout?.inSeconds}s to ${e.requestOptions.uri}',
        originalError: e,
      );
    }

    if (e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        type: NetworkErrorType.receiveTimeout,
        message: 'O servidor demorou para responder. Tente novamente.',
        technicalDetails: 'Receive timeout after ${e.requestOptions.receiveTimeout?.inSeconds}s',
        originalError: e,
      );
    }

    if (e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        type: NetworkErrorType.sendTimeout,
        message: 'Falha ao enviar dados. Verifique sua conexão.',
        technicalDetails: 'Send timeout',
        originalError: e,
      );
    }

    // Erros de conexão
    if (e.type == DioExceptionType.connectionError) {
      final innerError = e.error;

      // Sem internet
      if (innerError is SocketException) {
        if (innerError.message.contains('Network is unreachable') ||
            innerError.message.contains('No address associated') ||
            innerError.osError?.errorCode == 101) {
          return ApiException(
            type: NetworkErrorType.noInternet,
            message: 'Sem conexão com a internet.',
            technicalDetails: 'SocketException: ${innerError.message}',
            originalError: e,
          );
        }

        // Conexão recusada (backend não está rodando)
        if (innerError.message.contains('Connection refused') ||
            innerError.osError?.errorCode == 111 ||
            innerError.osError?.errorCode == 10061) {
          return ApiException(
            type: NetworkErrorType.connectionRefused,
            message: 'Servidor indisponível. Verifique se o backend está rodando.',
            technicalDetails: 'Connection refused to ${e.requestOptions.uri}',
            originalError: e,
          );
        }
      }

      // Erro de SSL/TLS
      if (innerError is HandshakeException) {
        return ApiException(
          type: NetworkErrorType.sslHandshake,
          message: 'Erro de segurança na conexão.',
          technicalDetails: 'SSL Handshake failed: ${innerError.message}',
          originalError: e,
        );
      }

      // Erro genérico de conexão
      return ApiException(
        type: NetworkErrorType.connectionRefused,
        message: 'Não foi possível conectar ao servidor.',
        technicalDetails: 'Connection error: ${e.error}',
        originalError: e,
      );
    }

    // Erros de resposta HTTP
    if (e.type == DioExceptionType.badResponse) {
      switch (statusCode) {
        case 400:
          final data = e.response?.data;
          String message = 'Dados inválidos';
          if (data is Map && data['message'] != null) {
            message = data['message'] is List
                ? (data['message'] as List).first.toString()
                : data['message'].toString();
          }
          return ApiException(
            type: NetworkErrorType.badRequest,
            message: message,
            statusCode: statusCode,
            originalError: e,
          );

        case 401:
          return ApiException(
            type: NetworkErrorType.unauthorized,
            message: 'Credenciais inválidas ou sessão expirada.',
            statusCode: statusCode,
            originalError: e,
          );

        case 403:
          return ApiException(
            type: NetworkErrorType.unauthorized,
            message: 'Acesso negado.',
            statusCode: statusCode,
            originalError: e,
          );

        case 404:
          return ApiException(
            type: NetworkErrorType.notFound,
            message: 'Recurso não encontrado.',
            technicalDetails: 'Endpoint ${e.requestOptions.path} not found',
            statusCode: statusCode,
            originalError: e,
          );

        case 409:
          return ApiException(
            type: NetworkErrorType.conflict,
            message: 'Este registro já existe.',
            statusCode: statusCode,
            originalError: e,
          );

        case 500:
        case 502:
        case 503:
        case 504:
          return ApiException(
            type: NetworkErrorType.serverError,
            message: 'Erro no servidor. Tente novamente mais tarde.',
            statusCode: statusCode,
            originalError: e,
          );

        default:
          return ApiException(
            type: NetworkErrorType.unknown,
            message: 'Erro inesperado (código $statusCode).',
            statusCode: statusCode,
            originalError: e,
          );
      }
    }

    // Erro desconhecido
    return ApiException(
      type: NetworkErrorType.unknown,
      message: 'Erro de conexão. Tente novamente.',
      technicalDetails: 'Unknown error: ${e.type} - ${e.message}',
      originalError: e,
    );
  }

  /// Define o token de autenticação
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Remove o token de autenticação
  void clearAuthToken() {
    _authToken = null;
  }

  /// Carrega o token salvo (primeiro tenta SecureStorage, depois SharedPreferences para migração)
  Future<String?> loadSavedToken() async {
    // Primeiro tenta SecureStorage
    _authToken = await _secureStorage.getAccessToken();

    // Se não encontrou, tenta migrar do SharedPreferences antigo
    if (_authToken == null) {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString('auth_token');
      if (oldToken != null && oldToken.isNotEmpty) {
        // Migra para SecureStorage
        await _secureStorage.saveAccessToken(oldToken);
        // Remove do SharedPreferences antigo
        await prefs.remove('auth_token');
        _authToken = oldToken;
        debugPrint('🔄 Migrated token from SharedPreferences to SecureStorage');
      }
    }

    return _authToken;
  }

  /// Salva o par de tokens no SecureStorage
  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    String? userId,
    String? patientId,
  }) async {
    _authToken = accessToken;
    await _secureStorage.saveTokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      userId: userId,
      patientId: patientId,
    );
  }

  /// Salva apenas o access token (legado - para compatibilidade)
  Future<void> saveToken(String token) async {
    _authToken = token;
    await _secureStorage.saveAccessToken(token);
  }

  /// Remove todos os tokens salvos
  Future<void> removeToken() async {
    _authToken = null;
    await _secureStorage.clearAll();
    // Também limpa o SharedPreferences antigo por segurança
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Limpa todos os tokens (alias para removeToken)
  Future<void> clearAllTokens() async {
    await removeToken();
  }

  /// Verifica se o token está expirado
  Future<bool> isTokenExpired() async {
    return await _secureStorage.isTokenExpired();
  }

  /// Retorna o SecureStorageService para uso externo
  SecureStorageService get secureStorage => _secureStorage;

  /// Retorna o token atual em memória (pode ser null)
  String? get currentToken => _authToken;

  // ==================== MÉTODOS HTTP ====================

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.put(path, data: data, queryParameters: queryParameters);
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.patch(path, data: data, queryParameters: queryParameters);
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete(path, data: data, queryParameters: queryParameters);
  }

  // ==================== MÉTODOS DE AUTENTICAÇÃO ====================

  /// Login do usuário
  Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('[API] login() - URL: ${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
    try {
      final response = await post(
        ApiConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );
      debugPrint('[API] login() - Status: ${response.statusCode}');
      return response.data;
    } catch (e) {
      debugPrint('[API] login() - Erro: $e');
      rethrow;
    }
  }

  /// Registro de novo usuário
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? role,
    String? clinicId,
  }) async {
    final response = await post(
      ApiConfig.registerEndpoint,
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (role != null) 'role': role,
        if (clinicId != null) 'clinicId': clinicId,
      },
    );
    return response.data;
  }

  /// Busca perfil do usuário autenticado
  Future<Map<String, dynamic>> getProfile() async {
    final response = await get(ApiConfig.profileEndpoint);
    return response.data;
  }

  /// Valida se o token ainda é válido
  Future<Map<String, dynamic>> validateToken() async {
    final response = await get(ApiConfig.validateEndpoint);
    return response.data;
  }

  /// Atualiza o perfil do usuário
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? cpf,
    String? birthDate,
    String? surgeryDate,
    String? surgeryType,
  }) async {
    final response = await put(
      ApiConfig.profileEndpoint,
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (cpf != null) 'cpf': cpf,
        if (birthDate != null) 'birthDate': birthDate,
        if (surgeryDate != null) 'surgeryDate': surgeryDate,
        if (surgeryType != null) 'surgeryType': surgeryType,
      },
    );
    return response.data;
  }

  /// Altera a senha do usuário
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await post(
      ApiConfig.changePasswordEndpoint,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return response.data;
  }

  // ==================== MÉTODOS DE CONTEÚDO ====================

  /// Busca conteúdo da clínica por tipo (para staff/admin)
  Future<List<dynamic>> getClinicContent({
    required String type,
    String? category,
  }) async {
    final response = await get(
      ApiConfig.contentClinicEndpoint,
      queryParameters: {
        'type': type,
        if (category != null) 'category': category,
      },
    );
    return response.data is List ? response.data : [];
  }

  /// Busca todo conteúdo da clínica por tipo (para staff/admin)
  Future<List<dynamic>> getAllClinicContentByType(String type) async {
    final response = await get(
      '${ApiConfig.contentClinicEndpoint}/all',
      queryParameters: {'type': type},
    );
    return response.data is List ? response.data : [];
  }

  /// Busca estatísticas de conteúdo por tipo (contagem para grid principal)
  Future<Map<String, dynamic>> getContentStats() async {
    final response = await get(ApiConfig.contentClinicStatsEndpoint);
    return response.data is Map ? response.data as Map<String, dynamic> : {};
  }

  /// Cria conteúdo da clínica
  Future<Map<String, dynamic>> createClinicContent({
    required String type,
    required String category,
    required String title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
  }) async {
    final response = await post(
      ApiConfig.contentClinicEndpoint,
      data: {
        'type': type,
        'category': category,
        'title': title,
        if (description != null) 'description': description,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
      },
    );
    return response.data;
  }

  /// Atualiza conteúdo da clínica
  Future<Map<String, dynamic>> updateClinicContent(
    String contentId, {
    String? title,
    String? description,
    String? category,
    int? validFromDay,
    int? validUntilDay,
  }) async {
    final response = await put(
      '${ApiConfig.contentClinicEndpoint}/$contentId',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
      },
    );
    return response.data;
  }

  /// Toggle ativo/inativo de conteúdo
  Future<Map<String, dynamic>> toggleClinicContent(String contentId) async {
    final response =
        await patch('${ApiConfig.contentClinicEndpoint}/$contentId/toggle');
    return response.data;
  }

  /// Deleta conteúdo da clínica
  Future<void> deleteClinicContent(String contentId) async {
    await delete('${ApiConfig.contentClinicEndpoint}/$contentId');
  }

  /// Reordena conteúdos da clínica
  Future<void> reorderClinicContents(List<String> contentIds) async {
    await post(
      '${ApiConfig.contentClinicEndpoint}/reorder',
      data: {'contentIds': contentIds},
    );
  }

  /// Busca conteúdo da clínica do paciente por tipo (para pacientes)
  Future<List<dynamic>> getPatientClinicContent({
    required String type,
    String? category,
  }) async {
    final response = await get(
      ApiConfig.contentPatientClinicEndpoint,
      queryParameters: {
        'type': type,
        if (category != null) 'category': category,
      },
    );
    return response.data is List ? response.data : [];
  }

  /// Busca todo conteúdo da clínica do paciente por tipo
  Future<List<dynamic>> getAllPatientClinicContentByType(String type) async {
    final response = await get(
      '${ApiConfig.contentPatientClinicEndpoint}/all',
      queryParameters: {'type': type},
    );
    return response.data is List ? response.data : [];
  }

  /// Busca conteúdo personalizado do paciente
  Future<List<dynamic>> getPatientContent({
    required String type,
    int? day,
  }) async {
    final response = await get(
      ApiConfig.contentPatientEndpoint,
      queryParameters: {
        'type': type,
        if (day != null) 'day': day.toString(),
      },
    );
    // O backend retorna { type, items, totalCount }
    if (response.data is Map && response.data['items'] != null) {
      return response.data['items'] as List<dynamic>;
    }
    return response.data is List ? response.data : [];
  }

  // ==================== AGENDAMENTOS ====================

  /// Lista todas as consultas do paciente
  Future<List<dynamic>> getAppointments({String? status}) async {
    final response = await get(
      ApiConfig.appointmentsEndpoint,
      queryParameters: status != null ? {'status': status} : null,
    );
    return response.data is List ? response.data : [];
  }

  /// Lista próximas consultas (para dashboard)
  Future<List<dynamic>> getUpcomingAppointments({int limit = 5}) async {
    final response = await get(
      ApiConfig.appointmentsUpcomingEndpoint,
      queryParameters: {'limit': limit.toString()},
    );
    return response.data is List ? response.data : [];
  }

  /// Busca uma consulta específica
  Future<Map<String, dynamic>> getAppointmentById(String id) async {
    final response = await get('${ApiConfig.appointmentsEndpoint}/$id');
    return response.data;
  }

  /// Cria uma nova consulta
  Future<Map<String, dynamic>> createAppointment({
    required String title,
    required String date,
    required String time,
    required String type,
    String? description,
    String? location,
    String? notes,
  }) async {
    final response = await post(
      ApiConfig.appointmentsEndpoint,
      data: {
        'title': title,
        'date': date,
        'time': time,
        'type': type,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  /// Atualiza o status de uma consulta
  Future<Map<String, dynamic>> updateAppointmentStatus(
    String id,
    String status,
  ) async {
    final response = await patch(
      '${ApiConfig.appointmentsEndpoint}/$id/status',
      data: {'status': status},
    );
    return response.data;
  }

  /// Cancela uma consulta
  Future<Map<String, dynamic>> cancelAppointment(String id) async {
    final response = await patch('${ApiConfig.appointmentsEndpoint}/$id/cancel');
    return response.data;
  }

  /// Confirma uma consulta
  Future<Map<String, dynamic>> confirmAppointment(String id) async {
    final response = await patch('${ApiConfig.appointmentsEndpoint}/$id/confirm');
    return response.data;
  }

  // ==================== MEDICAÇÕES ====================

  /// Registra que uma medicação foi tomada
  Future<Map<String, dynamic>> logMedication({
    required String contentId,
    required String scheduledTime,
    String? takenAt,
  }) async {
    final response = await post(
      ApiConfig.medicationsLogEndpoint,
      data: {
        'contentId': contentId,
        'scheduledTime': scheduledTime,
        if (takenAt != null) 'takenAt': takenAt,
      },
    );
    return response.data;
  }

  /// Busca histórico de medicações do paciente
  Future<List<dynamic>> getMedicationLogs({
    String? startDate,
    String? endDate,
    String? contentId,
    int? limit,
  }) async {
    final response = await get(
      ApiConfig.medicationsLogsEndpoint,
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (contentId != null) 'contentId': contentId,
        if (limit != null) 'limit': limit.toString(),
      },
    );
    return response.data is List ? response.data : [];
  }

  /// Busca logs de medicações de hoje
  Future<List<dynamic>> getTodayMedicationLogs() async {
    final response = await get(ApiConfig.medicationsTodayEndpoint);
    return response.data is List ? response.data : [];
  }

  /// Busca porcentagem de adesão às medicações
  Future<Map<String, dynamic>> getMedicationAdherence({int? days}) async {
    final response = await get(
      ApiConfig.medicationsAdherenceEndpoint,
      queryParameters: days != null ? {'days': days.toString()} : null,
    );
    return response.data;
  }

  /// Verifica se uma medicação específica foi tomada hoje
  Future<bool> checkMedicationTakenToday(
    String contentId,
    String scheduledTime,
  ) async {
    final response = await get(
      '${ApiConfig.medicationsCheckEndpoint}/$contentId/$scheduledTime',
    );
    return response.data['taken'] == true;
  }

  /// Desfaz o registro de uma medicação
  Future<Map<String, dynamic>> undoMedicationLog(String logId) async {
    final response = await delete('${ApiConfig.medicationsLogEndpoint}/$logId');
    return response.data;
  }

  /// Adiciona uma medicação pessoal do paciente
  Future<Map<String, dynamic>> addPatientMedication({
    required String title,
    String? description,
    String? dosage,
    String? frequency,
    List<String>? times,
  }) async {
    final response = await post(
      '/content/patient/medication',
      data: {
        'title': title,
        if (description != null) 'description': description,
        if (dosage != null) 'dosage': dosage,
        if (frequency != null) 'frequency': frequency,
        if (times != null) 'times': times,
      },
    );
    return response.data;
  }

  // ==================== CHAT IA ====================

  /// Envia uma mensagem para o assistente IA
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? conversationId,
  }) async {
    final response = await post(
      ApiConfig.chatSendEndpoint,
      data: {
        'message': message,
        if (conversationId != null) 'conversationId': conversationId,
      },
    );
    return response.data;
  }

  /// Busca histórico de uma conversa específica
  Future<Map<String, dynamic>> getChatHistory(String conversationId) async {
    final response = await get(
      ApiConfig.chatHistoryEndpoint,
      queryParameters: {'conversationId': conversationId},
    );
    return response.data;
  }

  /// Lista todas as conversas do paciente
  Future<List<dynamic>> getChatConversations() async {
    final response = await get(ApiConfig.chatConversationsEndpoint);
    return response.data is List ? response.data : [];
  }

  // ==================== EXAMES ====================

  /// Lista exames do paciente
  Future<List<dynamic>> getPatientExams({String? status}) async {
    final response = await get(
      '/exams/patient',
      queryParameters: status != null ? {'status': status} : null,
    );
    return response.data is List ? response.data : [];
  }

  /// Busca estatísticas dos exames
  Future<Map<String, dynamic>> getExamStats() async {
    final response = await get('/exams/patient/stats');
    return response.data;
  }

  /// Busca detalhes de um exame
  Future<Map<String, dynamic>> getExamById(String examId) async {
    final response = await get('/exams/patient/$examId');
    return response.data;
  }

  /// Marca exame como visualizado
  Future<Map<String, dynamic>> markExamAsViewed(String examId) async {
    final response = await patch('/exams/patient/$examId/viewed');
    return response.data;
  }

  // ==================== PROTOCOLO DE TREINO ====================

  /// Busca o protocolo de treino com as semanas e status
  Future<Map<String, dynamic>> getTrainingProtocol() async {
    final response = await get('/content/patient/training-protocol');
    return response.data;
  }

  // ==================== HEALTH CHECK ====================

  /// Verifica se o backend está online
  Future<bool> healthCheck() async {
    try {
      final response = await get(ApiConfig.healthEndpoint);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== ADMIN / PAINEL CLÍNICA ====================

  /// Busca resumo do dashboard (indicadores)
  Future<Map<String, dynamic>> getAdminDashboardSummary() async {
    final response = await get(ApiConfig.adminDashboardSummaryEndpoint);
    return response.data;
  }

  /// Lista consultas pendentes de aprovação
  Future<Map<String, dynamic>> getAdminPendingAppointments({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await get(
      ApiConfig.adminPendingAppointmentsEndpoint,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return response.data;
  }

  /// Aprova uma consulta
  Future<Map<String, dynamic>> approveAppointment(
    String appointmentId, {
    String? notes,
  }) async {
    final response = await post(
      '/admin/appointments/$appointmentId/approve',
      data: notes != null ? {'notes': notes} : {},
    );
    return response.data;
  }

  /// Rejeita uma consulta
  Future<Map<String, dynamic>> rejectAppointment(
    String appointmentId, {
    String? reason,
  }) async {
    final response = await post(
      '/admin/appointments/$appointmentId/reject',
      data: reason != null ? {'reason': reason} : {},
    );
    return response.data;
  }

  /// Lista pacientes em recuperação
  Future<Map<String, dynamic>> getAdminRecoveryPatients({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await get(
      ApiConfig.adminRecoveryPatientsEndpoint,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return response.data;
  }

  /// Busca agendamentos de hoje
  Future<Map<String, dynamic>> getAdminTodayAppointments() async {
    final response = await get(ApiConfig.adminTodayAppointmentsEndpoint);
    return response.data;
  }

  /// Busca agendamentos do mês para calendário
  Future<Map<String, dynamic>> getAdminCalendar({
    int? month,
    int? year,
  }) async {
    final now = DateTime.now();
    final response = await get(
      ApiConfig.adminCalendarEndpoint,
      queryParameters: {
        'month': (month ?? now.month).toString(),
        'year': (year ?? now.year).toString(),
      },
    );
    return response.data;
  }

  /// Busca pacientes recentes
  Future<Map<String, dynamic>> getAdminRecentPatients({
    int limit = 5,
  }) async {
    final response = await get(
      ApiConfig.adminRecentPatientsEndpoint,
      queryParameters: {
        'limit': limit.toString(),
      },
    );
    return response.data;
  }

  /// Atualiza um agendamento (status, notas, tipo)
  Future<Map<String, dynamic>> updateAdminAppointment(
    String appointmentId, {
    String? status,
    String? notes,
    String? type,
  }) async {
    final response = await patch(
      '/admin/appointments/$appointmentId',
      data: {
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
        if (type != null) 'type': type,
      },
    );
    return response.data;
  }

  /// Cancela um agendamento pelo admin
  Future<Map<String, dynamic>> cancelAdminAppointment(
    String appointmentId, {
    String? reason,
  }) async {
    final response = await post(
      '/admin/appointments/$appointmentId/cancel',
      data: reason != null ? {'reason': reason} : {},
    );
    return response.data;
  }

  /// Cria um novo agendamento pelo admin
  Future<Map<String, dynamic>> createAdminAppointment({
    required String patientId,
    required String title,
    required String date,
    required String time,
    required String type,
    String? status,
    String? location,
    String? notes,
    String? description,
  }) async {
    final response = await post(
      '/admin/appointments',
      data: {
        'patientId': patientId,
        'title': title,
        'date': date,
        'time': time,
        'type': type,
        if (status != null) 'status': status,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
        if (description != null) 'description': description,
      },
    );
    return response.data;
  }

  /// Exporta agendamentos em CSV
  Future<List<int>> exportAdminAppointments({
    required String from,
    required String to,
    String? status,
  }) async {
    final response = await _dio.get(
      '/admin/appointments/export',
      queryParameters: {
        'from': from,
        'to': to,
        if (status != null && status != 'ALL') 'status': status,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  /// Lista alertas da clínica
  Future<Map<String, dynamic>> getAdminAlerts({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final response = await get(
      ApiConfig.adminAlertsEndpoint,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      },
    );
    return response.data;
  }

  /// Cria um alerta manual
  Future<Map<String, dynamic>> createAlert({
    required String type,
    required String title,
    String? description,
    String? patientId,
  }) async {
    final response = await post(
      ApiConfig.adminAlertsEndpoint,
      data: {
        'type': type,
        'title': title,
        if (description != null) 'description': description,
        if (patientId != null) 'patientId': patientId,
      },
    );
    return response.data;
  }

  /// Resolve um alerta
  Future<Map<String, dynamic>> resolveAlert(String alertId) async {
    final response = await patch('/admin/alerts/$alertId/resolve');
    return response.data;
  }

  /// Dispensa um alerta
  Future<Map<String, dynamic>> dismissAlert(String alertId) async {
    final response = await patch('/admin/alerts/$alertId/dismiss');
    return response.data;
  }

  /// Executa verificação de alertas automáticos
  Future<Map<String, dynamic>> checkAndGenerateAlerts() async {
    final response = await post('/admin/alerts/check');
    return response.data;
  }

  // ==================== PACIENTES (PAINEL CLÍNICA) ====================

  /// Lista pacientes da clínica
  Future<Map<String, dynamic>> getPatients({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await get(
      ApiConfig.patientsEndpoint,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
      },
    );
    return response.data;
  }

  /// Busca detalhes de um paciente
  Future<Map<String, dynamic>> getPatientById(String patientId) async {
    final fullUrl = '${ApiConfig.baseUrl}${ApiConfig.patientsEndpoint}/$patientId';
    debugPrint('[HTTP] -> GET $fullUrl headersAuth=${_authToken != null}');

    final stopwatch = Stopwatch()..start();
    try {
      final response = await get('${ApiConfig.patientsEndpoint}/$patientId');
      stopwatch.stop();
      debugPrint('[HTTP] <- status=${response.statusCode} ms=${stopwatch.elapsedMilliseconds}');
      debugPrint('[HTTP] <- body=${_truncate(response.data.toString(), 500)}');
      return response.data;
    } on DioException catch (e) {
      stopwatch.stop();
      debugPrint('[HTTP] ERROR type=${e.type}');
      debugPrint('[HTTP] ERROR status=${e.response?.statusCode}');
      debugPrint('[HTTP] ERROR data=${_truncate(e.response?.data?.toString() ?? 'null', 500)}');
      debugPrint('[HTTP] ERROR message=${e.message}');
      rethrow;
    } catch (e, stack) {
      stopwatch.stop();
      debugPrint('[HTTP] ERROR type=${e.runtimeType}');
      debugPrint('[HTTP] ERROR message=$e');
      debugPrint('[HTTP] STACK:');
      debugPrintStack(stackTrace: stack, maxFrames: 5);
      rethrow;
    }
  }

  /// Lista consultas de um paciente
  Future<Map<String, dynamic>> getPatientAppointments(
    String patientId, {
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await get(
      '${ApiConfig.patientsEndpoint}/$patientId/appointments',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      },
    );
    return response.data;
  }

  /// Atualiza dados do paciente
  Future<Map<String, dynamic>> updatePatient(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    final response = await patch(
      '${ApiConfig.patientsEndpoint}/$patientId',
      data: data,
    );
    return response.data;
  }

  /// Busca histórico completo do paciente
  Future<Map<String, dynamic>> getPatientHistory(
    String patientId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await get(
      '${ApiConfig.patientsEndpoint}/$patientId/history',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return response.data;
  }

  // ==================== ALERGIAS DO PACIENTE ====================

  /// Lista alergias de um paciente
  Future<List<dynamic>> getPatientAllergies(String patientId) async {
    final response = await get(
      '${ApiConfig.patientsEndpoint}/$patientId/allergies',
    );
    return response.data is List ? response.data : [];
  }

  /// Adiciona uma alergia ao paciente
  Future<Map<String, dynamic>> addPatientAllergy(
    String patientId, {
    required String name,
    String? severity,
    String? notes,
  }) async {
    final response = await post(
      '${ApiConfig.patientsEndpoint}/$patientId/allergies',
      data: {
        'name': name,
        if (severity != null) 'severity': severity,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  /// Remove uma alergia do paciente
  Future<Map<String, dynamic>> removePatientAllergy(
    String patientId,
    String allergyId,
  ) async {
    final response = await delete(
      '${ApiConfig.patientsEndpoint}/$patientId/allergies/$allergyId',
    );
    return response.data;
  }

  // ==================== NOTAS MÉDICAS DO PACIENTE ====================

  /// Lista notas médicas de um paciente
  Future<Map<String, dynamic>> getPatientMedicalNotes(
    String patientId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await get(
      '${ApiConfig.patientsEndpoint}/$patientId/medical-notes',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return response.data;
  }

  /// Adiciona uma nota médica ao paciente
  Future<Map<String, dynamic>> addPatientMedicalNote(
    String patientId, {
    required String content,
    String? author,
  }) async {
    final response = await post(
      '${ApiConfig.patientsEndpoint}/$patientId/medical-notes',
      data: {
        'content': content,
        if (author != null) 'author': author,
      },
    );
    return response.data;
  }

  /// Remove uma nota médica do paciente
  Future<Map<String, dynamic>> removePatientMedicalNote(
    String patientId,
    String noteId,
  ) async {
    final response = await delete(
      '${ApiConfig.patientsEndpoint}/$patientId/medical-notes/$noteId',
    );
    return response.data;
  }

  // ==================== CONSULTAS (CRIAR PARA PACIENTE) ====================

  /// Cria uma consulta para um paciente específico (usado pelo admin)
  Future<Map<String, dynamic>> createPatientAppointment(
    String patientId, {
    required String title,
    required String date,
    required String time,
    required String type,
    String? description,
    String? location,
    String? notes,
  }) async {
    final response = await post(
      ApiConfig.appointmentsEndpoint,
      data: {
        'patientId': patientId,
        'title': title,
        'date': date,
        'time': time,
        'type': type,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  // ==================== AJUSTES DE CONTEÚDO DO PACIENTE ====================

  /// Busca ajustes de conteúdo de um paciente específico
  /// Retorna dynamic pois backend pode retornar List ou Map
  Future<dynamic> getPatientContentAdjustments(
    String patientId, {
    String? contentType,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await get(
      '/content/patients/$patientId/adjustments',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (contentType != null) 'contentType': contentType,
      },
    );
    return response.data;
  }

  /// Adiciona conteúdo customizado para um paciente (adjustmentType = ADD)
  Future<Map<String, dynamic>> addPatientContent(
    String patientId, {
    required String contentType,
    required String category,
    required String title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
    String? reason,
  }) async {
    final endpoint = '/content/patients/$patientId/adjustments/add';
    final payload = {
      'contentType': contentType,
      'category': category,
      'title': title,
      if (description != null) 'description': description,
      if (validFromDay != null) 'validFromDay': validFromDay,
      if (validUntilDay != null) 'validUntilDay': validUntilDay,
      if (reason != null) 'reason': reason,
    };

    print('[API] addPatientContent: POST $endpoint');
    print('[API] payload: $payload');
    print('[API] authToken present: ${_authToken != null}');

    final response = await post(endpoint, data: payload);

    print('[API] addPatientContent response: ${response.statusCode}');

    return response.data;
  }

  /// Desabilita um conteúdo base para um paciente (adjustmentType = DISABLE)
  Future<Map<String, dynamic>> disablePatientContent(
    String patientId, {
    required String baseContentId,
    required String reason,
  }) async {
    final response = await post(
      '/content/patients/$patientId/adjustments/disable',
      data: {
        'baseContentId': baseContentId,
        'reason': reason,
      },
    );
    return response.data;
  }

  /// Modifica um conteúdo base para um paciente (adjustmentType = MODIFY)
  Future<Map<String, dynamic>> modifyPatientContent(
    String patientId, {
    required String baseContentId,
    String? title,
    String? description,
    String? category,
    String? reason,
  }) async {
    final response = await post(
      '/content/patients/$patientId/adjustments/modify',
      data: {
        'baseContentId': baseContentId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (reason != null) 'reason': reason,
      },
    );
    return response.data;
  }

  /// Cria um ajuste de conteúdo para um paciente (método legado - redireciona para métodos específicos)
  @Deprecated('Use addPatientContent, disablePatientContent, ou modifyPatientContent')
  Future<Map<String, dynamic>> createPatientContentAdjustment(
    String patientId, {
    required String adjustmentType,
    String? baseContentId,
    String? contentType,
    String? category,
    String? title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
    String? reason,
  }) async {
    // Redireciona para o método específico baseado no adjustmentType
    switch (adjustmentType) {
      case 'ADD':
        return addPatientContent(
          patientId,
          contentType: contentType!,
          category: category!,
          title: title!,
          description: description,
          validFromDay: validFromDay,
          validUntilDay: validUntilDay,
          reason: reason,
        );
      case 'DISABLE':
        return disablePatientContent(
          patientId,
          baseContentId: baseContentId!,
          reason: reason!,
        );
      case 'MODIFY':
        return modifyPatientContent(
          patientId,
          baseContentId: baseContentId!,
          title: title,
          description: description,
          category: category,
          reason: reason,
        );
      default:
        throw ArgumentError('adjustmentType inválido: $adjustmentType');
    }
  }

  /// Remove um ajuste de conteúdo de um paciente
  Future<Map<String, dynamic>> removePatientContentAdjustment(
    String patientId,
    String adjustmentId,
  ) async {
    final response = await delete(
      '/content/patients/$patientId/adjustments/$adjustmentId',
    );
    return response.data;
  }

  // ==================== CONEXÃO DE PACIENTE ====================

  /// Conecta paciente usando código de pareamento
  Future<Map<String, dynamic>> connectWithCode(String code) async {
    final response = await post(
      '/patient/connect',
      data: {'connectionCode': code.toUpperCase().trim()},
    );
    return response.data;
  }

  /// Admin gera código de conexão para um paciente
  Future<Map<String, dynamic>> generateConnectionCode(String patientId) async {
    final response = await post(
      '/admin/patients/$patientId/connection-code',
    );
    return response.data;
  }

  /// Admin lista conexões de um paciente
  Future<List<dynamic>> getPatientConnections(String patientId) async {
    final response = await get(
      '/admin/patients/$patientId/connections',
    );
    return response.data is List ? response.data : [];
  }

  /// Admin revoga um código de conexão
  Future<Map<String, dynamic>> revokeConnectionCode(String connectionId) async {
    final response = await delete(
      '/admin/connections/$connectionId',
    );
    return response.data;
  }

  // ==================== REFRESH TOKEN ====================

  /// Faz refresh do token manualmente
  Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
    final response = await post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return response.data;
  }

  /// Logout - revoga todos os refresh tokens
  Future<Map<String, dynamic>> logout() async {
    final response = await post('/auth/logout');
    return response.data;
  }

  // ==================== HUMAN HANDOFF (ADMIN) ====================

  /// Lista conversas em modo HUMAN para atendimento
  /// status: 'HUMAN' | 'CLOSED' (opcional)
  Future<Map<String, dynamic>> getHumanConversations({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final response = await get(
      '/chat/admin/conversations',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      },
    );
    return response.data;
  }

  /// Busca detalhes de uma conversa específica para admin
  Future<Map<String, dynamic>> getConversationForAdmin(String conversationId) async {
    final response = await get('/chat/admin/conversations/$conversationId');
    return response.data;
  }

  /// Envia mensagem como staff/admin em uma conversa em modo HUMAN
  Future<Map<String, dynamic>> sendHumanMessage(
    String conversationId,
    String message,
  ) async {
    final response = await post(
      '/chat/admin/conversations/$conversationId/message',
      data: {'message': message},
    );
    return response.data;
  }

  /// Fecha uma conversa em modo HUMAN
  /// returnToAi: true para voltar ao modo IA, false para fechar permanentemente
  Future<Map<String, dynamic>> closeHumanConversation(
    String conversationId, {
    bool returnToAi = true,
  }) async {
    final response = await post(
      '/chat/admin/conversations/$conversationId/close',
      data: {'returnToAi': returnToAi},
    );
    return response.data;
  }

  // ==================== CONTENT TEMPLATES (NOVO) ====================

  /// Lista templates de conteúdo da clínica
  Future<List<dynamic>> getContentTemplates({String? type}) async {
    final response = await get(
      '/content/templates',
      queryParameters: type != null ? {'type': type} : null,
    );
    return response.data is List ? response.data : [];
  }

  /// Busca um template específico
  Future<Map<String, dynamic>> getContentTemplateById(String id) async {
    final response = await get('/content/templates/$id');
    return response.data;
  }

  /// Cria um novo template de conteúdo
  Future<Map<String, dynamic>> createContentTemplate({
    required String type,
    required String category,
    required String title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
    int? sortOrder,
  }) async {
    final response = await post(
      '/content/templates',
      data: {
        'type': type,
        'category': category,
        'title': title,
        if (description != null) 'description': description,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );
    return response.data;
  }

  /// Atualiza um template de conteúdo
  Future<Map<String, dynamic>> updateContentTemplate(
    String id, {
    String? type,
    String? category,
    String? title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
    bool? isActive,
  }) async {
    final response = await put(
      '/content/templates/$id',
      data: {
        if (type != null) 'type': type,
        if (category != null) 'category': category,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
        if (isActive != null) 'isActive': isActive,
      },
    );
    return response.data;
  }

  /// Toggle ativo/inativo de um template
  Future<Map<String, dynamic>> toggleContentTemplate(String id) async {
    final response = await patch('/content/templates/$id/toggle');
    return response.data;
  }

  /// Deleta um template de conteúdo
  Future<void> deleteContentTemplate(String id) async {
    await delete('/content/templates/$id');
  }

  /// Reordena templates
  Future<void> reorderContentTemplates(List<String> templateIds) async {
    await post(
      '/content/templates/reorder',
      data: {'templateIds': templateIds},
    );
  }

  // ==================== PATIENT CONTENT OVERRIDES (NOVO) ====================

  /// Lista overrides de conteúdo de um paciente
  Future<List<dynamic>> getPatientContentOverrides(String patientId) async {
    final response = await get('/content/patients/$patientId/overrides');
    return response.data is List ? response.data : [];
  }

  /// Cria um override de conteúdo para um paciente
  /// action: 'ADD' | 'DISABLE' | 'MODIFY'
  Future<Map<String, dynamic>> createPatientContentOverride({
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
    final response = await post(
      '/content/patients/$patientId/overrides',
      data: {
        if (templateId != null) 'templateId': templateId,
        'action': action,
        if (type != null) 'type': type,
        if (category != null) 'category': category,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
        if (reason != null) 'reason': reason,
      },
    );
    return response.data;
  }

  /// Atualiza um override de conteúdo
  Future<Map<String, dynamic>> updatePatientContentOverride(
    String patientId,
    String overrideId, {
    String? category,
    String? title,
    String? description,
    int? validFromDay,
    int? validUntilDay,
    String? reason,
    bool? isActive,
  }) async {
    final response = await put(
      '/content/patients/$patientId/overrides/$overrideId',
      data: {
        if (category != null) 'category': category,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (validFromDay != null) 'validFromDay': validFromDay,
        if (validUntilDay != null) 'validUntilDay': validUntilDay,
        if (reason != null) 'reason': reason,
        if (isActive != null) 'isActive': isActive,
      },
    );
    return response.data;
  }

  /// Deleta um override de conteúdo
  Future<void> deletePatientContentOverride(
    String patientId,
    String overrideId,
  ) async {
    await delete('/content/patients/$patientId/overrides/$overrideId');
  }

  /// Preview do conteúdo final de um paciente (como admin)
  Future<Map<String, dynamic>> getPatientContentPreview(
    String patientId, {
    String? type,
  }) async {
    final response = await get(
      '/content/patients/$patientId/preview',
      queryParameters: type != null ? {'type': type} : null,
    );
    return response.data;
  }

  // ==================== PATIENT CONTENT FROM TEMPLATES ====================

  /// Busca conteúdo do paciente a partir dos templates (com overrides aplicados)
  Future<Map<String, dynamic>> getMyContentFromTemplates({String? type}) async {
    final endpoint = type != null
        ? '/content/patient/me/templates/type/$type'
        : '/content/patient/me/templates';
    final response = await get(endpoint);
    return response.data;
  }

  /// Verifica se há atualizações de conteúdo (polling)
  Future<Map<String, dynamic>> checkContentSync(int clientVersion) async {
    final response = await get(
      '/content/patient/me/sync',
      queryParameters: {'version': clientVersion.toString()},
    );
    return response.data;
  }
}
