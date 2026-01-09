import '../entities/chat_message.dart';

/// Resultado do envio de mensagem com conversationId
class SendMessageResult {
  final ChatMessage message;
  final String conversationId;

  SendMessageResult({
    required this.message,
    required this.conversationId,
  });
}

/// Resultado do carregamento de historico
class ChatHistoryResult {
  final String conversationId;
  final List<ChatMessage> messages;

  ChatHistoryResult({
    required this.conversationId,
    required this.messages,
  });
}

/// Interface abstrata do repositorio de chat
/// Permite trocar a implementacao (OpenAI direto vs Backend) facilmente
abstract class ChatRepository {
  /// Envia uma mensagem e retorna a resposta do assistente
  /// [message] - Mensagem do usuario
  /// [conversationId] - ID da conversa (opcional)
  Future<SendMessageResult> sendMessage(
    String message, {
    String? conversationId,
  });

  /// Carrega historico de uma conversa
  /// [conversationId] - ID da conversa (opcional, retorna mais recente se nao fornecido)
  Future<ChatHistoryResult?> getHistory({String? conversationId});
}
