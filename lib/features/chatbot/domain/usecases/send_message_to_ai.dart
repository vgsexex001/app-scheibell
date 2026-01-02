import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Caso de uso para enviar mensagem ao assistente IA
class SendMessageToAi {
  final ChatRepository _repository;

  SendMessageToAi(this._repository);

  /// Executa o caso de uso
  /// [messages] - Historico completo da conversa (para contexto)
  /// Retorna a mensagem de resposta do assistente
  Future<ChatMessage> call(List<ChatMessage> messages) async {
    return await _repository.sendMessage(messages);
  }
}
