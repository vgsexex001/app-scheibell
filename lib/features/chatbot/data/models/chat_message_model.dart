import '../../domain/entities/chat_message.dart';

/// Modelo de dados para mensagem de chat (conversao JSON)
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.content,
    required super.role,
    required super.timestamp,
    super.isError,
  });

  /// Cria modelo a partir de resposta da OpenAI API
  factory ChatMessageModel.fromOpenAiResponse(Map<String, dynamic> json) {
    final choice = json['choices']?[0];
    final message = choice?['message'];

    return ChatMessageModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: message?['content'] ?? '',
      role: _parseRole(message?['role'] ?? 'assistant'),
      timestamp: DateTime.now(),
    );
  }

  /// Cria modelo a partir de Map generico
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] ?? '',
      role: _parseRole(json['role'] ?? 'assistant'),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isError: json['isError'] ?? false,
    );
  }

  /// Converte para Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
    };
  }

  /// Cria modelo a partir de entidade de dominio
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      content: entity.content,
      role: entity.role,
      timestamp: entity.timestamp,
      isError: entity.isError,
    );
  }

  /// Converte para entidade de dominio
  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      content: content,
      role: role,
      timestamp: timestamp,
      isError: isError,
    );
  }

  static MessageRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.assistant;
    }
  }
}
