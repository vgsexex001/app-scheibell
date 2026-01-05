import 'package:flutter/foundation.dart';
import '../../chatbot/domain/entities/chat_message.dart';
import '../../chatbot/data/datasources/openai_datasource.dart';

/// Estados possiveis do chat admin
enum AdminChatState { idle, loading, error }

/// Controller do chat IA para equipe clinica
/// Reutiliza OpenAiDatasource com system prompt especifico para admin
class AdminChatController extends ChangeNotifier {
  final OpenAiDatasource _datasource;

  /// System prompt especifico para equipe clinica
  static const String adminSystemPrompt = '''Voce e um assistente para a equipe clinica da Clinica Scheibel.

FUNCAO:
- Gerar sugestoes de resposta para pacientes no pos-operatorio
- Ajudar a equipe a criar mensagens claras e seguras

DIRETRIZES:
1. Seja claro, objetivo e profissional
2. Nunca faca diagnosticos medicos
3. Sempre recomende que o paciente entre em contato com a clinica em caso de:
   - Sangramento intenso
   - Febre alta
   - Dor intensa nao controlada
   - Dificuldade respiratoria
   - Qualquer sintoma preocupante
4. Use linguagem acolhedora mas tecnica
5. Respostas devem ser concisas (maximo 3-4 paragrafos)

FORMATO:
- Comece com saudacao breve
- Forneca a informacao solicitada
- Finalize com orientacao de seguranca quando aplicavel

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
        'Ola! Sou a assistente inteligente da Clinica Scheibel. Como posso ajudar voce hoje?',
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
