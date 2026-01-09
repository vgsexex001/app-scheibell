import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  Param,
  Res,
  UseGuards,
  Request,
  BadRequestException,
  UploadedFile,
  UseInterceptors,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { ChatService } from './chat.service';
import {
  SendMessageDto,
  ImageAnalyzeDto,
  UploadAttachmentDto,
  RequestHandoffDto,
  SendHumanMessageDto,
  CloseConversationDto,
} from './dto';
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

  private getClinicId(req: AuthenticatedRequest): string {
    const clinicId = req.user.clinicId;
    if (!clinicId) {
      throw new BadRequestException('Clinic ID not found');
    }
    return clinicId;
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

  // ==================== IMAGE UPLOAD ENDPOINTS ====================

  // POST /api/chat/attachments - Upload de imagem
  @Post('attachments')
  @Roles('PATIENT')
  @UseInterceptors(FileInterceptor('file'))
  async uploadAttachment(
    @Request() req: AuthenticatedRequest,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 10 * 1024 * 1024 }), // 10MB
          new FileTypeValidator({ fileType: /^image\/(jpeg|png|heic|heif)$/ }),
        ],
        fileIsRequired: true,
      }),
    )
    file: Express.Multer.File,
    @Body() dto: UploadAttachmentDto,
  ) {
    const patientId = this.getPatientId(req);
    const clinicId = this.getClinicId(req);
    return this.chatService.uploadAttachment(
      patientId,
      clinicId,
      file,
      dto.conversationId,
    );
  }

  // POST /api/chat/image-analyze - Análise de imagem pela IA
  @Post('image-analyze')
  @Roles('PATIENT')
  async analyzeImage(
    @Request() req: AuthenticatedRequest,
    @Body() dto: ImageAnalyzeDto,
  ) {
    const patientId = this.getPatientId(req);
    return this.chatService.analyzeImage(patientId, dto);
  }

  // GET /api/chat/attachments/:id/file - Servir arquivo de imagem
  @Get('attachments/:id/file')
  @Roles('PATIENT')
  async getAttachmentFile(
    @Request() req: AuthenticatedRequest,
    @Param('id') attachmentId: string,
    @Res() res: Response,
  ) {
    const patientId = this.getPatientId(req);
    const { filePath, mimeType } = await this.chatService.getAttachmentFile(
      patientId,
      attachmentId,
    );

    res.setHeader('Content-Type', mimeType);
    res.setHeader('Cache-Control', 'private, max-age=3600'); // Cache 1h
    res.sendFile(filePath);
  }

  // ==================== HUMAN HANDOFF ENDPOINTS ====================

  // POST /api/chat/handoff - Solicitar transferência para atendimento humano
  @Post('handoff')
  @Roles('PATIENT')
  async requestHandoff(
    @Request() req: AuthenticatedRequest,
    @Body() dto: RequestHandoffDto,
  ) {
    const patientId = this.getPatientId(req);
    return this.chatService.requestHandoff(patientId, dto);
  }

  // GET /api/chat/conversation-status - Obter status/modo da conversa
  @Get('conversation-status')
  @Roles('PATIENT')
  async getConversationStatus(
    @Request() req: AuthenticatedRequest,
    @Query('conversationId') conversationId?: string,
  ) {
    const patientId = this.getPatientId(req);
    return this.chatService.getConversationStatus(patientId, conversationId);
  }

  // ==================== ADMIN/STAFF ENDPOINTS ====================

  // GET /api/chat/admin/conversations - Listar conversas em modo HUMAN
  @Get('admin/conversations')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getHumanConversations(
    @Request() req: AuthenticatedRequest,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('status') status?: 'HUMAN' | 'CLOSED',
  ) {
    const clinicId = this.getClinicId(req);
    return this.chatService.getHumanConversations(
      clinicId,
      parseInt(page || '1'),
      parseInt(limit || '10'),
      status,
    );
  }

  // GET /api/chat/admin/conversations/:id - Obter conversa completa
  @Get('admin/conversations/:id')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getConversationById(
    @Request() req: AuthenticatedRequest,
    @Param('id') conversationId: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.chatService.getConversationForAdmin(conversationId, clinicId);
  }

  // POST /api/chat/admin/conversations/:id/message - Enviar mensagem como staff
  @Post('admin/conversations/:id/message')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async sendHumanMessage(
    @Request() req: AuthenticatedRequest,
    @Param('id') conversationId: string,
    @Body() dto: SendHumanMessageDto,
  ) {
    const clinicId = this.getClinicId(req);
    const userId = req.user.sub;
    return this.chatService.sendHumanMessage(
      conversationId,
      userId,
      clinicId,
      dto.message,
    );
  }

  // POST /api/chat/admin/conversations/:id/close - Fechar conversa
  @Post('admin/conversations/:id/close')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async closeConversation(
    @Request() req: AuthenticatedRequest,
    @Param('id') conversationId: string,
    @Body() dto: CloseConversationDto,
  ) {
    const clinicId = this.getClinicId(req);
    const userId = req.user.sub;
    return this.chatService.closeConversation(
      conversationId,
      userId,
      clinicId,
      dto.returnToAi,
    );
  }
}
