import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_gradientStart, _gradientEnd],
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
                child: const Icon(
                  Icons.smart_toy_outlined,
                  size: 24,
                  color: _primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assistente Inteligente',
                      style: TextStyle(
                        color: _primaryDark,
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
                            color: chatController.isLoading
                                ? Colors.orange
                                : _statusOnline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chatController.isLoading ? 'Pensando...' : 'Online',
                          style: TextStyle(
                            color: _primaryDark.withOpacity(0.7),
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
                icon: const Icon(
                  Icons.more_vert,
                  size: 24,
                  color: _primaryDark,
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
                      : const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  message.isError ? Icons.error_outline : Icons.smart_toy_outlined,
                  size: 12,
                  color: message.isError ? _errorColor : _textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                message.isError ? 'Erro' : 'Assistente IA',
                style: TextStyle(
                  color: message.isError ? _errorColor : _textSecondary,
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
            onTap: () {
              setState(() {
                _mostrarTooltipSuporte = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Conectando com equipe...'),
                  backgroundColor: _statusOnline,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
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
              child: const Icon(
                Icons.support_agent,
                size: 24,
                color: Colors.white,
              ),
            ),
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
