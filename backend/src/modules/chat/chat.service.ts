import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { SendMessageDto } from './dto';

interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

@Injectable()
export class ChatService {
  private readonly openaiApiKey: string;
  private readonly systemPrompt: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.openaiApiKey = this.configService.get<string>('OPENAI_API_KEY') || '';

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
  ): Promise<{ response: string; conversationId: string }> {
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

    // Salvar mensagem do usuário
    await this.prisma.chatMessage.create({
      data: {
        conversationId: conversation.id,
        role: 'user',
        content: dto.message,
      },
    });

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
    await this.prisma.chatMessage.create({
      data: {
        conversationId: conversation.id,
        role: 'assistant',
        content: responseText,
      },
    });

    // Atualizar timestamp da conversa
    await this.prisma.chatConversation.update({
      where: { id: conversation.id },
      data: { updatedAt: new Date() },
    });

    return {
      response: responseText,
      conversationId: conversation.id,
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

      if (!response.ok) {
        console.error('OpenAI API error:', response.status, await response.text());
        return this.getLocalResponse(messages[messages.length - 1].content);
      }

      const data = await response.json();
      return data.choices[0]?.message?.content || this.getLocalResponse(messages[messages.length - 1].content);
    } catch (error) {
      console.error('OpenAI API call failed:', error);
      return this.getLocalResponse(messages[messages.length - 1].content);
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
        include: { messages: { orderBy: { createdAt: 'asc' } } },
      });
      return conversation;
    }

    // Retorna a conversa mais recente
    const conversation = await this.prisma.chatConversation.findFirst({
      where: { patientId },
      orderBy: { updatedAt: 'desc' },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
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
}
