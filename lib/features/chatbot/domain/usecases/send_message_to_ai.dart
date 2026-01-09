import '../repositories/chat_repository.dart';

/// Caso de uso para enviar mensagem ao assistente IA
class SendMessageToAi {
  final ChatRepository _repository;

  SendMessageToAi(this._repository);

  /// Executa o caso de uso
  /// [message] - Mensagem do usuario
  /// [conversationId] - ID da conversa para manter contexto
  /// Retorna o resultado com a mensagem de resposta e conversationId
  Future<SendMessageResult> call(
    String message, {
    String? conversationId,
  }) async {
    return await _repository.sendMessage(
      message,
      conversationId: conversationId,
    );
  }
}

/// Caso de uso para carregar historico do chat
class LoadChatHistory {
  final ChatRepository _repository;

  LoadChatHistory(this._repository);

  /// Executa o caso de uso
  /// [conversationId] - ID da conversa (opcional)
  /// Retorna o historico ou null se nao houver
  Future<ChatHistoryResult?> call({String? conversationId}) async {
    return await _repository.getHistory(conversationId: conversationId);
  }
}
