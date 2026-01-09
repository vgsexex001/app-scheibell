import { IsString, IsNotEmpty, IsOptional, IsArray, IsUUID, IsBoolean } from 'class-validator';

export class SendMessageDto {
  @IsString()
  @IsNotEmpty()
  message: string;

  @IsOptional()
  @IsString()
  conversationId?: string;
}

export class ChatMessageDto {
  role: 'user' | 'assistant' | 'system';
  content: string;
  createdAt?: Date;
}

export class ConversationDto {
  id: string;
  messages: ChatMessageDto[];
  createdAt: Date;
  updatedAt: Date;
}

// ==================== IMAGE UPLOAD DTOs ====================

export class UploadAttachmentDto {
  @IsOptional()
  @IsString()
  conversationId?: string;
}

export class ImageAnalyzeDto {
  @IsUUID()
  @IsNotEmpty()
  attachmentId: string;

  @IsOptional()
  @IsString()
  userPrompt?: string;
}

export class AttachmentResponseDto {
  id: string;
  conversationId: string;
  originalName: string;
  mimeType: string;
  sizeBytes: number;
  status: string;
  createdAt: Date;
}

export class ImageAnalyzeResponseDto {
  response: string;
  conversationId: string;
  messageId: string;
  attachmentId: string;
}

// ==================== HUMAN HANDOFF DTOs ====================

export class RequestHandoffDto {
  @IsOptional()
  @IsString()
  conversationId?: string;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class RequestHandoffResponseDto {
  conversationId: string;
  mode: string;
  handoffAt: string;
  alertId: string;
  message: string;
}

export class SendHumanMessageDto {
  @IsString()
  @IsNotEmpty()
  message: string;
}

export class CloseConversationDto {
  @IsOptional()
  @IsBoolean()
  returnToAi?: boolean;
}

export class ConversationWithModeDto {
  id: string;
  mode: string;
  handoffAt?: string;
  closedAt?: string;
  patientId: string;
  patientName?: string;
  lastMessage?: string;
  lastMessageAt?: string;
  lastMessageFrom?: string;
  createdAt: string;
  updatedAt: string;
}

export class AdminConversationsResponseDto {
  items: ConversationWithModeDto[];
  page: number;
  limit: number;
  total: number;
}

export class ConversationStatusDto {
  conversationId: string;
  mode: string;
  handoffAt?: string;
  closedAt?: string;
}
