/// Entidade de dominio representando uma mensagem de chat
enum MessageRole { user, assistant, system }

/// Modo da conversa (Human Handoff)
enum ChatMode { ai, human, closed }

/// Converte string para ChatMode
ChatMode chatModeFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'HUMAN':
      return ChatMode.human;
    case 'CLOSED':
      return ChatMode.closed;
    default:
      return ChatMode.ai;
  }
}

/// Status de um anexo de imagem
enum AttachmentStatus { pending, processing, completed, failed }

/// Entidade representando um anexo de imagem no chat
class ChatAttachment {
  final String id;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final AttachmentStatus status;
  final String? aiAnalysis;
  final DateTime createdAt;
  final String? localPath;

  const ChatAttachment({
    required this.id,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    this.aiAnalysis,
    required this.createdAt,
    this.localPath,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'] as String,
      originalName: json['originalName'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int,
      status: _parseStatus(json['status'] as String),
      aiAnalysis: json['aiAnalysis'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      localPath: json['localPath'] as String?,
    );
  }

  static AttachmentStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AttachmentStatus.pending;
      case 'PROCESSING':
        return AttachmentStatus.processing;
      case 'COMPLETED':
        return AttachmentStatus.completed;
      case 'FAILED':
        return AttachmentStatus.failed;
      default:
        return AttachmentStatus.pending;
    }
  }

  bool get isProcessing => status == AttachmentStatus.processing;
  bool get isCompleted => status == AttachmentStatus.completed;
  bool get isFailed => status == AttachmentStatus.failed;
}

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isError;
  final List<ChatAttachment> attachments;

  // Human Handoff - identificacao do remetente
  final String? senderId;
  final String? senderType; // 'patient' | 'staff' | 'ai' | 'system'
  final String? senderName; // Nome do staff (para exibicao)

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isError = false,
    this.attachments = const [],
    this.senderId,
    this.senderType,
    this.senderName,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;
  bool get hasAttachments => attachments.isNotEmpty;

  // Human Handoff helpers
  bool get isFromStaff => senderType == 'staff';
  bool get isFromAi => senderType == 'ai' || (role == MessageRole.assistant && senderType == null);
  bool get isFromPatient => senderType == 'patient' || (role == MessageRole.user && senderType == null);
  bool get isSystemMessage => role == MessageRole.system;

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
