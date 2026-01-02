import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { ChatService } from './chat.service';
import { SendMessageDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Request as ExpressRequest } from 'express';

interface AuthenticatedRequest extends ExpressRequest {
  user: {
    sub: string;
    email: string;
    role: string;
    patientId?: string;
    clinicId?: string;
  };
}

@Controller('chat')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  private getPatientId(req: AuthenticatedRequest): string {
    const patientId = req.user.patientId;
    if (!patientId) {
      throw new BadRequestException('Patient ID not found');
    }
    return patientId;
  }

  // POST /api/chat/send - Enviar mensagem
  @Post('send')
  @Roles('PATIENT')
  async sendMessage(
    @Request() req: AuthenticatedRequest,
    @Body() dto: SendMessageDto,
  ) {
    const patientId = this.getPatientId(req);
    return this.chatService.sendMessage(patientId, dto);
  }

  // GET /api/chat/history - Histórico de conversas
  @Get('history')
  @Roles('PATIENT')
  async getHistory(
    @Request() req: AuthenticatedRequest,
    @Query('conversationId') conversationId?: string,
  ) {
    const patientId = this.getPatientId(req);
    return this.chatService.getConversationHistory(patientId, conversationId);
  }

  // GET /api/chat/conversations - Lista de conversas
  @Get('conversations')
  @Roles('PATIENT')
  async getConversations(@Request() req: AuthenticatedRequest) {
    const patientId = this.getPatientId(req);
    return this.chatService.getConversations(patientId);
  }
}
