import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_message.dart';

/// Excecao customizada para erros da API de Chat
class ChatApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  ChatApiException({
    required this.message,
    this.statusCode,
    this.errorType,
  });

  @override
  String toString() =>
      'ChatApiException: $message (status: $statusCode, type: $errorType)';

  /// Mensagem amigavel para o usuario
  String get userFriendlyMessage {
    if (statusCode == 401) {
      return 'Sessao expirada. Faca login novamente.';
    }
    if (statusCode == 403) {
      return 'Acesso negado ao chat.';
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
    return 'Ocorreu um erro. Por favor, tente novamente.';
  }
}

/// Modelo para conversa do chat
class ConversationModel {
  final String id;
  final List<ChatMessageModel> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Human Handoff fields
  final ChatMode mode;
  final DateTime? handoffAt;
  final DateTime? closedAt;

  ConversationModel({
    required this.id,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.mode = ChatMode.ai,
    this.handoffAt,
    this.closedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List<dynamic>? ?? [];
    return ConversationModel(
      id: json['id'] ?? '',
      messages: messagesList
          .map((m) => ChatMessageModel.fromBackendJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      // Human Handoff fields
      mode: chatModeFromString(json['mode'] as String?),
      handoffAt: json['handoffAt'] != null
          ? DateTime.parse(json['handoffAt'])
          : null,
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'])
          : null,
    );
  }
}

/// Datasource para comunicacao com a API de Chat do backend
class ChatApiDatasource {
  final ApiService _apiService;

  ChatApiDatasource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Envia mensagem para o backend e retorna a resposta da IA
  /// [message] - Mensagem do usuario
  /// [conversationId] - ID da conversa (opcional, cria nova se nao fornecido)
  Future<ChatApiResponse> sendMessage(
    String message, {
    String? conversationId,
  }) async {
    try {
      final response = await _apiService.sendChatMessage(
        message: message,
        conversationId: conversationId,
      );

      // Backend retorna: { response: string, conversationId: string }
      final responseText = response['response'] as String? ?? '';
      final convId = response['conversationId'] as String? ?? '';

      // Validar conteudo - se vazio, retornar mensagem de erro
      if (responseText.trim().isEmpty) {
        debugPrint('[CHAT] API retornou resposta vazia: $response');
        return ChatApiResponse(
          message: ChatMessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Desculpe, nao consegui processar sua mensagem. Por favor, tente novamente.',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            isError: true,
          ),
          conversationId: convId,
        );
      }

      return ChatApiResponse(
        message: ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: responseText,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ),
        conversationId: convId,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is ChatApiException) rethrow;
      throw ChatApiException(
        message: 'Erro inesperado: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }

  /// Busca historico de uma conversa
  /// [conversationId] - ID da conversa (opcional, retorna a mais recente se nao fornecido)
  Future<ConversationModel?> getHistory({String? conversationId}) async {
    try {
      final Map<String, dynamic> response;

      if (conversationId != null) {
        response = await _apiService.getChatHistory(conversationId);
      } else {
        // Se nao tem conversationId, busca o historico mais recente
        final historyResponse = await _apiService.get(
          '/chat/history',
        );
        response = historyResponse.data is Map<String, dynamic>
            ? historyResponse.data
            : {};
      }

      if (response.isEmpty || response['id'] == null) {
        return null;
      }

      return ConversationModel.fromJson(response);
    } on DioException catch (e) {
      // Se for 404, nao tem historico - retorna null
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleDioError(e);
    } catch (e) {
      if (e is ChatApiException) rethrow;
      throw ChatApiException(
        message: 'Erro ao carregar historico: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }

  /// Lista todas as conversas do paciente
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _apiService.getChatConversations();

      return response
          .map((c) => ConversationModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is ChatApiException) rethrow;
      throw ChatApiException(
        message: 'Erro ao listar conversas: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }

  // ==================== IMAGE UPLOAD & ANALYSIS ====================

  /// Faz upload de uma imagem para o chat
  /// [imageFile] - Arquivo de imagem (jpg, png, heic)
  /// [conversationId] - ID da conversa (opcional)
  Future<UploadAttachmentResponse> uploadAttachment(
    File imageFile, {
    String? conversationId,
  }) async {
    final stopwatch = Stopwatch()..start();
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final fileSize = await imageFile.length();

    debugPrint('[ChatAPI] uploadAttachment START');
    debugPrint('[ChatAPI] file: $fileName, size: ${(fileSize / 1024).toStringAsFixed(1)}KB');
    debugPrint('[ChatAPI] endpoint: /chat/attachments');

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        if (conversationId != null) 'conversationId': conversationId,
      });

      // Para multipart/form-data, usamos o post normal - Dio detecta automaticamente
      final response = await _apiService.post(
        '/chat/attachments',
        data: formData,
      );

      stopwatch.stop();
      debugPrint('[ChatAPI] uploadAttachment SUCCESS in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('[ChatAPI] response: ${response.data}');

      return UploadAttachmentResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      debugPrint('[ChatAPI] uploadAttachment FAILED in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('[ChatAPI] error type: ${e.type}');
      debugPrint('[ChatAPI] error message: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      stopwatch.stop();
      debugPrint('[ChatAPI] uploadAttachment ERROR in ${stopwatch.elapsedMilliseconds}ms: $e');
      if (e is ChatApiException) rethrow;
      throw ChatApiException(
        message: 'Erro ao fazer upload da imagem: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }

  /// Solicita analise de uma imagem pela IA
  /// [attachmentId] - ID do anexo a ser analisado
  /// [userPrompt] - Prompt opcional do usuario
  Future<ImageAnalyzeResponse> analyzeImage({
    required String attachmentId,
    String? userPrompt,
  }) async {
    final stopwatch = Stopwatch()..start();

    debugPrint('[ChatAPI] analyzeImage START');
    debugPrint('[ChatAPI] attachmentId: $attachmentId');
    debugPrint('[ChatAPI] userPrompt: ${userPrompt ?? "(nenhum)"}');
    debugPrint('[ChatAPI] endpoint: /chat/image-analyze');

    try {
      final response = await _apiService.post(
        '/chat/image-analyze',
        data: {
          'attachmentId': attachmentId,
          if (userPrompt != null) 'userPrompt': userPrompt,
        },
      );

      stopwatch.stop();
      debugPrint('[ChatAPI] analyzeImage SUCCESS in ${stopwatch.elapsedMilliseconds}ms');

      return ImageAnalyzeResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      debugPrint('[ChatAPI] analyzeImage FAILED in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('[ChatAPI] error type: ${e.type}');
      debugPrint('[ChatAPI] error message: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      stopwatch.stop();
      debugPrint('[ChatAPI] analyzeImage ERROR in ${stopwatch.elapsedMilliseconds}ms: $e');
      if (e is ChatApiException) rethrow;
      throw ChatApiException(
        message: 'Erro ao analisar imagem: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }

  /// Valida se o arquivo e uma imagem valida (jpg, png, heic)
  bool isValidImageFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'heic', 'heif'].contains(extension);
  }

  /// Retorna o tamanho maximo permitido para upload (10MB)
  int get maxFileSizeBytes => 10 * 1024 * 1024;

  /// Verifica se o arquivo esta dentro do limite de tamanho
  Future<bool> isFileSizeValid(File file) async {
    final size = await file.length();
    return size <= maxFileSizeBytes;
  }

  // ==================== HUMAN HANDOFF ====================

  /// Solicita transferencia para atendimento humano
  /// [conversationId] - ID da conversa (opcional)
  /// [reason] - Motivo da solicitacao (opcional)
  Future<HandoffResponse> requestHandoff({
    String? conversationId,
    String? reason,
  }) async {
    debugPrint('[ChatAPI] requestHandoff START');
    debugPrint('[ChatAPI] conversationId: ${conversationId ?? "(nova)"}');

    try {
      final response = await _apiService.post(
        '/chat/handoff',
        data: {
          if (conversationId != null) 'conversationId': conversationId,
          if (reason != null) 'reason': reason,
        },
      );

      debugPrint('[ChatAPI] requestHandoff SUCCESS');
      debugPrint('[ChatAPI] response: ${response.data}');

      return HandoffResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[ChatAPI] requestHandoff FAILED: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('[ChatAPI] requestHandoff ERROR: $e');
      if (e is ChatApiException) rethrow;
      throw ChatApiException(
        message: 'Erro ao solicitar atendimento: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }

  /// Obtem o status/modo da conversa atual
  /// [conversationId] - ID da conversa (opcional, retorna a mais recente se nao fornecido)
  Future<ConversationStatusResponse?> getConversationStatus({
    String? conversationId,
  }) async {
    debugPrint('[ChatAPI] getConversationStatus START');

    try {
      final response = await _apiService.get(
        '/chat/conversation-status',
        queryParameters: {
          if (conversationId != null) 'conversationId': conversationId,
        },
      );

      if (response.data == null) {
        debugPrint('[ChatAPI] getConversationStatus: null');
        return null;
      }

      debugPrint('[ChatAPI] getConversationStatus SUCCESS: ${response.data}');
      return ConversationStatusResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('[ChatAPI] getConversationStatus: not found');
        return null;
      }
      debugPrint('[ChatAPI] getConversationStatus FAILED: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('[ChatAPI] getConversationStatus ERROR: $e');
      if (e is ChatApiException) rethrow;
      throw ChatApiException(
        message: 'Erro ao obter status: ${e.toString()}',
        errorType: 'unknown',
      );
    }
  }

  /// Trata erros do Dio e converte para ChatApiException
  ChatApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ChatApiException(
        message: 'Timeout na conexao',
        statusCode: null,
        errorType: 'timeout',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ChatApiException(
        message: 'Erro de conexao com a internet',
        statusCode: null,
        errorType: 'network',
      );
    }

    final statusCode = error.response?.statusCode;
    final errorData = error.response?.data;
    String errorMessage = 'Erro desconhecido';
    String? errorType;

    if (errorData is Map<String, dynamic>) {
      errorMessage = errorData['message']?.toString() ?? errorMessage;
      errorType = errorData['error']?.toString();
    }

    return ChatApiException(
      message: errorMessage,
      statusCode: statusCode,
      errorType: errorType,
    );
  }
}

/// Resposta da API de chat
class ChatApiResponse {
  final ChatMessageModel message;
  final String conversationId;

  ChatApiResponse({
    required this.message,
    required this.conversationId,
  });
}

/// Resposta do upload de anexo
class UploadAttachmentResponse {
  final String id;
  final String conversationId;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final String status;
  final DateTime createdAt;

  UploadAttachmentResponse({
    required this.id,
    required this.conversationId,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    required this.createdAt,
  });

  factory UploadAttachmentResponse.fromJson(Map<String, dynamic> json) {
    return UploadAttachmentResponse(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      originalName: json['originalName'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Resposta da analise de imagem
class ImageAnalyzeResponse {
  final String response;
  final String conversationId;
  final String messageId;
  final String attachmentId;

  ImageAnalyzeResponse({
    required this.response,
    required this.conversationId,
    required this.messageId,
    required this.attachmentId,
  });

  factory ImageAnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return ImageAnalyzeResponse(
      response: json['response'] as String,
      conversationId: json['conversationId'] as String,
      messageId: json['messageId'] as String,
      attachmentId: json['attachmentId'] as String,
    );
  }
}

// ==================== HUMAN HANDOFF RESPONSE CLASSES ====================

/// Resposta da solicitacao de handoff
class HandoffResponse {
  final String conversationId;
  final String mode;
  final String handoffAt;
  final String alertId;
  final String message;

  HandoffResponse({
    required this.conversationId,
    required this.mode,
    required this.handoffAt,
    required this.alertId,
    required this.message,
  });

  factory HandoffResponse.fromJson(Map<String, dynamic> json) {
    return HandoffResponse(
      conversationId: json['conversationId'] as String,
      mode: json['mode'] as String,
      handoffAt: json['handoffAt'] as String,
      alertId: json['alertId'] as String? ?? '',
      message: json['message'] as String,
    );
  }

  ChatMode get chatMode => chatModeFromString(mode);
  DateTime get handoffDateTime => DateTime.parse(handoffAt);
}

/// Resposta do status da conversa
class ConversationStatusResponse {
  final String conversationId;
  final String mode;
  final String? handoffAt;
  final String? closedAt;

  ConversationStatusResponse({
    required this.conversationId,
    required this.mode,
    this.handoffAt,
    this.closedAt,
  });

  factory ConversationStatusResponse.fromJson(Map<String, dynamic> json) {
    return ConversationStatusResponse(
      conversationId: json['conversationId'] as String,
      mode: json['mode'] as String,
      handoffAt: json['handoffAt'] as String?,
      closedAt: json['closedAt'] as String?,
    );
  }

  ChatMode get chatMode => chatModeFromString(mode);
  DateTime? get handoffDateTime =>
      handoffAt != null ? DateTime.parse(handoffAt!) : null;
  DateTime? get closedDateTime =>
      closedAt != null ? DateTime.parse(closedAt!) : null;
}
