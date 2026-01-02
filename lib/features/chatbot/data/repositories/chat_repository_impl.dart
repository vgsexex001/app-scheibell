import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/openai_datasource.dart';

/// Implementacao do ChatRepository usando OpenAI diretamente
class ChatRepositoryImpl implements ChatRepository {
  final OpenAiDatasource _datasource;

  ChatRepositoryImpl({OpenAiDatasource? datasource})
      : _datasource = datasource ?? OpenAiDatasource();

  @override
  Future<ChatMessage> sendMessage(List<ChatMessage> messages) async {
    try {
      final response = await _datasource.sendMessage(messages);
      return response.toEntity();
    } on OpenAiException catch (e) {
      // Retorna mensagem de erro amigavel
      return ChatMessage.fromAssistant(
        e.userFriendlyMessage,
        isError: true,
      );
    } catch (e) {
      return ChatMessage.fromAssistant(
        'Ocorreu um erro inesperado. Por favor, tente novamente.',
        isError: true,
      );
    }
  }
}
