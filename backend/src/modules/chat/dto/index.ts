import { IsString, IsNotEmpty, IsOptional, IsArray } from 'class-validator';

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
