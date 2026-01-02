import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_message_to_ai.dart';
import '../../data/repositories/chat_repository_impl.dart';

/// Estados possiveis do chat
enum ChatState { idle, loading, error }

/// Controller do chat usando ChangeNotifier (Provider pattern)
class ChatController extends ChangeNotifier {
  final SendMessageToAi _sendMessageToAi;

  ChatState _state = ChatState.idle;
  final List<ChatMessage> _messages = [];
  String? _errorMessage;

  ChatController({SendMessageToAi? sendMessageToAi})
      : _sendMessageToAi = sendMessageToAi ??
            SendMessageToAi(ChatRepositoryImpl());

  /// Estado atual do chat
  ChatState get state => _state;

  /// Lista de mensagens (somente leitura)
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Mensagem de erro atual
  String? get errorMessage => _errorMessage;

  /// Verifica se esta carregando
  bool get isLoading => _state == ChatState.loading;

  /// Adiciona mensagem inicial de boas-vindas
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

    // Adiciona mensagem do usuario
    final userMessage = ChatMessage.fromUser(content.trim());
    _messages.add(userMessage);

    // Atualiza estado para loading
    _state = ChatState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Filtra apenas mensagens de usuario e assistente para enviar (nao erros)
      final messagesToSend = _messages
          .where((m) => !m.isError && !m.isSystem)
          .toList();

      // Chama o caso de uso
      final response = await _sendMessageToAi(messagesToSend);

      // Adiciona resposta
      _messages.add(response);

      // Verifica se foi erro
      if (response.isError) {
        _state = ChatState.error;
        _errorMessage = response.content;
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

  /// Limpa o historico de mensagens
  void clearHistory() {
    _messages.clear();
    _state = ChatState.idle;
    _errorMessage = null;
    addWelcomeMessage();
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
}
