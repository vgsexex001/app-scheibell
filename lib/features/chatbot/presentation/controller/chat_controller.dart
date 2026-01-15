import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_message_to_ai.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/datasources/chat_api_datasource.dart';

/// Estados possiveis do chat
enum ChatState { idle, loading, loadingHistory, uploading, analyzing, requestingHandoff, error }

/// Controller do chat usando ChangeNotifier (Provider pattern)
class ChatController extends ChangeNotifier {
  final SendMessageToAi _sendMessageToAi;
  final LoadChatHistory _loadChatHistory;
  final ChatApiDatasource _chatApiDatasource;

  ChatState _state = ChatState.idle;
  final List<ChatMessage> _messages = [];
  String? _errorMessage;
  String? _conversationId;
  bool _historyLoaded = false;

  // Campos para upload de imagem
  File? _pendingImage;
  UploadAttachmentResponse? _pendingAttachment;

  // Human Handoff
  ChatMode _chatMode = ChatMode.ai;
  DateTime? _handoffAt;

  ChatController({
    SendMessageToAi? sendMessageToAi,
    LoadChatHistory? loadChatHistory,
    ChatApiDatasource? chatApiDatasource,
  })  : _sendMessageToAi = sendMessageToAi ??
            SendMessageToAi(ChatRepositoryImpl()),
        _loadChatHistory = loadChatHistory ??
            LoadChatHistory(ChatRepositoryImpl()),
        _chatApiDatasource = chatApiDatasource ?? ChatApiDatasource();

  /// Estado atual do chat
  ChatState get state => _state;

  /// Lista de mensagens (somente leitura)
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Mensagem de erro atual
  String? get errorMessage => _errorMessage;

  /// ID da conversa atual
  String? get conversationId => _conversationId;

  /// Verifica se esta carregando
  bool get isLoading => _state == ChatState.loading;

  /// Verifica se esta carregando historico
  bool get isLoadingHistory => _state == ChatState.loadingHistory;

  /// Verifica se o historico ja foi carregado
  bool get historyLoaded => _historyLoaded;

  /// Verifica se esta fazendo upload
  bool get isUploading => _state == ChatState.uploading;

  /// Verifica se esta analisando imagem
  bool get isAnalyzing => _state == ChatState.analyzing;

  /// Imagem pendente para envio
  File? get pendingImage => _pendingImage;

  /// Anexo pendente (apos upload)
  UploadAttachmentResponse? get pendingAttachment => _pendingAttachment;

  /// Verifica se tem imagem pendente
  bool get hasPendingImage => _pendingImage != null || _pendingAttachment != null;

  // ==================== HUMAN HANDOFF ====================

  /// Modo atual da conversa (AI, HUMAN, CLOSED)
  ChatMode get chatMode => _chatMode;

  /// Timestamp de quando foi solicitado handoff
  DateTime? get handoffAt => _handoffAt;

  /// Verifica se esta em modo humano
  bool get isHumanMode => _chatMode == ChatMode.human;

  /// Verifica se a conversa esta fechada
  bool get isClosed => _chatMode == ChatMode.closed;

  /// Verifica se esta solicitando handoff
  bool get isRequestingHandoff => _state == ChatState.requestingHandoff;

  /// Carrega o historico do chat do backend
  Future<void> loadHistory() async {
    if (_historyLoaded) return;

    _state = ChatState.loadingHistory;
    notifyListeners();

    try {
      final result = await _loadChatHistory();

      if (result != null && result.messages.isNotEmpty) {
        _conversationId = result.conversationId;
        _messages.clear();
        _messages.addAll(result.messages);

        // Carrega modo da conversa (Human Handoff)
        await loadConversationStatus();
      } else {
        // Nao tem historico, adiciona mensagem de boas-vindas
        _addWelcomeMessageInternal();
      }

      _historyLoaded = true;
      _state = ChatState.idle;
    } catch (e) {
      debugPrint('Erro ao carregar historico: $e');
      // Em caso de erro, ainda mostra mensagem de boas-vindas
      _addWelcomeMessageInternal();
      _historyLoaded = true;
      _state = ChatState.idle;
    }

    notifyListeners();
  }

