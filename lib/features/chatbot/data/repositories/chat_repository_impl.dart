import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_api_datasource.dart';

/// Implementacao do ChatRepository usando o backend
class ChatRepositoryImpl implements ChatRepository {
  final ChatApiDatasource _datasource;

  ChatRepositoryImpl({ChatApiDatasource? datasource})
      : _datasource = datasource ?? ChatApiDatasource();

  @override
  Future<SendMessageResult> sendMessage(
    String message, {
    String? conversationId,
  }) async {
    try {
      final response = await _datasource.sendMessage(
        message,
        conversationId: conversationId,
      );

      return SendMessageResult(
        message: response.message.toEntity(),
        conversationId: response.conversationId,
      );
    } on ChatApiException catch (e) {
      // Retorna mensagem de erro amigavel
      return SendMessageResult(
        message: ChatMessage.fromAssistant(
          e.userFriendlyMessage,
          isError: true,
        ),
        conversationId: conversationId ?? '',
      );
    } catch (e) {
      return SendMessageResult(
        message: ChatMessage.fromAssistant(
          'Ocorreu um erro inesperado. Por favor, tente novamente.',
          isError: true,
        ),
        conversationId: conversationId ?? '',
      );
    }
  }

  @override
  Future<ChatHistoryResult?> getHistory({String? conversationId}) async {
    try {
      final conversation = await _datasource.getHistory(
        conversationId: conversationId,
      );

      if (conversation == null) {
        return null;
      }

      return ChatHistoryResult(
        conversationId: conversation.id,
        messages: conversation.messages.map((m) => m.toEntity()).toList(),
      );
    } on ChatApiException {
      // Em caso de erro, retorna null (sem historico)
      return null;
    } catch (e) {
      return null;
    }
  }
}
