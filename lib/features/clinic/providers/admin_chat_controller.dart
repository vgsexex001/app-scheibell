import 'package:flutter/foundation.dart';
import '../../chatbot/domain/entities/chat_message.dart';
import '../../chatbot/data/datasources/openai_datasource.dart';

/// Estados possiveis do chat admin
enum AdminChatState { idle, loading, error }

/// Controller do chat IA para equipe clinica
/// Reutiliza OpenAiDatasource com system prompt especifico para admin
class AdminChatController extends ChangeNotifier {
  final OpenAiDatasource _datasource;

  /// System prompt especifico para equipe clinica (profissionais de saude)
  static const String adminSystemPrompt = '''Voce e um assistente inteligente para a equipe medica da Clinica Scheibell, especializada em cirurgia plastica e pos-operatorio.

IMPORTANTE: Voce esta AUXILIANDO a equipe da clinica a responder pacientes com ORIENTACOES UTEIS E PRATICAS. Voce faz parte da clinica e tem conhecimento sobre pos-operatorio.

SEU PAPEL:
Voce deve fornecer RESPOSTAS COMPLETAS E UTEIS para os pacientes, com orientacoes praticas baseadas em conhecimento medico de pos-operatorio. NAO apenas encaminhe para o medico - de orientacoes reais sempre que possivel.

CONHECIMENTOS QUE VOCE TEM SOBRE POS-OPERATORIO:

SINTOMAS NORMAIS (pode tranquilizar o paciente):
- Inchaco nos primeiros 7-14 dias e leve
- Hematomas (roxos) que mudam de cor e desaparecem em 2-3 semanas
- Leve desconforto ou sensibilidade na area operada
- Dificuldade para respirar pelo nariz nos primeiros dias (rinoplastia)
- Sensacao de "nariz entupido" por algumas semanas
- Dormencia temporaria na regiao
- Leve sangramento rosado nas primeiras 48h

CUIDADOS POS-OPERATORIOS (pode orientar diretamente):
- Manter cabeca elevada ao dormir (2-3 travesseiros)
- Aplicar compressas frias nos primeiros 2-3 dias (nao gelo direto)
- Evitar sol direto por 30-60 dias, usar protetor solar
- Nao assoar o nariz com forca por 2-3 semanas
- Evitar exercicios fisicos por 3-4 semanas
- Nao usar oculos apoiados no nariz por 4-6 semanas
- Alimentacao leve, evitar alimentos muito quentes ou duros
- Tomar medicacoes nos horarios prescritos
- Manter curativos limpos e secos

SINAIS DE ALERTA (encaminhar para avaliacao do doutor):
- Sangramento intenso e continuo
- Febre acima de 38°C
- Dor intensa que nao melhora com medicacao
- Secrecao com pus ou cheiro forte
- Inchaco que piora apos o 3o dia
- Dificuldade respiratoria severa

DIRETRIZES:
1. De ORIENTACOES PRATICAS E UTEIS primeiro
2. Escreva em PRIMEIRA PESSOA como equipe da clinica ("nossa equipe", "nosso doutor")
3. NUNCA sugira pronto-socorro ou outra clinica - nos somos a solucao
4. So encaminhe para o doutor quando for realmente necessario (sinais de alerta)
5. Seja acolhedora, profissional e INFORMATIVA

EXEMPLOS DE BOAS RESPOSTAS:

Paciente: "Estou com o nariz muito inchado, e normal?"
Resposta: "O inchaco nos primeiros dias e completamente normal e esperado! Ele vai diminuindo gradualmente ao longo das proximas semanas. Para ajudar, mantenha a cabeca elevada ao dormir e aplique compressas frias (nao gelo direto) por 10-15 minutos algumas vezes ao dia. Evite alimentos muito salgados tambem. Se precisar de mais alguma orientacao, estamos aqui!"

Paciente: "Posso tomar banho normal?"
Resposta: "Pode sim! So tome cuidado para nao molhar diretamente os curativos ou a area operada com jato forte de agua. Prefira banhos mornos e evite agua muito quente. Se tiver splint ou tampao nasal, proteja bem a regiao. Qualquer duvida, estamos a disposicao!"

Paciente: "Estou com sangramento"
Resposta: "Um leve sangramento rosado nas primeiras 48-72h pode ser normal. Mantenha a cabeca elevada e evite assoar o nariz. Se o sangramento for intenso, vermelho vivo e continuo, entre em contato conosco imediatamente que nosso doutor vai avaliar. Como esta o sangramento agora?"

FORMATO:
- Respostas completas com orientacoes praticas
- Tom acolhedor e profissional
- Primeira pessoa representando a clinica
- So encaminhe para medico quando necessario

Responda sempre em portugues brasileiro.''';

