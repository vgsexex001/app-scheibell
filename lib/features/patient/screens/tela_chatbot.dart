import 'dart:async';
import 'package:flutter/material.dart';

// Enums para tipos de mensagem
enum TipoMensagem { texto, audio, foto }
enum RemetenteMensagem { usuario, assistente }

// Classe de mensagem
class Mensagem {
  final String conteudo;
  final String horario;
  final TipoMensagem tipo;
  final RemetenteMensagem remetente;
  final int? duracaoAudio;
  final String? caminhoFoto;

  Mensagem({
    required this.conteudo,
    required this.horario,
    required this.tipo,
    required this.remetente,
    this.duracaoAudio,
    this.caminhoFoto,
  });
}

class TelaChatbot extends StatefulWidget {
  const TelaChatbot({super.key});

  @override
  State<TelaChatbot> createState() => _TelaChatbotState();
}

class _TelaChatbotState extends State<TelaChatbot> with TickerProviderStateMixin {
  // Cores padrão do aplicativo
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _primaryDark = Color(0xFF4F4A34);
  static const _statusOnline = Color(0xFF05DF72); // Verde online
  static const _bubbleBot = Colors.white;
  static const _bubbleUser = Color(0xFFE8DEB5); // Bege/amarelo claro
  static const _cardSupport = Color(0xFFF0EDE5); // Bege claro
  static const _backgroundColor = Color(0xFFF5F5F5);
  static const _textPrimary = Color(0xFF333333);
  static const _textSecondary = Color(0xFF666666);
  static const _textTertiary = Color(0xFF999999);
  static const _borderChip = Color(0xFFE0E0E0);
  static const _inputBackground = Color(0xFFF5F5F5);

  // Cores para navbar
  static const _navInactive = Color(0xFF697282);
  static const _textPrimaryNav = Color(0xFF212621);

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Mensagem> _mensagens = [];
  bool _estaDigitando = false;
  bool _estaGravando = false;
  int _duracaoGravacao = 0;
  Timer? _timerGravacao;
  late AnimationController _animationController;
  bool _mostrarTooltipSuporte = true;

