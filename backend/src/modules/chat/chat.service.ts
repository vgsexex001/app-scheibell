import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { StorageService } from './storage.service';
import { WebsocketService } from '../../websocket/websocket.service';
import {
  SendMessageDto,
  ImageAnalyzeDto,
  AttachmentResponseDto,
  ImageAnalyzeResponseDto,
  RequestHandoffDto,
  RequestHandoffResponseDto,
  ConversationStatusDto,
  ConversationWithModeDto,
  AdminConversationsResponseDto,
  SendHumanMessageDto,
} from './dto';
import { ChatAttachmentStatus, ChatMode } from '@prisma/client';

interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string | ContentPart[];
}

interface ContentPart {
  type: 'text' | 'image_url';
  text?: string;
  image_url?: {
    url: string;
    detail?: 'low' | 'high' | 'auto';
  };
}

@Injectable()
export class ChatService {
  private readonly openaiApiKey: string;
  private readonly systemPrompt: string;
  private readonly visionSystemPrompt: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly websocketService: WebsocketService,
  ) {
    this.openaiApiKey = this.configService.get<string>('OPENAI_API_KEY') || '';

    this.visionSystemPrompt = `Você é uma assistente virtual especializada em acompanhamento pós-operatório de cirurgias bariátricas e estéticas, com capacidade de analisar imagens.

Ao analisar imagens do paciente:
- Descreva objetivamente o que você observa na imagem
- Identifique possíveis sinais que mereçam atenção médica
- NUNCA faça diagnósticos definitivos
- SEMPRE recomende confirmação com a equipe médica para qualquer preocupação
- Seja empática e tranquilizadora, mas honesta sobre limitações

Se a imagem mostrar:
- Incisões/cicatrizes: comente sobre aparência geral (vermelhidão, inchaço, secreção)
- Hematomas: descreva cor e extensão aproximada
- Inchaço: note a localização e intensidade aparente
- Outros sintomas visíveis: descreva de forma clara

Importante: Esta análise é apenas para orientação. Qualquer preocupação deve ser discutida com o médico responsável.`;

    this.systemPrompt = `Você é uma assistente virtual especializada em acompanhamento pós-operatório de cirurgias bariátricas e estéticas.

Seu papel é:
- Responder dúvidas sobre recuperação pós-cirúrgica
- Dar orientações sobre alimentação, medicação e cuidados
- Identificar sinais de alerta e recomendar contato com a equipe médica quando necessário
- Ser empática, acolhedora e transmitir confiança

Regras importantes:
- NUNCA faça diagnósticos médicos
- SEMPRE recomende contato com a clínica em casos de emergência
- Mantenha respostas concisas (máximo 3-4 frases quando possível)
- Use linguagem simples e acessível
- Seja carinhosa mas profissional

Informações sobre pós-operatório comum:
- Primeiros dias: repouso, alimentação líquida, medicação conforme prescrição
- Primeira semana: início de alimentos pastosos, caminhadas leves
- Após 7-10 dias: retorno gradual a atividades, ainda sem esforço físico
- Inchaço e desconforto leve são normais nos primeiros dias
- Sinais de alerta: febre alta, dor intensa, sangramento, falta de ar`;
  }

  async sendMessage(
    patientId: string,
    dto: SendMessageDto,
  ): Promise<{ response: string | null; conversationId: string; mode: string }> {
    // Buscar ou criar conversa
    let conversation = dto.conversationId
      ? await this.prisma.chatConversation.findUnique({
          where: { id: dto.conversationId },
          include: { messages: { orderBy: { createdAt: 'asc' }, take: 20 } },
        })
      : null;

    if (!conversation) {
      conversation = await this.prisma.chatConversation.create({
        data: {
          patientId,
        },
        include: { messages: true },
      });
    }

    // Buscar userId do paciente para senderId
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { userId: true },
    });

    // Salvar mensagem do usuário
    const userMessage = await this.prisma.chatMessage.create({
      data: {
        conversationId: conversation.id,
        role: 'user',
        content: dto.message,
        senderId: patient?.userId,
        senderType: 'patient',
      },
    });

    // Emitir mensagem via WebSocket
    this.websocketService.notifyNewMessage(conversation.id, {
      id: userMessage.id,
      conversationId: conversation.id,
      role: 'user',
      content: dto.message,
      senderId: patient?.userId,
      senderType: 'patient',
      createdAt: userMessage.createdAt.toISOString(),
    });

    // Atualizar timestamp da conversa
    await this.prisma.chatConversation.update({
      where: { id: conversation.id },
      data: { updatedAt: new Date() },
    });

    // HUMAN HANDOFF: Se não está em modo AI, não chamar OpenAI
    if (conversation.mode !== 'AI') {
      console.log(`[Chat] Conversation ${conversation.id} in ${conversation.mode} mode - skipping AI response`);
      return {
        response: null,
        conversationId: conversation.id,
        mode: conversation.mode,
      };
    }

    // Preparar histórico de mensagens para a API
    const messages: ChatMessage[] = [
      { role: 'system', content: this.systemPrompt },
      ...conversation.messages.map((m) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
      { role: 'user', content: dto.message },
    ];

    // Chamar API OpenAI ou usar fallback local
    let responseText: string;

    if (this.openaiApiKey) {
      responseText = await this.callOpenAI(messages);
    } else {
      responseText = this.getLocalResponse(dto.message);
    }

    // Salvar resposta da IA
    const aiMessage = await this.prisma.chatMessage.create({
      data: {
        conversationId: conversation.id,
        role: 'assistant',
        content: responseText,
        senderType: 'ai',
      },
    });

    // Emitir resposta da IA via WebSocket
    this.websocketService.notifyNewMessage(conversation.id, {
      id: aiMessage.id,
      conversationId: conversation.id,
      role: 'assistant',
      content: responseText,
      senderType: 'ai',
      createdAt: aiMessage.createdAt.toISOString(),
    });

    return {
      response: responseText,
      conversationId: conversation.id,
      mode: conversation.mode,
    };
  }

  private async callOpenAI(messages: ChatMessage[]): Promise<string> {
    try {
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.openaiApiKey}`,
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages,
          max_tokens: 500,
          temperature: 0.7,
        }),
      });

      const lastContent = messages[messages.length - 1].content;
      const fallbackText = typeof lastContent === 'string' ? lastContent : '';

      if (!response.ok) {
        console.error('OpenAI API error:', response.status, await response.text());
        return this.getLocalResponse(fallbackText);
      }

      const data = await response.json();
      return data.choices[0]?.message?.content || this.getLocalResponse(fallbackText);
    } catch (error) {
      console.error('OpenAI API call failed:', error);
      const lastContent = messages[messages.length - 1].content;
      const fallbackText = typeof lastContent === 'string' ? lastContent : '';
      return this.getLocalResponse(fallbackText);
    }
  }

  private getLocalResponse(message: string): string {
    const q = message.toLowerCase();

    // Alimentação
    if (q.includes('comer') || q.includes('alimenta') || q.includes('comida') || q.includes('dieta')) {
      return 'Nos primeiros dias após a cirurgia, prefira alimentos líquidos e leves. Evite comidas gordurosas, condimentadas ou muito quentes. Beba bastante água ao longo do dia. Se tiver dúvidas específicas sobre sua dieta, consulte as orientações da clínica ou fale com nossa equipe!';
    }

    // Dirigir
    if (q.includes('dirigir') || q.includes('carro') || q.includes('direção')) {
      return 'Geralmente, você pode voltar a dirigir após 7-10 dias, dependendo do tipo de procedimento e como você está se sentindo. O importante é não estar tomando medicamentos que causem sonolência e conseguir fazer movimentos sem desconforto. Consulte seu médico para uma orientação personalizada.';
    }

    // Medicação
    if (q.includes('medicação') || q.includes('remédio') || q.includes('medicamento') || q.includes('tomar')) {
      return 'É muito importante seguir corretamente a prescrição médica. Tome os medicamentos nos horários indicados e não interrompa o tratamento sem orientação. Se sentir algum efeito colateral ou tiver dúvidas, entre em contato com a clínica.';
    }

    // Dor
    if (q.includes('dor') || q.includes('incômodo') || q.includes('desconforto') || q.includes('doendo')) {
      return 'Algum desconforto nos primeiros dias é esperado e normal. Siga a medicação para dor conforme prescrito. Porém, se a dor for muito intensa, não melhorar com a medicação, ou vier acompanhada de febre, entre em contato imediatamente com a clínica.';
    }

    // Inchaço/Edema
    if (q.includes('incha') || q.includes('edema') || q.includes('roxo') || q.includes('hematoma')) {
      return 'Inchaço e pequenos hematomas são normais no pós-operatório. O pico de edema costuma ocorrer entre 2-3 dias após a cirurgia e diminui gradualmente. Compressas frias podem ajudar. Se notar inchaço excessivo ou que piora muito, avise a equipe médica.';
    }

    // Atividade física
    if (q.includes('exercício') || q.includes('academia') || q.includes('físic') || q.includes('caminhada')) {
      return 'Caminhadas leves são recomendadas desde os primeiros dias para ajudar na circulação. Atividades mais intensas devem ser evitadas nas primeiras semanas. Seu médico indicará o momento certo para retomar exercícios regulares, geralmente após 3-4 semanas.';
    }

    // Trabalho
    if (q.includes('trabalho') || q.includes('voltar a trabalhar') || q.includes('trabalhar')) {
      return 'O retorno ao trabalho depende do tipo de atividade. Trabalhos leves podem ser retomados após 7-14 dias. Atividades que exijam esforço físico precisam de mais tempo. Converse com seu médico sobre sua situação específica.';
    }

    // Banho
    if (q.includes('banho') || q.includes('molhar') || q.includes('lavar')) {
      return 'Geralmente, banhos rápidos são liberados após 24-48 horas, evitando molhar diretamente os curativos. Banhos de banheira, piscina ou mar devem ser evitados nas primeiras semanas. Siga as orientações específicas que recebeu da clínica.';
    }

    // Sono/Dormir
    if (q.includes('dormir') || q.includes('sono') || q.includes('deitar') || q.includes('posição')) {
      return 'Nos primeiros dias, dormir com a cabeça elevada pode ajudar a reduzir o inchaço. Evite deitar sobre a região operada. Tente encontrar uma posição confortável e use travesseiros para apoio se necessário.';
    }

    // Emergência
    if (q.includes('urgente') || q.includes('emergência') || q.includes('grave') || q.includes('sangue') || q.includes('febre')) {
      return '⚠️ Se você está tendo febre alta, sangramento significativo, dor muito intensa, falta de ar ou qualquer sintoma que pareça grave, entre em contato IMEDIATAMENTE com a clínica ou procure uma emergência. Não espere!';
    }

    // Saudação
    if (q.includes('olá') || q.includes('oi') || q.includes('bom dia') || q.includes('boa tarde') || q.includes('boa noite')) {
      return 'Olá! Que bom falar com você! Como posso ajudar na sua recuperação hoje? Pode me perguntar sobre alimentação, medicação, cuidados ou qualquer dúvida sobre o pós-operatório.';
    }

    // Agradecimento
    if (q.includes('obrigad') || q.includes('valeu') || q.includes('agradeço')) {
      return 'Por nada! Fico feliz em ajudar. Se tiver mais alguma dúvida durante sua recuperação, estarei aqui. Desejo uma ótima recuperação! 💚';
    }

    // Resposta padrão
    return 'Entendi sua dúvida! Para uma orientação mais precisa sobre esse assunto, recomendo entrar em contato com nossa equipe médica. Eles poderão avaliar seu caso específico e dar as melhores recomendações. Posso ajudar com algo mais?';
  }

  async getConversationHistory(
    patientId: string,
    conversationId?: string,
  ): Promise<{ id: string; messages: any[] } | null> {
    if (conversationId) {
      const conversation = await this.prisma.chatConversation.findFirst({
        where: { id: conversationId, patientId },
        include: {
          messages: {
            orderBy: { createdAt: 'asc' },
            include: { attachments: true },
          },
        },
      });
      return conversation;
    }

    // Retorna a conversa mais recente
    const conversation = await this.prisma.chatConversation.findFirst({
      where: { patientId },
      orderBy: { updatedAt: 'desc' },
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
          include: { attachments: true },
        },
      },
    });
    return conversation;
  }

  async getConversations(patientId: string): Promise<any[]> {
    return this.prisma.chatConversation.findMany({
      where: { patientId },
      orderBy: { updatedAt: 'desc' },
      include: {
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });
  }

  // ==================== IMAGE UPLOAD & ANALYSIS ====================

  /**
   * Upload an image attachment for a conversation
   */
  async uploadAttachment(
    patientId: string,
    clinicId: string,
    file: Express.Multer.File,
    conversationId?: string,
  ): Promise<AttachmentResponseDto> {
    // Validate file type
    if (!this.storageService.isValidImageMimeType(file.mimetype)) {
      throw new BadRequestException(
        'Formato de arquivo inválido. Apenas JPG, PNG e HEIC são permitidos.',
      );
    }

    // Validate file size (10MB max)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      throw new BadRequestException(
        'Arquivo muito grande. Tamanho máximo permitido: 10MB.',
      );
    }

    // Get or create conversation
    let conversation = conversationId
      ? await this.prisma.chatConversation.findFirst({
          where: { id: conversationId, patientId },
        })
      : null;

    if (!conversation) {
      conversation = await this.prisma.chatConversation.create({
        data: { patientId },
      });
    }

    // Save file to storage
    const storageResult = await this.storageService.saveFile(
      clinicId,
      patientId,
      conversation.id,
      file,
    );

    // Create attachment record
    const attachment = await this.prisma.chatAttachment.create({
      data: {
        conversationId: conversation.id,
        type: 'IMAGE',
        originalName: storageResult.originalName,
        storagePath: storageResult.storagePath,
        mimeType: storageResult.mimeType,
        sizeBytes: storageResult.sizeBytes,
        status: 'PENDING',
      },
    });

    return {
      id: attachment.id,
      conversationId: conversation.id,
      originalName: attachment.originalName,
      mimeType: attachment.mimeType,
      sizeBytes: attachment.sizeBytes,
      status: attachment.status,
      createdAt: attachment.createdAt,
    };
  }

  /**
   * Analyze an image using OpenAI Vision API
   */
  async analyzeImage(
    patientId: string,
    dto: ImageAnalyzeDto,
  ): Promise<ImageAnalyzeResponseDto> {
    // Find attachment and verify ownership
    const attachment = await this.prisma.chatAttachment.findUnique({
      where: { id: dto.attachmentId },
      include: {
        conversation: true,
      },
    });

    if (!attachment) {
      throw new NotFoundException('Anexo não encontrado.');
    }

    // Validar se conversation existe (proteção contra dados inconsistentes)
    if (!attachment.conversation) {
      throw new BadRequestException('Conversa associada ao anexo não encontrada.');
    }

    if (attachment.conversation.patientId !== patientId) {
      throw new ForbiddenException('Acesso negado a este anexo.');
    }

    if (attachment.status === 'PROCESSING') {
      throw new BadRequestException('Esta imagem já está sendo processada.');
    }

    // Update status to processing
    await this.prisma.chatAttachment.update({
      where: { id: attachment.id },
      data: { status: 'PROCESSING' },
    });

    try {
      // Read image as base64
      const base64Image = await this.storageService.readAsBase64(attachment.storagePath);

      // Get conversation history for context (last 10 messages)
      const history = await this.prisma.chatMessage.findMany({
        where: { conversationId: attachment.conversationId },
        orderBy: { createdAt: 'asc' },
        take: 10,
      });

      // Build user prompt
      const userPrompt = dto.userPrompt || 'Por favor, analise esta imagem e me diga o que você observa.';

      // LOG DE EVIDÊNCIA - texto + imagem
      console.log(`[CHAT_IMG] caption="${dto.userPrompt || ''}"`);
      console.log(`[CHAT_IMG] analyze payload question length=${userPrompt.length}`);

      // Create user message for image (content vazio se nao houver caption)
      // A imagem e representada pelo attachment, nao pelo texto
      const messageContent = dto.userPrompt?.trim() || '';

      const userMessage = await this.prisma.chatMessage.create({
        data: {
          conversationId: attachment.conversationId,
          role: 'user',
          content: messageContent,
        },
      });

      // Link attachment to message
      await this.prisma.chatAttachment.update({
        where: { id: attachment.id },
        data: { messageId: userMessage.id },
      });

      // Call OpenAI Vision API
      const aiResponse = await this.callOpenAIVision(
        base64Image,
        attachment.mimeType,
        userPrompt,
        history,
      );

      // Save AI response
      const assistantMessage = await this.prisma.chatMessage.create({
        data: {
          conversationId: attachment.conversationId,
          role: 'assistant',
          content: aiResponse,
        },
      });

      // Update attachment status to completed
      await this.prisma.chatAttachment.update({
        where: { id: attachment.id },
        data: {
          status: 'COMPLETED',
          aiAnalysis: aiResponse,
          processedAt: new Date(),
        },
      });

      // Update conversation timestamp
      await this.prisma.chatConversation.update({
        where: { id: attachment.conversationId },
        data: { updatedAt: new Date() },
      });

      return {
        response: aiResponse,
        conversationId: attachment.conversationId,
        messageId: assistantMessage.id,
        attachmentId: attachment.id,
      };
    } catch (error) {
      // Update attachment status to failed
      const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';

      await this.prisma.chatAttachment.update({
        where: { id: attachment.id },
        data: {
          status: 'FAILED',
          errorMessage: errorMessage,
          processedAt: new Date(),
        },
      });

      // Still save an error message in the chat
      await this.prisma.chatMessage.create({
        data: {
          conversationId: attachment.conversationId,
          role: 'assistant',
          content: 'Desculpe, não foi possível analisar a imagem no momento. Por favor, tente novamente ou entre em contato com a clínica.',
        },
      });

      throw new BadRequestException(
        'Erro ao analisar imagem. Por favor, tente novamente.',
      );
    }
  }

  /**
   * Call OpenAI Vision API with image
   * Includes 90-second timeout to prevent hanging requests
   */
  private async callOpenAIVision(
    base64Image: string,
    mimeType: string,
    userPrompt: string,
    history: { role: string; content: string }[],
  ): Promise<string> {
    if (!this.openaiApiKey) {
      console.log('[OpenAI Vision] No API key configured, using fallback');
      return this.getVisionFallbackResponse();
    }

    // Timeout de 90 segundos para chamada OpenAI Vision
    const controller = new AbortController();
    const timeoutId = setTimeout(() => {
      console.error('[OpenAI Vision] Request timeout after 90s, aborting...');
      controller.abort();
    }, 90000);

    try {
      const messages: any[] = [
        { role: 'system', content: this.visionSystemPrompt },
        ...history.map((m) => ({
          role: m.role,
          content: m.content,
        })),
        {
          role: 'user',
          content: [
            { type: 'text', text: userPrompt },
            {
              type: 'image_url',
              image_url: {
                url: `data:${mimeType};base64,${base64Image}`,
                detail: 'high',
              },
            },
          ],
        },
      ];

      console.log('[OpenAI Vision] Sending request to API...');
      const startTime = Date.now();

      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.openaiApiKey}`,
        },
        body: JSON.stringify({
          model: 'gpt-4o', // Use gpt-4o for vision (not gpt-4o-mini)
          messages,
          max_tokens: 1000,
          temperature: 0.5,
        }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);
      const duration = Date.now() - startTime;

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[OpenAI Vision] API error: ${response.status} - ${errorText} (${duration}ms)`);
        return this.getVisionFallbackResponse();
      }

      const data = await response.json();
      const result = data.choices[0]?.message?.content || this.getVisionFallbackResponse();
      console.log(`[OpenAI Vision] Success in ${duration}ms`);
      return result;
    } catch (error: any) {
      clearTimeout(timeoutId);

      if (error.name === 'AbortError') {
        console.error('[OpenAI Vision] Request aborted due to timeout');
        throw new Error('Timeout ao processar imagem. A análise demorou muito. Tente novamente.');
      }

      console.error('[OpenAI Vision] API call failed:', error.message || error);
      return this.getVisionFallbackResponse();
    }
  }

  /**
   * Fallback response when Vision API is unavailable
   */
  private getVisionFallbackResponse(): string {
    return 'Recebi sua imagem! No momento não consigo analisá-la automaticamente, mas você pode descrevê-la para mim ou enviar diretamente para a equipe da clínica para uma avaliação profissional. Como posso ajudar de outra forma?';
  }

  /**
   * Get attachment by ID
   */
  async getAttachment(attachmentId: string, patientId: string) {
    const attachment = await this.prisma.chatAttachment.findUnique({
      where: { id: attachmentId },
      include: { conversation: true },
    });

    if (!attachment) {
      throw new NotFoundException('Anexo não encontrado.');
    }

    if (attachment.conversation.patientId !== patientId) {
      throw new ForbiddenException('Acesso negado.');
    }

    return attachment;
  }

  /**
   * Get attachment file path for serving
   */
  async getAttachmentFile(
    patientId: string,
    attachmentId: string,
  ): Promise<{ filePath: string; mimeType: string }> {
    const attachment = await this.getAttachment(attachmentId, patientId);
    const filePath = this.storageService.getFullPath(attachment.storagePath);
    return { filePath, mimeType: attachment.mimeType };
  }

  // ==================== HUMAN HANDOFF ====================

  /**
   * Request handoff to human team
   */
  async requestHandoff(
    patientId: string,
    dto: RequestHandoffDto,
  ): Promise<RequestHandoffResponseDto> {
    // Buscar paciente com clinicId e dados do usuário
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      include: {
        user: { select: { name: true } },
        clinic: { select: { id: true, name: true } },
      },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado.');
    }

    // Buscar ou criar conversa
    let conversation = dto.conversationId
      ? await this.prisma.chatConversation.findFirst({
          where: { id: dto.conversationId, patientId },
        })
      : await this.prisma.chatConversation.findFirst({
          where: { patientId },
          orderBy: { updatedAt: 'desc' },
        });

    if (!conversation) {
      conversation = await this.prisma.chatConversation.create({
        data: { patientId },
      });
    }

    // Se já está em modo HUMAN, retornar status atual
    if (conversation.mode === 'HUMAN') {
      return {
        conversationId: conversation.id,
        mode: 'HUMAN',
        handoffAt: conversation.handoffAt?.toISOString() || new Date().toISOString(),
        alertId: conversation.handoffAlertId || '',
        message: 'Você já está conectado com nossa equipe. Aguarde o atendimento.',
      };
    }

    // Se está CLOSED, reabrir como HUMAN
    // Se está AI, transferir para HUMAN

    const patientName = patient.user?.name || patient.name || 'Paciente';
    const now = new Date();

    // Criar Alert para notificar admin
    const alert = await this.prisma.alert.create({
      data: {
        clinicId: patient.clinicId,
        patientId: patientId,
        type: 'HUMAN_HANDOFF',
        title: 'Solicitação de Atendimento Humano',
        description: dto.reason
          ? `${patientName} solicitou atendimento humano. Motivo: ${dto.reason}`
          : `${patientName} solicitou atendimento humano no chat.`,
        isAutomatic: true,
      },
    });

    // Atualizar conversa para modo HUMAN
    const updatedConversation = await this.prisma.chatConversation.update({
      where: { id: conversation.id },
      data: {
        mode: 'HUMAN',
        handoffAt: now,
        handoffAlertId: alert.id,
        closedAt: null,
        closedBy: null,
      },
    });

    // Adicionar mensagem de sistema
    await this.prisma.chatMessage.create({
      data: {
        conversationId: conversation.id,
        role: 'system',
        content: 'Você foi transferido para nossa equipe de atendimento. Aguarde, em breve alguém irá atendê-lo.',
        senderType: 'system',
      },
    });

    console.log(`[Handoff] Patient ${patientId} requested handoff. Alert ${alert.id} created.`);

    // Notificar clínica via WebSocket
    this.websocketService.notifyHandoff(patient.clinicId, conversation.id, patientName);

    return {
      conversationId: updatedConversation.id,
      mode: 'HUMAN',
      handoffAt: now.toISOString(),
      alertId: alert.id,
      message: 'Transferência realizada com sucesso. Nossa equipe foi notificada e em breve entrará em contato.',
    };
  }

  /**
   * Get conversation status (mode)
   */
  async getConversationStatus(
    patientId: string,
    conversationId?: string,
  ): Promise<ConversationStatusDto | null> {
    const conversation = conversationId
      ? await this.prisma.chatConversation.findFirst({
          where: { id: conversationId, patientId },
        })
      : await this.prisma.chatConversation.findFirst({
          where: { patientId },
          orderBy: { updatedAt: 'desc' },
        });

    if (!conversation) {
      return null;
    }

    return {
      conversationId: conversation.id,
      mode: conversation.mode,
      handoffAt: conversation.handoffAt?.toISOString(),
      closedAt: conversation.closedAt?.toISOString(),
    };
  }

  /**
   * Admin: Get conversations in HUMAN mode for a clinic
   */
  async getHumanConversations(
    clinicId: string,
    page: number = 1,
    limit: number = 10,
    status?: 'HUMAN' | 'CLOSED',
  ): Promise<AdminConversationsResponseDto> {
    const skip = (page - 1) * limit;

    const whereClause = {
      patient: { clinicId },
      mode: status ? (status as ChatMode) : ('HUMAN' as ChatMode),
    };

    const [conversations, total] = await Promise.all([
      this.prisma.chatConversation.findMany({
        where: whereClause,
        include: {
          patient: {
            include: { user: { select: { name: true } } },
          },
          messages: {
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
        },
        orderBy: { handoffAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.chatConversation.count({ where: whereClause }),
    ]);

    const items: ConversationWithModeDto[] = conversations.map((conv) => {
      const lastMessage = conv.messages[0];
      return {
        id: conv.id,
        mode: conv.mode,
        handoffAt: conv.handoffAt?.toISOString(),
        closedAt: conv.closedAt?.toISOString(),
        patientId: conv.patientId,
        patientName: conv.patient.user?.name || conv.patient.name || 'Paciente',
        lastMessage: lastMessage?.content,
        lastMessageAt: lastMessage?.createdAt.toISOString(),
        lastMessageFrom: lastMessage?.senderType || (lastMessage?.role === 'user' ? 'patient' : 'ai'),
        createdAt: conv.createdAt.toISOString(),
        updatedAt: conv.updatedAt.toISOString(),
      };
    });

    return { items, page, limit, total };
  }

  /**
   * Admin: Get full conversation by ID
   */
  async getConversationForAdmin(
    conversationId: string,
    clinicId: string,
  ) {
    const conversation = await this.prisma.chatConversation.findUnique({
      where: { id: conversationId },
      include: {
        patient: {
          include: { user: { select: { name: true } } },
        },
        messages: {
          orderBy: { createdAt: 'asc' },
          include: { attachments: true },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversa não encontrada.');
    }

    if (conversation.patient.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a esta conversa.');
    }

    return {
      id: conversation.id,
      mode: conversation.mode,
      handoffAt: conversation.handoffAt?.toISOString(),
      closedAt: conversation.closedAt?.toISOString(),
      patientId: conversation.patientId,
      patientName: conversation.patient.user?.name || conversation.patient.name || 'Paciente',
      messages: conversation.messages.map((m) => ({
        id: m.id,
        role: m.role,
        content: m.content,
        senderId: m.senderId,
        senderType: m.senderType,
        createdAt: m.createdAt.toISOString(),
        attachments: m.attachments,
      })),
      createdAt: conversation.createdAt.toISOString(),
      updatedAt: conversation.updatedAt.toISOString(),
    };
  }

  /**
   * Admin: Send message as staff
   */
  async sendHumanMessage(
    conversationId: string,
    staffUserId: string,
    clinicId: string,
    message: string,
  ) {
    // Verificar conversa e permissão
    const conversation = await this.prisma.chatConversation.findUnique({
      where: { id: conversationId },
      include: { patient: true },
    });

    if (!conversation) {
      throw new NotFoundException('Conversa não encontrada.');
    }

    if (conversation.patient.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a esta conversa.');
    }

    // Buscar nome do staff
    const staffUser = await this.prisma.user.findUnique({
      where: { id: staffUserId },
      select: { name: true },
    });

    // Criar mensagem (usando role='assistant' para aparecer do lado do "bot" na UI)
    const chatMessage = await this.prisma.chatMessage.create({
      data: {
        conversationId,
        role: 'assistant',
        content: message,
        senderId: staffUserId,
        senderType: 'staff',
      },
    });

    // Atualizar timestamp da conversa
    await this.prisma.chatConversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    console.log(`[Handoff] Staff ${staffUserId} sent message to conversation ${conversationId}`);

    // Emitir mensagem via WebSocket
    this.websocketService.notifyNewMessage(conversationId, {
      id: chatMessage.id,
      conversationId,
      role: chatMessage.role,
      content: chatMessage.content,
      senderId: chatMessage.senderId,
      senderType: chatMessage.senderType,
      senderName: staffUser?.name || 'Equipe',
      createdAt: chatMessage.createdAt.toISOString(),
    });

    return {
      message: {
        id: chatMessage.id,
        role: chatMessage.role,
        content: chatMessage.content,
        senderId: chatMessage.senderId,
        senderType: chatMessage.senderType,
        createdAt: chatMessage.createdAt.toISOString(),
      },
      conversationId,
      senderName: staffUser?.name || 'Equipe',
    };
  }

  /**
   * Admin: Close conversation
   */
  async closeConversation(
    conversationId: string,
    staffUserId: string,
    clinicId: string,
    returnToAi: boolean = false,
  ) {
    // Verificar conversa e permissão
    const conversation = await this.prisma.chatConversation.findUnique({
      where: { id: conversationId },
      include: { patient: true },
    });

    if (!conversation) {
      throw new NotFoundException('Conversa não encontrada.');
    }

    if (conversation.patient.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a esta conversa.');
    }

    const newMode: ChatMode = returnToAi ? 'AI' : 'CLOSED';
    const now = new Date();

    // Atualizar conversa
    await this.prisma.chatConversation.update({
      where: { id: conversationId },
      data: {
        mode: newMode,
        closedAt: now,
        closedBy: staffUserId,
      },
    });

    // Mensagem de sistema
    const systemMessage = returnToAi
      ? 'Atendimento encerrado. Você foi redirecionado para o assistente virtual.'
      : 'Atendimento encerrado. Obrigado por entrar em contato com nossa equipe.';

    await this.prisma.chatMessage.create({
      data: {
        conversationId,
        role: 'system',
        content: systemMessage,
        senderType: 'system',
      },
    });

    // Resolver o Alert associado
    if (conversation.handoffAlertId) {
      await this.prisma.alert.update({
        where: { id: conversation.handoffAlertId },
        data: {
          status: 'RESOLVED',
          resolvedAt: now,
          resolvedBy: staffUserId,
        },
      });
    }

    console.log(`[Handoff] Conversation ${conversationId} closed by staff ${staffUserId}. Mode: ${newMode}`);

    // Notificar paciente via WebSocket
    this.websocketService.notifyConversationClosed(conversationId, conversation.patientId);

    return {
      success: true,
      mode: newMode,
      closedAt: now.toISOString(),
    };
  }
}
