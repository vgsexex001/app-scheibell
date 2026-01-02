/// Entidade de dominio representando uma mensagem de chat
enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;

  /// Cria uma nova mensagem do usuario
  factory ChatMessage.fromUser(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  /// Cria uma nova mensagem do assistente
  factory ChatMessage.fromAssistant(String content, {bool isError = false}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isError: isError,
    );
  }

  /// Cria mensagem de sistema
  factory ChatMessage.system(String content) {
    return ChatMessage(
      id: 'system',
      content: content,
      role: MessageRole.system,
      timestamp: DateTime.now(),
    );
  }

  /// Converte para Map (para API OpenAI)
  Map<String, String> toApiMessage() {
    return {
      'role': role.name,
      'content': content,
    };
  }

  @override
  String toString() => 'ChatMessage(role: $role, content: $content)';
}
