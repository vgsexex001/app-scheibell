import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JobType } from '@prisma/client';
import { QueueService, JobPayload, JobResult } from '../queue.service';
import { PrismaService } from '../../../prisma/prisma.service';
import { WebsocketService } from '../../../websocket/websocket.service';
import OpenAI from 'openai';

export interface ChatAiJobPayload extends JobPayload {
  conversationId: string;
  userMessageId: string;
  patientId: string;
  messageContent: string;
  patientContext?: {
    name: string;
    surgeryType?: string;
    surgeryDate?: string;
  };
}

@Injectable()
export class ChatAiProcessor implements OnModuleInit {
  private readonly logger = new Logger(ChatAiProcessor.name);
  private openai: OpenAI | null = null;

  constructor(
    private queueService: QueueService,
    private prisma: PrismaService,
    private websocketService: WebsocketService,
    private configService: ConfigService,
  ) {}

  onModuleInit() {
    const apiKey = this.configService.get<string>('OPENAI_API_KEY');
    if (apiKey) {
      this.openai = new OpenAI({ apiKey });
      this.logger.log('OpenAI client initialized');
    } else {
      this.logger.warn('OpenAI API key not configured');
    }

    // Registra o handler no QueueService
    this.queueService.registerHandler(JobType.CHAT_AI_REPLY, this.process.bind(this));
  }

  async process(payload: ChatAiJobPayload): Promise<JobResult> {
    if (!this.openai) {
      throw new Error('OpenAI not configured');
    }

    const { conversationId, userMessageId, patientId, messageContent, patientContext } = payload;

    this.logger.log(`Processing AI reply for conversation ${conversationId}`);

    // Busca histórico recente da conversa para contexto
    const recentMessages = await this.prisma.chatMessage.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    // Monta o prompt do sistema
    const systemPrompt = this.buildSystemPrompt(patientContext);

    // Monta as mensagens para a API
    const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
      { role: 'system', content: systemPrompt },
      ...recentMessages.reverse().map(msg => ({
        role: msg.role === 'user' ? 'user' as const : 'assistant' as const,
        content: msg.content,
      })),
    ];

    // Chama a API da OpenAI
    const completion = await this.openai.chat.completions.create({
      model: this.configService.get('OPENAI_MODEL') || 'gpt-4o-mini',
      messages,
      max_tokens: 1000,
      temperature: 0.7,
    });

    const aiResponse = completion.choices[0]?.message?.content || 'Desculpe, não consegui processar sua mensagem.';

    // Salva a resposta da IA no banco
    const aiMessage = await this.prisma.chatMessage.create({
      data: {
        conversationId,
        content: aiResponse,
        role: 'assistant',
        senderType: 'ai',
      },
    });

    // Atualiza a conversa
    await this.prisma.chatConversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    // Emite via WebSocket para o paciente
    this.websocketService.emitToPatient(patientId, 'chat:message', {
      id: aiMessage.id,
      conversationId,
      content: aiResponse,
      role: 'assistant',
      senderType: 'ai',
      createdAt: aiMessage.createdAt.toISOString(),
    });

    this.logger.log(`AI reply sent for conversation ${conversationId}`);

    return {
      messageId: aiMessage.id,
      tokensUsed: completion.usage?.total_tokens,
    };
  }

  private buildSystemPrompt(patientContext?: ChatAiJobPayload['patientContext']): string {
    let prompt = `Você é um assistente de saúde virtual especializado em acompanhamento pós-operatório.
Seu papel é ajudar pacientes em recuperação de cirurgias, fornecendo:
- Orientações gerais sobre cuidados pós-operatórios
- Respostas a dúvidas comuns sobre medicamentos e sintomas
- Encorajamento e suporte emocional
- Lembretes sobre a importância de seguir o protocolo de recuperação

IMPORTANTE:
- Nunca forneça diagnósticos médicos
- Em casos de emergência ou sintomas graves, sempre recomende contato imediato com a equipe médica
- Seja empático e acolhedor
- Mantenha respostas concisas e claras
- Se não souber a resposta, admita e sugira contato com a equipe médica`;

    if (patientContext) {
      prompt += `\n\nContexto do paciente:`;
      if (patientContext.name) {
        prompt += `\n- Nome: ${patientContext.name}`;
      }
      if (patientContext.surgeryType) {
        prompt += `\n- Tipo de cirurgia: ${patientContext.surgeryType}`;
      }
      if (patientContext.surgeryDate) {
        prompt += `\n- Data da cirurgia: ${patientContext.surgeryDate}`;
      }
    }

    return prompt;
  }
}