  // Perguntas rápidas pré-definidas
  final List<String> _perguntasRapidas = [
    'O que posso comer?',
    'Quando posso dirigir?',
    'Medicação',
    'Dor no local',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Mensagem inicial
    _mensagens.add(Mensagem(
      conteudo: 'Olá! Sou sua assistente virtual.\nComo posso ajudar você hoje?',
      horario: '14:30',
      tipo: TipoMensagem.texto,
      remetente: RemetenteMensagem.assistente,
    ));

    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _timerGravacao?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _getHorarioAtual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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

  String _getRespostaAssistente(String pergunta) {
    final q = pergunta.toLowerCase();
    if (q.contains('comer')) {
      return 'Nos primeiros dias, prefira alimentos leves e de fácil digestão. Evite alimentos muito condimentados ou gordurosos. Beba bastante água!';
    } else if (q.contains('dirigir')) {
      return 'Geralmente, você pode voltar a dirigir após 7-10 dias, dependendo do tipo de procedimento. Consulte seu médico para orientação específica.';
    } else if (q.contains('medicação') || q.contains('remédio')) {
      return 'Tome os medicamentos conforme prescrição médica. Não interrompa o tratamento sem orientação. Se tiver dúvidas, entre em contato com a clínica.';
    } else if (q.contains('dor')) {
      return 'Algum desconforto é normal nos primeiros dias. Se a dor for intensa ou persistente, entre em contato com seu médico imediatamente.';
    }
    return 'Entendi sua dúvida. Para uma orientação mais precisa, recomendo entrar em contato com nossa equipe médica.';
  }

  void _enviarMensagem() {
    final texto = _textController.text.trim();
    if (texto.isEmpty) return;

    final horario = _getHorarioAtual();
    setState(() {
      _mensagens.add(Mensagem(
        conteudo: texto,
        horario: horario,
        tipo: TipoMensagem.texto,
        remetente: RemetenteMensagem.usuario,
      ));
      _estaDigitando = true;
    });
    _textController.clear();
    _scrollParaFim();

    // Simular resposta da IA
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _estaDigitando = false;
          _mensagens.add(Mensagem(
            conteudo: _getRespostaAssistente(texto),
            horario: _getHorarioAtual(),
            tipo: TipoMensagem.texto,
            remetente: RemetenteMensagem.assistente,
          ));
        });
        _scrollParaFim();
      }
    });
  }

  void _enviarPerguntaRapida(String pergunta) {
    final horario = _getHorarioAtual();
    setState(() {
      _mensagens.add(Mensagem(
        conteudo: pergunta,
        horario: horario,
        tipo: TipoMensagem.texto,
        remetente: RemetenteMensagem.usuario,
      ));
      _estaDigitando = true;
    });
    _scrollParaFim();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _estaDigitando = false;
          _mensagens.add(Mensagem(
            conteudo: _getRespostaAssistente(pergunta),
            horario: _getHorarioAtual(),
            tipo: TipoMensagem.texto,
            remetente: RemetenteMensagem.assistente,
          ));
        });
        _scrollParaFim();
      }
    });
  }

  void _iniciarGravacao() {
    setState(() {
      _estaGravando = true;
      _duracaoGravacao = 0;
    });
    _timerGravacao = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duracaoGravacao++;
      });
    });
  }

  void _pararGravacao() {
    _timerGravacao?.cancel();
    if (_duracaoGravacao > 0) {
      _enviarAudio();
    }
    setState(() {
      _estaGravando = false;
    });
  }

  void _enviarAudio() {
    final horario = _getHorarioAtual();
    setState(() {
      _mensagens.add(Mensagem(
        conteudo: 'Áudio de $_duracaoGravacao segundos',
        horario: horario,
        tipo: TipoMensagem.audio,
        remetente: RemetenteMensagem.usuario,
        duracaoAudio: _duracaoGravacao,
      ));
      _estaDigitando = true;
    });
    _scrollParaFim();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _estaDigitando = false;
          _mensagens.add(Mensagem(
            conteudo: 'Ouvi seu áudio! Entendi que você está preocupado com o inchaço. Isso é completamente normal no pós-operatório. O pico de edema ocorre entre 2-3 dias e reduz gradualmente. Continue seguindo as orientações!',
            horario: _getHorarioAtual(),
            tipo: TipoMensagem.texto,
            remetente: RemetenteMensagem.assistente,
          ));
        });
        _scrollParaFim();
      }
    });
  }

  void _mostrarModalAnexo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enviar anexo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 20),
            _buildOpcaoAnexo(
              icone: Icons.camera_alt_outlined,
              titulo: 'Tirar foto',
              subtitulo: 'Capturar imagem com câmera',
              onTap: () {
                Navigator.pop(context);
                _enviarFoto();
              },
            ),
            const SizedBox(height: 12),
            _buildOpcaoAnexo(
              icone: Icons.photo_library_outlined,
              titulo: 'Escolher da galeria',
              subtitulo: 'Selecionar foto existente',
              onTap: () {
                Navigator.pop(context);
                _enviarFoto();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoAnexo({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _inputBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primaryDark.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, size: 24, color: _primaryDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textTertiary),
          ],
        ),
      ),
    );
  }

  void _enviarFoto() {
    final horario = _getHorarioAtual();
    setState(() {
      _mensagens.add(Mensagem(
        conteudo: 'Foto para análise',
        horario: horario,
        tipo: TipoMensagem.foto,
        remetente: RemetenteMensagem.usuario,
      ));
      _estaDigitando = true;
    });
    _scrollParaFim();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _estaDigitando = false;
          _mensagens.add(Mensagem(
            conteudo: 'Recebi sua foto! Estou analisando a imagem...\n\nBaseado na foto, observo que a recuperação está progredindo bem. O edema está dentro do esperado. Continue com as compressas frias e evite exposição solar direta.\n\nDeseja mais detalhes sobre algum aspecto específico?',
            horario: _getHorarioAtual(),
            tipo: TipoMensagem.texto,
            remetente: RemetenteMensagem.assistente,
          ));
        });
        _scrollParaFim();
      }
    });
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
            // FAB flutuante acima do card de input
            _buildFloatingSupportSection(),
            _buildInputArea(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// ==========================================
  /// HEADER - Gradiente padrão do app
  /// ==========================================
  Widget _buildHeader() {
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
          // Ícone do assistente
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
          // Título e status
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
                      decoration: const BoxDecoration(
                        color: _statusOnline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _estaGravando ? 'Gravando... ${_duracaoGravacao}s' : 'Online',
                      style: TextStyle(
                        color: _estaGravando ? Colors.red : _primaryDark.withOpacity(0.7),
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
          // Botão de menu/opções
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opções em breve!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Icon(
              Icons.more_vert,
              size: 24,
              color: _primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  /// ==========================================
  /// ÁREA DE MENSAGENS
  /// ==========================================
  Widget _buildMessagesArea() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensagens
          ..._mensagens.map((msg) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMessageBubble(msg),
          )),

          // Indicador de digitação
          if (_estaDigitando) _buildDigitando(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// ==========================================
  /// BOLHA DE MENSAGEM - Estilo balão de fala
  /// ==========================================
  Widget _buildMessageBubble(Mensagem message) {
    final isBot = message.remetente == RemetenteMensagem.assistente;

    // Se for áudio do usuário
    if (message.tipo == TipoMensagem.audio && !isBot) {
      return _buildAudioBubble(message);
    }

    // Se for foto do usuário
    if (message.tipo == TipoMensagem.foto && !isBot) {
      return _buildPhotoBubble(message);
    }

    return Column(
      crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        // Label "Assistente IA" (apenas para mensagens do bot)
        if (isBot) ...[
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
                'Assistente IA',
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
        ],

        // Bolha com pontinha
        Row(
          mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBot) _buildBubbleTail(isBot: true),

            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? _bubbleBot : _bubbleUser,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isBot ? 4 : 20),
                  topRight: Radius.circular(isBot ? 20 : 4),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.conteudo,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),

            if (!isBot) _buildBubbleTail(isBot: false),
          ],
        ),

        // Horário
        Padding(
          padding: EdgeInsets.only(
            top: 4,
            left: isBot ? 12 : 0,
            right: isBot ? 0 : 12,
          ),
          child: Text(
            message.horario,
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

  /// Bolha de áudio
  Widget _buildAudioBubble(Mensagem message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bubbleUser,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(4),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _primaryDark,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  _buildWaveform(),
                  const SizedBox(width: 10),
                  Text(
                    '0:${message.duracaoAudio?.toString().padLeft(2, '0') ?? '00'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            _buildBubbleTail(isBot: false),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 12),
          child: Text(
            message.horario,
            style: const TextStyle(
              color: _textTertiary,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  /// Bolha de foto
  Widget _buildPhotoBubble(Mensagem message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _bubbleUser,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(4),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7D1C5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 40, color: _textSecondary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.conteudo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            _buildBubbleTail(isBot: false),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 12),
          child: Text(
            message.horario,
            style: const TextStyle(
              color: _textTertiary,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    final alturas = [8, 17, 8, 20, 12, 10, 9, 15, 10, 7, 6, 6, 13, 18, 18, 16, 11, 7];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: alturas.map((altura) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        width: 2,
        height: altura.toDouble(),
        decoration: BoxDecoration(
          color: _primaryDark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(999),
        ),
      )).toList(),
    );
  }

  /// Pontinha do balão de fala
  Widget _buildBubbleTail({required bool isBot}) {
    return CustomPaint(
      size: const Size(8, 12),
      painter: BubbleTailPainter(
        isBot: isBot,
        color: isBot ? _bubbleBot : _bubbleUser,
      ),
    );
  }

  /// Indicador de digitação
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

  /// ==========================================
  /// SEÇÃO FLUTUANTE DE SUPORTE (acima do card de input)
  /// ==========================================
  Widget _buildFloatingSupportSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tooltip com texto
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
                    // Balão de texto
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Não encontrou o que queria?',
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
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.close,
                            size: 14,
                            color: _textTertiary,
                          ),
                        ],
                      ),
                    ),
                    // Setinha apontando para a direita (para o FAB)
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
          // FAB verde
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

  /// ==========================================
  /// SEÇÃO DE PERGUNTAS RÁPIDAS
  /// ==========================================
  Widget _buildQuickQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perguntas rápidas:',
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

  /// ==========================================
  /// ÁREA DE INPUT - Com perguntas rápidas em cima
  /// ==========================================
  Widget _buildInputArea() {
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
          // Perguntas rápidas
          _buildQuickQuestionsSection(),

          const SizedBox(height: 12),

          // Row de input
          Row(
            children: [
              // Botão de anexo (+)
              GestureDetector(
                onTap: _mostrarModalAnexo,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _inputBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 24,
                    color: _textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Campo de texto
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _inputBackground,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Digite sua mensagem...',
                            hintStyle: TextStyle(
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
                          onSubmitted: (_) => _enviarMensagem(),
                        ),
                      ),
                      // Botão de microfone
                      GestureDetector(
                        onLongPressStart: (_) => _iniciarGravacao(),
                        onLongPressEnd: (_) => _pararGravacao(),
                        child: Icon(
                          _estaGravando ? Icons.mic : Icons.mic_none,
                          size: 22,
                          color: _estaGravando ? Colors.red : _textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botão de enviar
              GestureDetector(
                onTap: _enviarMensagem,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _textController.text.isEmpty
                        ? _primaryDark.withOpacity(0.5)
                        : _primaryDark,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Disclaimer
          const Text(
            'Respostas geradas por IA • Para emergências, ligue para a clínica',
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
  }

  /// ==========================================
  /// BOTTOM NAV BAR
  /// ==========================================
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(69),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', false, () {
            Navigator.pushReplacementNamed(context, '/home');
          }),
          _buildNavItem(Icons.chat_bubble_outline, 'Chatbot', true, () {}),
          _buildNavItem(Icons.favorite_border, 'Recuperação', false, () {
            Navigator.pushReplacementNamed(context, '/recuperacao');
          }),
          _buildNavItem(Icons.calendar_today, 'Agenda', false, () {
            Navigator.pushReplacementNamed(context, '/agenda');
          }),
          _buildNavItem(Icons.person_outline, 'Perfil', false, () {
            Navigator.pushReplacementNamed(context, '/perfil');
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? _textPrimaryNav : _navInactive,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? _textPrimaryNav : _navInactive,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: _primaryDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(999),
                  topRight: Radius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ==========================================
/// CUSTOM PAINTER - Pontinha do balão
/// ==========================================
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
      // Pontinha à esquerda
      path.moveTo(size.width, 0);
      path.lineTo(0, 8);
      path.lineTo(size.width, 12);
    } else {
      // Pontinha à direita
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

/// ==========================================
/// CUSTOM PAINTER - Setinha do tooltip apontando para direita
/// ==========================================
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
    // Triângulo apontando para a direita
    path.moveTo(0, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(0, size.height);
    path.close();

    // Desenha sombra primeiro
    canvas.drawPath(path.shift(const Offset(1, 0)), shadowPaint);
    // Depois desenha o triângulo
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
