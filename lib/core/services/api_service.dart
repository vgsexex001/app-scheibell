import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

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

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor para adicionar token e logging detalhado
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
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
        onError: (error, handler) {
          _logError(error);
          return handler.next(error);
        },
      ),
    );
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

  /// Carrega o token salvo do SharedPreferences
  Future<String?> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    return _authToken;
  }

  /// Salva o token no SharedPreferences
  Future<void> saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Remove o token salvo
  Future<void> removeToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

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
    final response = await post(
      ApiConfig.loginEndpoint,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data;
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
}
