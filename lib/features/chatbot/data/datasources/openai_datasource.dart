import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_message.dart';

/// Excecao customizada para erros da OpenAI API
class OpenAiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  OpenAiException({
    required this.message,
    this.statusCode,
    this.errorType,
  });

  @override
  String toString() => 'OpenAiException: $message (status: $statusCode, type: $errorType)';

  /// Mensagem amigavel para o usuario
  String get userFriendlyMessage {
    if (statusCode == 401) {
      return 'Erro de autenticacao. Verifique a configuracao da API.';
    }
    if (statusCode == 404 || errorType == 'model_not_found') {
      return 'Modelo de IA nao encontrado. Verifique a configuracao.';
    }
    if (statusCode == 429) {
      return 'Muitas requisicoes. Aguarde um momento e tente novamente.';
    }
    if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
      return 'Servico temporariamente indisponivel. Tente novamente em alguns instantes.';
    }
    if (errorType == 'network') {
      return 'Sem conexao com a internet. Verifique sua rede e tente novamente.';
    }
    if (errorType == 'timeout') {
      return 'Tempo limite excedido. Tente novamente.';
    }
    return 'Ocorreu um erro. Por favor, tente novamente.';
  }
}

/// Datasource para comunicacao com a OpenAI API
class OpenAiDatasource {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _chatCompletionsEndpoint = '/chat/completions';

  final Dio _dio;

  /// System prompt para assistente medico pos-operatorio de rinoplastia
  static const String systemPrompt = '''Voce e um assistente medico virtual especializado em acompanhamento pos-operatorio de rinoplastia, desenvolvido para o App Scheibell.

DIRETRIZES DE COMPORTAMENTO:
1. Seja empatetico, acolhedor e profissional
2. Use linguagem clara e acessivel, evitando jargoes medicos complexos
3. Sempre reforce que suas orientacoes sao informativas e NAO substituem a consulta presencial
4. Em caso de sintomas graves (sangramento intenso, dificuldade respiratoria, febre alta, dor intensa nao controlada), oriente o paciente a entrar em contato imediatamente com a clinica ou ir ao pronto-socorro

TOPICOS QUE VOCE PODE ORIENTAR:
- Cuidados pos-operatorios gerais (higiene, curativos, uso do splint nasal)
- Medicacoes prescritas (horarios, dosagens, efeitos colaterais comuns)
- Alimentacao recomendada nos primeiros dias/semanas
- Atividades permitidas e restricoes (exercicios, exposicao solar, uso de oculos)
- Sintomas normais vs. sinais de alerta
- Cronograma de retornos e o que esperar em cada fase da recuperacao
- Dicas para reduzir inchaco e hematomas
- Orientacoes sobre sono e posicionamento

IMPORTANTE:
- Se o paciente relatar sintomas preocupantes, oriente-o a procurar atendimento presencial
- Nunca faca diagnosticos ou altere prescricoes medicas
- Encoraje o paciente a manter comunicacao com a equipe da clinica

Responda sempre em portugues brasileiro de forma clara e objetiva.''';

  OpenAiDatasource() : _dio = Dio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // Interceptor para logs em debug
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('[OpenAI] REQUEST: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('[OpenAI] RESPONSE: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('[OpenAI] ERROR: ${error.response?.statusCode} - ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Obtem a API key do arquivo .env
  String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw OpenAiException(
        message: 'OPENAI_API_KEY nao configurada no arquivo .env',
        errorType: 'configuration',
      );
    }
    return key;
  }

  /// Obtem o modelo do arquivo .env ou usa default
  String get _model => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';

  /// Envia mensagem para a OpenAI e retorna a resposta
  /// [messages] - Lista de mensagens do historico da conversa
  Future<ChatMessageModel> sendMessage(List<ChatMessage> messages) async {
    try {
      // Prepara as mensagens para a API (incluindo system prompt)
      final apiMessages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        ...messages.map((m) => m.toApiMessage()),
      ];

      final response = await _dio.post(
        _chatCompletionsEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: {
          'model': _model,
          'messages': apiMessages,
          'temperature': 0.7,
          'max_tokens': 1000,
        },
      );

      return ChatMessageModel.fromOpenAiResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is OpenAiException) rethrow;
      throw OpenAiException(
        message: 'Erro inesperado: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }

  /// Envia mensagem com system prompt customizado (para admin/clinica)
  /// [messages] - Lista de mensagens do historico da conversa
  /// [customSystemPrompt] - System prompt especifico para o contexto
  Future<ChatMessageModel> sendMessageWithCustomPrompt(
    List<ChatMessage> messages,
    String customSystemPrompt,
  ) async {
    try {
      // Prepara as mensagens para a API (com system prompt customizado)
      final apiMessages = <Map<String, String>>[
        {'role': 'system', 'content': customSystemPrompt},
        ...messages.map((m) => m.toApiMessage()),
      ];

      final response = await _dio.post(
        _chatCompletionsEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: {
          'model': _model,
          'messages': apiMessages,
          'temperature': 0.7,
          'max_tokens': 1000,
        },
      );

      return ChatMessageModel.fromOpenAiResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is OpenAiException) rethrow;
      throw OpenAiException(
        message: 'Erro inesperado: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }

  /// Trata erros do Dio e converte para OpenAiException
  OpenAiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return OpenAiException(
        message: 'Timeout na conexao',
        statusCode: null,
        errorType: 'timeout',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return OpenAiException(
        message: 'Erro de conexao com a internet',
        statusCode: null,
        errorType: 'network',
      );
    }

    final statusCode = error.response?.statusCode;
    final errorData = error.response?.data;
    String errorMessage = 'Erro desconhecido';
    String? errorType;

    // Tratamento específico para erro 404 (modelo não encontrado)
    if (statusCode == 404) {
      return OpenAiException(
        message: 'Modelo de IA nao encontrado. Verifique a configuracao.',
        statusCode: 404,
        errorType: 'model_not_found',
      );
    }

    if (errorData is Map<String, dynamic>) {
      final errorObj = errorData['error'];
      if (errorObj is Map<String, dynamic>) {
        errorMessage = errorObj['message'] ?? errorMessage;
        errorType = errorObj['type'];
      }
    }

    return OpenAiException(
      message: errorMessage,
      statusCode: statusCode,
      errorType: errorType,
    );
  }
}
