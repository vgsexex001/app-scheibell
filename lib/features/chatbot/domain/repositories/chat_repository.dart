import '../entities/chat_message.dart';

/// Interface abstrata do repositorio de chat
/// Permite trocar a implementacao (OpenAI direto vs Backend) facilmente
abstract class ChatRepository {
  /// Envia uma mensagem e retorna a resposta do assistente
  /// [messages] - Historico completo da conversa para contexto
  Future<ChatMessage> sendMessage(List<ChatMessage> messages);
}
