import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JobType, ChatAttachmentStatus } from '@prisma/client';
import { QueueService, JobPayload, JobResult } from '../queue.service';
import { PrismaService } from '../../../prisma/prisma.service';
import { WebsocketService } from '../../../websocket/websocket.service';
import { StorageService } from '../../storage/storage.service';
import OpenAI from 'openai';

export interface ImageAnalyzeJobPayload extends JobPayload {
  attachmentId: string;
  conversationId: string;
  patientId: string;
  imageUrl: string;
  userPrompt?: string;
}

@Injectable()
export class ImageAnalyzeProcessor implements OnModuleInit {
  private readonly logger = new Logger(ImageAnalyzeProcessor.name);
  private openai: OpenAI | null = null;

  constructor(
    private queueService: QueueService,
    private prisma: PrismaService,
    private websocketService: WebsocketService,
    private storageService: StorageService,
    private configService: ConfigService,
  ) {}

  onModuleInit() {
    const apiKey = this.configService.get<string>('OPENAI_API_KEY');
    if (apiKey) {
      this.openai = new OpenAI({ apiKey });
      this.logger.log('OpenAI Vision client initialized');
    } else {
      this.logger.warn('OpenAI API key not configured');
    }

    // Registra o handler no QueueService
    this.queueService.registerHandler(JobType.IMAGE_ANALYZE, this.process.bind(this));
  }

  async process(payload: ImageAnalyzeJobPayload): Promise<JobResult> {
    if (!this.openai) {
      throw new Error('OpenAI not configured');
    }

    const { attachmentId, conversationId, patientId, imageUrl, userPrompt } = payload;

    this.logger.log(`Processing image analysis for attachment ${attachmentId}`);

    // Atualiza status do attachment
    await this.prisma.chatAttachment.update({
      where: { id: attachmentId },
      data: { status: ChatAttachmentStatus.PROCESSING },
    });

    try {
      // Analisa a imagem com GPT-4 Vision
      const analysisPrompt = this.buildAnalysisPrompt(userPrompt);

      const completion = await this.openai.chat.completions.create({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: analysisPrompt },
              { type: 'image_url', image_url: { url: imageUrl } },
            ],
          },
        ],
        max_tokens: 1000,
      });

      const analysisResult = completion.choices[0]?.message?.content || 'Não foi possível analisar a imagem.';

      // Atualiza o attachment com o resultado
      await this.prisma.chatAttachment.update({
        where: { id: attachmentId },
        data: {
          status: ChatAttachmentStatus.COMPLETED,
          aiAnalysis: analysisResult,
          processedAt: new Date(),
        },
      });

      // Cria mensagem com o resultado da análise
      const aiMessage = await this.prisma.chatMessage.create({
        data: {
          conversationId,
          content: `📸 *Análise da imagem:*\n\n${analysisResult}`,
          role: 'assistant',
          senderType: 'ai',
        },
      });

      // Emite via WebSocket
      this.websocketService.emitToPatient(patientId, 'chat:message', {
        id: aiMessage.id,
        conversationId,
        content: aiMessage.content,
        role: 'assistant',
        senderType: 'ai',
        createdAt: aiMessage.createdAt.toISOString(),
        metadata: { type: 'image_analysis', attachmentId },
      });

      this.logger.log(`Image analysis completed for attachment ${attachmentId}`);

      return {
        messageId: aiMessage.id,
        analysis: analysisResult,
        tokensUsed: completion.usage?.total_tokens,
      };
    } catch (error) {
      // Atualiza status para erro
      await this.prisma.chatAttachment.update({
        where: { id: attachmentId },
        data: {
          status: ChatAttachmentStatus.FAILED,
          errorMessage: error instanceof Error ? error.message : 'Erro desconhecido',
        },
      });

      throw error;
    }
  }

  private buildAnalysisPrompt(userPrompt?: string): string {
    let prompt = `Você é um assistente médico especializado em analisar imagens relacionadas a pós-operatório.

Analise esta imagem considerando:
1. O que está sendo mostrado na imagem
2. Se há algo que parece preocupante ou fora do normal
3. Recomendações gerais baseadas na imagem

IMPORTANTE:
- Esta análise é apenas informativa e não substitui uma avaliação médica profissional
- Em caso de preocupação, sempre recomende contato com a equipe médica
- Seja descritivo mas evite causar alarme desnecessário
- Se a imagem não for clara ou não for possível analisar, informe isso`;

    if (userPrompt) {
      prompt += `\n\nO paciente perguntou especificamente: "${userPrompt}"`;
    }

    return prompt;
  }
}
