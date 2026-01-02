import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor para adicionar token e logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
          print('ERROR MESSAGE: ${error.message}');
          return handler.next(error);
        },
      ),
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
}