  /// Adiciona mensagem inicial de boas-vindas (interno)
  void _addWelcomeMessageInternal() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.fromAssistant(
        'Ola! Sou sua assistente virtual para acompanhamento pos-operatorio.\nComo posso ajudar voce hoje?',
      ));
    }
  }

  /// Adiciona mensagem inicial de boas-vindas (publico - para compatibilidade)
  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.fromAssistant(
        'Ola! Sou sua assistente virtual para acompanhamento pos-operatorio.\nComo posso ajudar voce hoje?',
      ));
      notifyListeners();
    }
  }

  /// Envia uma mensagem do usuario
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Se estiver em modo humano, usa fluxo diferente (sem IA)
    if (_chatMode == ChatMode.human) {
      await _sendMessageInHumanMode(content);
      return;
    }

    // Adiciona mensagem do usuario
    final userMessage = ChatMessage.fromUser(content.trim());
    _messages.add(userMessage);

    // Atualiza estado para loading
    _state = ChatState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Chama o caso de uso com conversationId para manter contexto
      final result = await _sendMessageToAi(
        content.trim(),
        conversationId: _conversationId,
      );

      // Atualiza conversationId se vier do backend
      if (result.conversationId.isNotEmpty) {
        _conversationId = result.conversationId;
      }

      // Validar que mensagem AI tem conteudo antes de adicionar
      if (result.message.content.trim().isNotEmpty) {
        _messages.add(result.message);
      } else {
        // Mensagem vazia - adicionar erro ao inves de bolha vazia
        debugPrint('[CHAT] Mensagem AI vazia ignorada');
        _messages.add(ChatMessage.fromAssistant(
          'Desculpe, ocorreu um erro ao processar sua mensagem.',
          isError: true,
        ));
      }

      // Verifica se foi erro
      if (result.message.isError) {
        _state = ChatState.error;
        _errorMessage = result.message.content;
      } else {
        _state = ChatState.idle;
      }
    } catch (e) {
      _state = ChatState.error;
      _errorMessage = 'Erro ao enviar mensagem: ${e.toString()}';
      _messages.add(ChatMessage.fromAssistant(
        'Desculpe, ocorreu um erro. Por favor, tente novamente.',
        isError: true,
      ));
    }

    notifyListeners();
  }

  /// Envia uma pergunta rapida pre-definida
  Future<void> sendQuickQuestion(String question) async {
    await sendMessage(question);
  }

  /// Limpa o historico de mensagens (cria nova conversa)
  void clearHistory() {
    _messages.clear();
    _conversationId = null;
    _historyLoaded = false;
    _state = ChatState.idle;
    _errorMessage = null;
    // Reset Human Handoff state
    _chatMode = ChatMode.ai;
    _handoffAt = null;
    _addWelcomeMessageInternal();
    notifyListeners();
  }

  /// Reenvia a ultima mensagem do usuario (retry)
  Future<void> retryLastMessage() async {
    // Encontra a ultima mensagem do usuario
    final lastUserMessage = _messages.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage.fromUser(''),
    );

    if (lastUserMessage.content.isNotEmpty) {
      // Remove a ultima resposta de erro se houver
      if (_messages.isNotEmpty && _messages.last.isError) {
        _messages.removeLast();
      }
      // Remove a ultima mensagem do usuario para reenviar
      _messages.removeWhere((m) => m.id == lastUserMessage.id);
      notifyListeners();

      // Reenvia
      await sendMessage(lastUserMessage.content);
    }
  }

  // ==================== IMAGE UPLOAD & ANALYSIS ====================

  /// Define uma imagem para enviar (valida formato e tamanho)
  /// Retorna true se a imagem for valida
  Future<bool> setImageToSend(File imageFile) async {
    // Valida formato
    if (!_chatApiDatasource.isValidImageFile(imageFile)) {
      _errorMessage = 'Formato invalido. Use JPG, PNG ou HEIC.';
      notifyListeners();
      return false;
    }

    // Valida tamanho
    if (!await _chatApiDatasource.isFileSizeValid(imageFile)) {
      _errorMessage = 'Imagem muito grande. Maximo 10MB.';
      notifyListeners();
      return false;
    }

    _pendingImage = imageFile;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Cancela a imagem pendente
  void cancelPendingImage() {
    _pendingImage = null;
    _pendingAttachment = null;
    notifyListeners();
  }

  /// Envia mensagem com imagem para analise da IA
  /// [text] - Texto opcional para acompanhar a imagem
  Future<void> sendMessageWithImage({String? text}) async {
    if (_pendingImage == null) {
      _errorMessage = 'Nenhuma imagem selecionada.';
      notifyListeners();
      return;
    }

    final imageFile = _pendingImage!;
    final userPrompt = text?.trim();

    // Limpa imagem pendente
    _pendingImage = null;

    // Fase 1: Upload da imagem
    _state = ChatState.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Faz upload
      final uploadResponse = await _chatApiDatasource.uploadAttachment(
        imageFile,
        conversationId: _conversationId,
      );

      // Atualiza conversationId se for nova conversa
      if (_conversationId == null || _conversationId!.isEmpty) {
        _conversationId = uploadResponse.conversationId;
      }

      // Adiciona mensagem do usuario com imagem (content vazio se nao houver caption)
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: userPrompt ?? '',
        role: MessageRole.user,
        timestamp: DateTime.now(),
        attachments: [
          ChatAttachment(
            id: uploadResponse.id,
            originalName: uploadResponse.originalName,
            mimeType: uploadResponse.mimeType,
            sizeBytes: uploadResponse.sizeBytes,
            status: AttachmentStatus.pending,
            createdAt: uploadResponse.createdAt,
            localPath: imageFile.path,
          ),
        ],
      );
      _messages.add(userMessage);
      notifyListeners();

      // Fase 2: Analise pela IA
      _state = ChatState.analyzing;
      notifyListeners();

      final analyzeResponse = await _chatApiDatasource.analyzeImage(
        attachmentId: uploadResponse.id,
        userPrompt: userPrompt,
      );

      // Adiciona resposta da IA
      _messages.add(ChatMessage.fromAssistant(analyzeResponse.response));

      _state = ChatState.idle;
      _pendingAttachment = null;
    } on ChatApiException catch (e) {
      _state = ChatState.error;
      _errorMessage = e.userFriendlyMessage;
      _messages.add(ChatMessage.fromAssistant(
        'Desculpe, nao foi possivel analisar a imagem. ${e.userFriendlyMessage}',
        isError: true,
      ));
    } catch (e) {
      _state = ChatState.error;
      _errorMessage = 'Erro ao processar imagem: ${e.toString()}';
      _messages.add(ChatMessage.fromAssistant(
        'Desculpe, ocorreu um erro ao processar a imagem. Tente novamente.',
        isError: true,
      ));
    }

    notifyListeners();
  }

  /// Faz apenas o upload da imagem (sem analise imediata)
  /// Util para preparar imagem antes de enviar com texto
  Future<bool> uploadImage(File imageFile) async {
    // Valida a imagem primeiro
    if (!await setImageToSend(imageFile)) {
      return false;
    }

    _state = ChatState.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _chatApiDatasource.uploadAttachment(
        imageFile,
        conversationId: _conversationId,
      );

      _conversationId = response.conversationId;
      _pendingAttachment = response;
      _pendingImage = null;
      _state = ChatState.idle;
      notifyListeners();
      return true;
    } on ChatApiException catch (e) {
      _state = ChatState.error;
      _errorMessage = e.userFriendlyMessage;
      _pendingImage = null;
      notifyListeners();
      return false;
    } catch (e) {
      _state = ChatState.error;
      _errorMessage = 'Erro ao fazer upload: ${e.toString()}';
      _pendingImage = null;
      notifyListeners();
      return false;
    }
  }

  /// Analisa uma imagem ja enviada (pendingAttachment)
  /// [userPrompt] - Pergunta ou contexto para a analise
  Future<void> analyzeUploadedImage({String? userPrompt}) async {
    if (_pendingAttachment == null) {
      _errorMessage = 'Nenhuma imagem para analisar.';
      notifyListeners();
      return;
    }

    final attachment = _pendingAttachment!;
    _pendingAttachment = null;

    // Adiciona mensagem do usuario
    final promptText = userPrompt?.trim() ?? 'Analise esta imagem';
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '[Imagem: ${attachment.originalName}] $promptText',
      role: MessageRole.user,
      timestamp: DateTime.now(),
    ));

    _state = ChatState.analyzing;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _chatApiDatasource.analyzeImage(
        attachmentId: attachment.id,
        userPrompt: userPrompt,
      );

      _messages.add(ChatMessage.fromAssistant(response.response));
      _state = ChatState.idle;
    } on ChatApiException catch (e) {
      _state = ChatState.error;
      _errorMessage = e.userFriendlyMessage;
      _messages.add(ChatMessage.fromAssistant(
        'Desculpe, nao foi possivel analisar a imagem. ${e.userFriendlyMessage}',
        isError: true,
      ));
    } catch (e) {
      _state = ChatState.error;
      _errorMessage = 'Erro ao analisar imagem: ${e.toString()}';
      _messages.add(ChatMessage.fromAssistant(
        'Desculpe, ocorreu um erro ao analisar a imagem. Tente novamente.',
        isError: true,
      ));
    }

    notifyListeners();
  }

  // ==================== HUMAN HANDOFF METHODS ====================

  /// Solicita transferencia para atendimento humano
  /// [reason] - Motivo da solicitacao (opcional)
  Future<bool> requestHandoff({String? reason}) async {
    _state = ChatState.requestingHandoff;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _chatApiDatasource.requestHandoff(
        conversationId: _conversationId,
        reason: reason,
      );

      _chatMode = response.chatMode;
      _handoffAt = response.handoffDateTime;
      _conversationId = response.conversationId;

      // Adiciona mensagem de sistema local
      _messages.add(ChatMessage(
        id: 'handoff_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Voce foi transferido para nossa equipe de atendimento. Aguarde, em breve alguem ira atende-lo.',
        role: MessageRole.system,
        timestamp: DateTime.now(),
        senderType: 'system',
      ));

      _state = ChatState.idle;
      notifyListeners();
      return true;
    } on ChatApiException catch (e) {
      _state = ChatState.error;
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _state = ChatState.error;
      _errorMessage = 'Erro ao solicitar atendimento humano';
      debugPrint('Erro no handoff: $e');
      notifyListeners();
      return false;
    }
  }

  /// Carrega o status da conversa do servidor
  Future<void> loadConversationStatus() async {
    try {
      final status = await _chatApiDatasource.getConversationStatus(
        conversationId: _conversationId,
      );

      if (status != null) {
        _chatMode = status.chatMode;
        _handoffAt = status.handoffDateTime;
        _conversationId = status.conversationId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar status da conversa: $e');
    }
  }

  /// Envia mensagem em modo humano (sem esperar resposta da IA)
  Future<void> _sendMessageInHumanMode(String content) async {
    if (content.trim().isEmpty) return;

    // Adiciona mensagem do usuario localmente
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
      senderType: 'patient',
    );
    _messages.add(userMessage);
    notifyListeners();

    try {
      // Envia para backend (sem esperar resposta IA)
      await _sendMessageToAi(
        content.trim(),
        conversationId: _conversationId,
      );
    } catch (e) {
      debugPrint('Erro ao enviar mensagem em modo humano: $e');
      // Mensagem ja aparece localmente, nao precisa adicionar erro
    }
  }

  /// Atualiza o modo da conversa a partir de resposta do servidor
  void updateModeFromServer(String? mode, String? handoffAtStr) {
    _chatMode = chatModeFromString(mode);
    if (handoffAtStr != null) {
      _handoffAt = DateTime.tryParse(handoffAtStr);
    }
    notifyListeners();
  }
}
