import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../chatbot/presentation/controller/chat_controller.dart';
import '../../chatbot/domain/entities/chat_message.dart';

class TelaChatbot extends StatefulWidget {
  const TelaChatbot({super.key});

  @override
  State<TelaChatbot> createState() => _TelaChatbotState();              
}

class _TelaChatbotState extends State<TelaChatbot> with TickerProviderStateMixin {
  // Cores padrao do aplicativo
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _primaryDark = Color(0xFF4F4A34);
  static const _statusOnline = Color(0xFF05DF72);
  static const _bubbleBot = Colors.white;
  static const _bubbleUser = Color(0xFFE8DEB5);
  static const _backgroundColor = Color(0xFFF5F5F5);
  static const _textPrimary = Color(0xFF333333);
  static const _textSecondary = Color(0xFF666666);
  static const _textTertiary = Color(0xFF999999);
  static const _borderChip = Color(0xFFE0E0E0);
  static const _inputBackground = Color(0xFFF5F5F5);
  static const _errorColor = Color(0xFFE57373);
  static const _humanModeColor = Color(0xFF3B82F6); // Azul para modo humano

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _animationController;
  bool _mostrarTooltipSuporte = true;

  final List<String> _perguntasRapidas = [
    'O que posso comer?',
    'Quando posso dirigir?',
    'Medicacao',
    'Dor no local',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _textController.addListener(() {
      setState(() {});
    });

    // Carrega o historico do chat do backend ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatController = context.read<ChatController>();
      if (!chatController.historyLoaded) {
        chatController.loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _scrollParaFim() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _enviarMensagem() {
    final texto = _textController.text.trim();
    if (texto.isEmpty) return;

    final chatController = context.read<ChatController>();
    chatController.sendMessage(texto);
    _textController.clear();
    _scrollParaFim();
  }

  void _enviarPerguntaRapida(String pergunta) {
    final chatController = context.read<ChatController>();
    chatController.sendQuickQuestion(pergunta);
    _scrollParaFim();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      final chatController = context.read<ChatController>();
      final file = File(image.path);

      // Valida e faz upload + analise
      final isValid = await chatController.setImageToSend(file);
      if (isValid) {
        await chatController.sendMessageWithImage(
          text: _textController.text.isNotEmpty ? _textController.text : null,
        );
        _textController.clear();
        _scrollParaFim();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildMessagesArea(),
            ),
            _buildFloatingSupportSection(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ChatController>(
      builder: (context, chatController, _) {
        final isHumanMode = chatController.isHumanMode;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHumanMode
                  ? [_humanModeColor.withOpacity(0.8), _humanModeColor.withOpacity(0.6)]
                  : [_gradientStart, _gradientEnd],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHumanMode ? Icons.support_agent : Icons.smart_toy_outlined,
                  size: 24,
                  color: isHumanMode ? Colors.white : _primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHumanMode ? 'Equipe de Suporte' : 'Assistente Inteligente',
                      style: TextStyle(
                        color: isHumanMode ? Colors.white : _primaryDark,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: chatController.isLoading || chatController.isLoadingHistory
                                ? Colors.orange
                                : (isHumanMode ? Colors.white : _statusOnline),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chatController.isLoadingHistory
                              ? 'Carregando...'
                              : chatController.isLoading
                                  ? 'Pensando...'
                                  : (isHumanMode ? 'Atendimento Humano' : 'Online'),
                          style: TextStyle(
                            color: isHumanMode
                                ? Colors.white.withOpacity(0.9)
                                : _primaryDark.withOpacity(0.7),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 24,
                  color: isHumanMode ? Colors.white : _primaryDark,
                ),
                onSelected: (value) {
                  if (value == 'limpar') {
                    chatController.clearHistory();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'limpar',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Limpar conversa'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesArea() {
    return Consumer<ChatController>(
      builder: (context, chatController, _) {
        // Se esta carregando historico, mostra loading
        if (chatController.isLoadingHistory) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryDark),
                ),
                SizedBox(height: 16),
                Text(
                  'Carregando historico...',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          );
        }

        // Scroll para o fim quando novas mensagens chegam
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollParaFim());

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...chatController.messages.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMessageBubble(msg),
              )),
              if (chatController.isLoading) _buildDigitando(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isBot = message.isAssistant;
    final isSystem = message.isSystem;
    final isFromStaff = message.isFromStaff;

    // Mensagens de sistema (handoff, etc)
    if (isSystem) {
      return _buildSystemMessage(message);
    }

    return Column(
      crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (isBot) ...[
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: message.isError
                      ? _errorColor.withOpacity(0.2)
                      : (isFromStaff ? _humanModeColor.withOpacity(0.2) : const Color(0xFFE8E8E8)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  message.isError
                      ? Icons.error_outline
                      : (isFromStaff ? Icons.support_agent : Icons.smart_toy_outlined),
                  size: 12,
                  color: message.isError
                      ? _errorColor
                      : (isFromStaff ? _humanModeColor : _textSecondary),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                message.isError
                    ? 'Erro'
                    : (isFromStaff ? (message.senderName ?? 'Equipe') : 'Assistente IA'),
                style: TextStyle(
                  color: message.isError
                      ? _errorColor
                      : (isFromStaff ? _humanModeColor : _textSecondary),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBot) _buildBubbleTail(isBot: true, isError: message.isError),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isError
                    ? _errorColor.withOpacity(0.1)
                    : (isBot ? _bubbleBot : _bubbleUser),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isBot ? 4 : 20),
                  topRight: Radius.circular(isBot ? 20 : 4),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                border: message.isError
                    ? Border.all(color: _errorColor.withOpacity(0.3))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Renderizar imagens se existirem attachments
                  if (message.hasAttachments) ...[
                    for (final attachment in message.attachments)
                      if (attachment.mimeType.startsWith('image/'))
                        _buildAttachmentImage(attachment),
                  ],
                  // So renderizar texto se nao for fallback de imagem E tiver conteudo
                  if (!_isImageFallbackText(message) && message.content.trim().isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: message.isError ? _errorColor : _textPrimary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  // Se conteudo vazio e sem imagem, mostrar erro generico
                  if (message.content.trim().isEmpty && !message.hasAttachments)
                    Text(
                      'Mensagem indisponivel',
                      style: TextStyle(
                        color: _errorColor.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (message.isError) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        context.read<ChatController>().retryLastMessage();
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 14, color: _primaryDark),
                          SizedBox(width: 4),
                          Text(
                            'Tentar novamente',
                            style: TextStyle(
                              fontSize: 12,
                              color: _primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isBot) _buildBubbleTail(isBot: false),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 4,
            left: isBot ? 12 : 0,
            right: isBot ? 0 : 12,
          ),
          child: Text(
            _formatTime(message.timestamp),
            style: const TextStyle(
              color: _textTertiary,
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBubbleTail({required bool isBot, bool isError = false}) {
    return CustomPaint(
      size: const Size(8, 12),
      painter: BubbleTailPainter(
        isBot: isBot,
        color: isError
            ? _errorColor.withOpacity(0.1)
            : (isBot ? _bubbleBot : _bubbleUser),
      ),
    );
  }

  Widget _buildAttachmentImage(ChatAttachment attachment) {
    // Usa path local se disponivel, senao usa URL do backend
    final imageUrl = attachment.localPath ??
        '${ApiConfig.baseUrl}/chat/attachments/${attachment.id}/file';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _showImageDialog(imageUrl, attachment.localPath),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 200,
              maxHeight: 200,
            ),
            child: attachment.localPath != null
                ? Image.file(
                    File(attachment.localPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImageErrorWidget();
                    },
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    headers: {
                      'Authorization': 'Bearer ${ApiService().currentToken}',
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 150,
                        color: _inputBackground,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_primaryDark),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImageErrorWidget();
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      width: 200,
      height: 100,
      color: _inputBackground,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: _textTertiary),
          SizedBox(height: 4),
          Text(
            'Nao foi possivel carregar',
            style: TextStyle(fontSize: 11, color: _textTertiary),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String imageUrl, String? localPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: localPath != null
                ? Image.file(
                    File(localPath),
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImageErrorWidget();
                    },
                  )
                : Image.network(
                    imageUrl,
                    headers: {'Authorization': 'Bearer ${ApiService().currentToken}'},
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImageErrorWidget();
                    },
                  ),
          ),
        ),
      ),
    );
  }

  /// Widget para mensagens de sistema (handoff, etc)
  Widget _buildSystemMessage(ChatMessage message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _humanModeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _humanModeColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              size: 16,
              color: _humanModeColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: const TextStyle(
                  color: _humanModeColor,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Verifica se o texto da mensagem e apenas um fallback de imagem
  /// e deve ser ocultado quando a imagem for renderizada
  bool _isImageFallbackText(ChatMessage message) {
    final content = message.content.trim();

    // Se nao tem attachments de imagem
    final hasImageAttachment = message.attachments.any(
      (a) => a.mimeType.startsWith('image/'),
    );
    if (!hasImageAttachment) {
      // Retorna true para esconder se conteudo vazio - fallback sera mostrado
      return content.isEmpty;
    }

    // Padroes de fallback a ocultar
    if (content.startsWith('[Imagem enviada:') && content.endsWith(']')) {
      return true;
    }

    // Se content esta vazio, nao precisa renderizar
    if (content.isEmpty) return true;

    // Caso contrario, e caption real - mostrar
    return false;
  }

  Widget _buildDigitando() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  size: 12,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Digitando...',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildBubbleTail(isBot: true),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _bubbleBot,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBolinha(0.68 + 0.32 * _getAnimValue(0)),
                        const SizedBox(width: 6),
                        _buildBolinha(0.58 + 0.42 * _getAnimValue(1)),
                        const SizedBox(width: 6),
                        _buildBolinha(0.51 + 0.49 * _getAnimValue(2)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getAnimValue(int index) {
    final value = (_animationController.value + index * 0.2) % 1.0;
    return (value < 0.5 ? value * 2 : 2 - value * 2);
  }

  Widget _buildBolinha(double opacidade) {
    return Opacity(
      opacity: opacidade.clamp(0.0, 1.0),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: _textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildFloatingSupportSection() {
    return Consumer<ChatController>(
      builder: (context, chatController, _) {
        // Ocultar botao se ja esta em modo humano
        if (chatController.isHumanMode) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_mostrarTooltipSuporte)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarTooltipSuporte = false;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Nao encontrou o que queria?',
                                    style: TextStyle(
                                      color: _textPrimary,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Fale com nossa equipe',
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 11,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.close,
                                size: 14,
                                color: _textTertiary,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: -6,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: CustomPaint(
                              size: const Size(8, 12),
                              painter: TooltipArrowRightPainter(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: chatController.isRequestingHandoff
                    ? null
                    : () async {
                        setState(() {
                          _mostrarTooltipSuporte = false;
                        });

                        // Mostrar dialog de confirmacao
                        final confirm = await _showHandoffConfirmDialog();
                        if (confirm == true && mounted) {
                          final success = await chatController.requestHandoff();
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Conectado com a equipe!'),
                                backgroundColor: _humanModeColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            _scrollParaFim();
                          } else if (!success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  chatController.errorMessage ??
                                      'Erro ao conectar com a equipe',
                                ),
                                backgroundColor: _errorColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _statusOnline,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _statusOnline.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: chatController.isRequestingHandoff
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.support_agent,
                          size: 24,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dialog de confirmacao para handoff
  Future<bool?> _showHandoffConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: _humanModeColor),
            SizedBox(width: 8),
            Text(
              'Falar com a equipe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          'Voce sera transferido para nossa equipe de atendimento.\n\n'
          'O assistente virtual nao respondera mais nesta conversa ate que o atendimento seja encerrado.\n\n'
          'Deseja continuar?',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _humanModeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Transferir'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perguntas rapidas:',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _perguntasRapidas.map((question) =>
            _buildQuickQuestionChip(question)
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickQuestionChip(String question) {
    return GestureDetector(
      onTap: () => _enviarPerguntaRapida(question),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _borderChip,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          question,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<ChatController>(
      builder: (context, chatController, _) {
        final isLoading = chatController.isLoading;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuickQuestionsSection(),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Botao de anexo de imagem
                  GestureDetector(
                    onTap: (isLoading || chatController.isUploading || chatController.isAnalyzing)
                        ? null
                        : _pickImage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _inputBackground,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: (chatController.isUploading || chatController.isAnalyzing)
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(_primaryDark),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_outlined,
                              size: 20,
                              color: _textTertiary,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _inputBackground,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _textController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          hintText: isLoading
                              ? 'Aguarde a resposta...'
                              : 'Digite sua mensagem...',
                          hintStyle: const TextStyle(
                            color: _textTertiary,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                        onSubmitted: isLoading ? null : (_) => _enviarMensagem(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isLoading ? null : _enviarMensagem,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (_textController.text.isEmpty || isLoading)
                            ? _primaryDark.withOpacity(0.5)
                            : _primaryDark,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              size: 20,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Respostas geradas por IA - Para emergencias, ligue para a clinica',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textTertiary,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  final bool isBot;
  final Color color;

  BubbleTailPainter({required this.isBot, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isBot) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 8);
      path.lineTo(size.width, 12);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 8);
      path.lineTo(0, 12);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TooltipArrowRightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path.shift(const Offset(1, 0)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
