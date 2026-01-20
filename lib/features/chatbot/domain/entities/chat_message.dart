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

/// Status de um anexo
enum AttachmentStatus { pending, processing, completed, failed }

/// Tipo de anexo
enum AttachmentType { image, audio }

/// Entidade representando um anexo no chat (imagem ou audio)
class ChatAttachment {
  final String id;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final AttachmentStatus status;
  final AttachmentType type;
  final String? aiAnalysis;
  final DateTime createdAt;
  final String? localPath;

  // Audio-specific fields
  final int? durationSeconds;
  final String? transcription;
  final DateTime? transcribedAt;
  final String? storagePath; // URL do Supabase Storage ou path relativo

  const ChatAttachment({
    required this.id,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    this.type = AttachmentType.image,
    this.aiAnalysis,
    required this.createdAt,
    this.localPath,
    this.durationSeconds,
    this.transcription,
    this.transcribedAt,
    this.storagePath,
  });

  /// Retorna URL para reprodução do áudio
  /// Se storagePath é URL completa (http), usa diretamente
  /// Senão, retorna null (será resolvido pelo endpoint do backend)
  String? get audioPlayableUrl {
    if (storagePath != null && storagePath!.startsWith('http')) {
      return storagePath;
    }
    return null;
  }

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'] as String,
      originalName: json['originalName'] as String? ?? 'file',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      status: _parseStatus(json['status'] as String?),
      type: _parseType(json['type'] as String?),
      aiAnalysis: json['aiAnalysis'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      localPath: json['localPath'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      transcription: json['transcription'] as String?,
      transcribedAt: json['transcribedAt'] != null
          ? DateTime.parse(json['transcribedAt'] as String)
          : null,
      storagePath: json['storagePath'] as String?,
    );
  }

  static AttachmentStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
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

  static AttachmentType _parseType(String? type) {
    switch (type?.toUpperCase()) {
      case 'AUDIO':
        return AttachmentType.audio;
      case 'IMAGE':
      default:
        return AttachmentType.image;
    }
  }

  bool get isProcessing => status == AttachmentStatus.processing;
  bool get isCompleted => status == AttachmentStatus.completed;
  bool get isFailed => status == AttachmentStatus.failed;
  bool get isAudio => type == AttachmentType.audio;
  bool get isImage => type == AttachmentType.image;
  bool get hasTranscription => transcription != null && transcription!.isNotEmpty;

  /// Formatted duration string (e.g., "0:45")
  String get formattedDuration {
    if (durationSeconds == null) return '0:00';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
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

  // Status de leitura
  final DateTime? deliveredAt;
  final DateTime? readAt;

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
    this.deliveredAt,
    this.readAt,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasAudioAttachment => attachments.any((a) => a.isAudio);
  bool get hasImageAttachment => attachments.any((a) => a.isImage);

  /// Get the first audio attachment if exists
  ChatAttachment? get audioAttachment =>
      attachments.where((a) => a.isAudio).firstOrNull;

  /// Get the first image attachment if exists
  ChatAttachment? get imageAttachment =>
      attachments.where((a) => a.isImage).firstOrNull;

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

  /// Cria mensagem de audio do usuario
  factory ChatMessage.audioFromUser({
    required String attachmentId,
    required int durationSeconds,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '[Mensagem de áudio]',
      role: MessageRole.user,
      timestamp: DateTime.now(),
      attachments: [
        ChatAttachment(
          id: attachmentId,
          originalName: 'audio.m4a',
          mimeType: 'audio/m4a',
          sizeBytes: 0,
          status: AttachmentStatus.pending,
          type: AttachmentType.audio,
          createdAt: DateTime.now(),
          durationSeconds: durationSeconds,
        ),
      ],
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