  AdminChatState _state = AdminChatState.idle;
  final List<ChatMessage> _messages = [];
  String? _errorMessage;

  AdminChatController({OpenAiDatasource? datasource})
      : _datasource = datasource ?? OpenAiDatasource();

  /// Estado atual do chat
  AdminChatState get state => _state;

  /// Lista de mensagens (somente leitura)
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Mensagem de erro atual
  String? get errorMessage => _errorMessage;

  /// Verifica se esta carregando
  bool get isLoading => _state == AdminChatState.loading;

  /// Adiciona mensagem inicial de boas-vindas
  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.fromAssistant(
        'Ola! Sou a assistente inteligente da equipe medica. Posso ajudar com:\n\n'
        '- Sugerir respostas para pacientes\n'
        '- Duvidas sobre protocolos pos-operatorios\n'
        '- Informacoes sobre medicacoes e cuidados\n'
        '- Identificar sinais de alerta em relatos\n\n'
        'Como posso ajudar voce hoje?',
      ));
      notifyListeners();
    }
  }

  /// Envia uma mensagem do usuario para a OpenAI
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Adiciona mensagem do usuario
    final userMessage = ChatMessage.fromUser(content.trim());
    _messages.add(userMessage);

    // Atualiza estado para loading
    _state = AdminChatState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Filtra apenas mensagens de usuario e assistente para enviar (nao erros)
      final messagesToSend = _messages
          .where((m) => !m.isError && !m.isSystem)
          .toList();

      // Chama OpenAI com system prompt admin
      final response = await _datasource.sendMessageWithCustomPrompt(
        messagesToSend,
        adminSystemPrompt,
      );

      // Adiciona resposta
      _messages.add(response);

      // Verifica se foi erro
      if (response.isError) {
        _state = AdminChatState.error;
        _errorMessage = response.content;
      } else {
        _state = AdminChatState.idle;
      }
    } on OpenAiException catch (e) {
      _state = AdminChatState.error;
      _errorMessage = e.userFriendlyMessage;
      _messages.add(ChatMessage.fromAssistant(
        e.userFriendlyMessage,
        isError: true,
      ));
    } catch (e) {
      _state = AdminChatState.error;
      _errorMessage = 'Erro ao enviar mensagem. Por favor, tente novamente.';
      _messages.add(ChatMessage.fromAssistant(
        'Desculpe, ocorreu um erro. Por favor, tente novamente.',
        isError: true,
      ));
    }

    notifyListeners();
  }

  /// Limpa o historico de mensagens
  void clearHistory() {
    _messages.clear();
    _state = AdminChatState.idle;
    _errorMessage = null;
    addWelcomeMessage();
    notifyListeners();
  }

  /// Reenvia a ultima mensagem do usuario (retry)
  Future<void> retryLastMessage() async {
    // Encontra a ultima mensagem do usuario
    final lastUserMessage = _messages.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage.fromUser(''),
    );

    if (lastUserMessage.content.isNotEmpty) {
      // Remove a ultima resposta de erro se houver
      if (_messages.isNotEmpty && _messages.last.isError) {
        _messages.removeLast();
      }
      // Remove a ultima mensagem do usuario para reenviar
      _messages.removeWhere((m) => m.id == lastUserMessage.id);
      notifyListeners();

      // Reenvia
      await sendMessage(lastUserMessage.content);
    }
  }
}
