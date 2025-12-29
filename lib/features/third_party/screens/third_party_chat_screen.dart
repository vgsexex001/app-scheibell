import 'package:flutter/material.dart';
import '../widgets/third_party_bottom_nav.dart';

class ThirdPartyChatScreen extends StatefulWidget {
  const ThirdPartyChatScreen({super.key});

  @override
  State<ThirdPartyChatScreen> createState() => _ThirdPartyChatScreenState();
}

class _ThirdPartyChatScreenState extends State<ThirdPartyChatScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Lista de conversas mock
  final List<_Conversa> _conversas = [
    _Conversa(
      id: '1',
      nome: 'Maria Silva',
      subtitulo: 'Rinoplastia • 7d pós-op',
      ultimaMensagem: 'Preciso de ajuda para responder sobre cuidados...',
      horario: '10:02',
      tipo: _TipoConversa.paciente,
      mensagensNaoLidas: 2,
      status: _StatusConversa.online,
    ),
    _Conversa(
      id: '2',
      nome: 'João Santos',
      subtitulo: 'Lipoaspiração • 14d pós-op',
      ultimaMensagem: 'Obrigado pela resposta!',
      horario: '09:45',
      tipo: _TipoConversa.paciente,
    ),
    _Conversa(
      id: '3',
      nome: 'Ana Costa',
      subtitulo: 'Mamoplastia • 3d pós-op',
      ultimaMensagem: 'Mensagem de voz',
      horario: '09:30',
      tipo: _TipoConversa.paciente,
      isAudio: true,
      duracaoAudio: '0:45',
      mensagensNaoLidas: 1,
    ),
    _Conversa(
      id: '4',
      nome: 'Clínica Geral',
      subtitulo: 'Comunicação interna',
      ultimaMensagem: 'Mensagem de voz',
      horario: 'Ontem',
      tipo: _TipoConversa.clinica,
      isAudio: true,
      duracaoAudio: '0:32',
    ),
    _Conversa(
      id: '5',
      nome: 'Equipe Cirúrgica',
      subtitulo: '5 participantes',
      ultimaMensagem: 'Dr. Paulo: Confirmo horário da cirurgia',
      horario: 'Ontem',
      tipo: _TipoConversa.grupo,
    ),
    _Conversa(
      id: '6',
      nome: 'Assistente IA',
      subtitulo: 'Sugestões de resposta',
      ultimaMensagem: 'Claro! Para criar uma resposta adequada...',
      horario: '08:30',
      tipo: _TipoConversa.ia,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildListaConversas(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: const ThirdPartyBottomNav(currentIndex: 1),
    );
  }

  // ==========================================
  // HEADER SIMPLES
  // ==========================================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(width: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      child: const Text(
        'Conversas',
        style: TextStyle(
          color: Color(0xFF212621),
          fontSize: 18,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================
  // ABA CLÍNICO - LISTA DE CONVERSAS
  // ==========================================
  Widget _buildListaConversas() {
    final conversasFiltradas = _filtrarConversas();

    return Column(
      children: [
        _buildCampoBusca(),
        Expanded(
          child: conversasFiltradas.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: conversasFiltradas.length,
                  itemBuilder: (context, index) {
                    return _buildCardConversa(conversasFiltradas[index]);
                  },
                ),
        ),
      ],
    );
  }

  List<_Conversa> _filtrarConversas() {
    final busca = _searchController.text.toLowerCase();
    return _conversas.where((c) {
      if (busca.isEmpty) return true;
      return c.nome.toLowerCase().contains(busca) ||
          (c.subtitulo?.toLowerCase().contains(busca) ?? false);
    }).toList();
  }

  Widget _buildCampoBusca() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
              decoration: const InputDecoration(
                hintText: 'Buscar conversa...',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filtros em breve!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Icon(Icons.tune, color: Color(0xFF495565), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCardConversa(_Conversa conversa) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ThirdPartyConversationScreen(conversa: conversa),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: conversa.mensagensNaoLidas > 0
                ? const Color(0xFF4F4A34).withOpacity(0.3)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(conversa),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome + Horário
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                conversa.nome,
                                style: TextStyle(
                                  color: const Color(0xFF212621),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: conversa.mensagensNaoLidas > 0
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conversa.status == _StatusConversa.online) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        conversa.horario,
                        style: TextStyle(
                          color: conversa.mensagensNaoLidas > 0
                              ? const Color(0xFF4F4A34)
                              : const Color(0xFF697282),
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: conversa.mensagensNaoLidas > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Subtítulo
                  if (conversa.subtitulo != null)
                    Text(
                      conversa.subtitulo!,
                      style: const TextStyle(
                        color: Color(0xFF495565),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Preview mensagem + Badge
                  Row(
                    children: [
                      Expanded(child: _buildPreviewMensagem(conversa)),
                      if (conversa.mensagensNaoLidas > 0)
                        _buildBadgeNaoLidas(conversa.mensagensNaoLidas),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(_Conversa conversa) {
    IconData icone;
    Color corFundo;

    switch (conversa.tipo) {
      case _TipoConversa.paciente:
        icone = Icons.person;
        corFundo = const Color(0xFF4F4A34);
        break;
      case _TipoConversa.clinica:
        icone = Icons.local_hospital;
        corFundo = const Color(0xFF22C55E);
        break;
      case _TipoConversa.ia:
        icone = Icons.auto_awesome;
        corFundo = const Color(0xFFA49E86);
        break;
      case _TipoConversa.grupo:
        icone = Icons.group;
        corFundo = const Color(0xFF3B82F6);
        break;
    }

    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icone, color: Colors.white, size: 24),
        ),
        if (conversa.status == _StatusConversa.online)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewMensagem(_Conversa conversa) {
    if (conversa.isAudio) {
      return Row(
        children: [
          const Icon(Icons.mic, color: Color(0xFF4F4A34), size: 14),
          const SizedBox(width: 4),
          Text(
            'Mensagem de voz (${conversa.duracaoAudio})',
            style: const TextStyle(
              color: Color(0xFF4F4A34),
              fontSize: 12,
              fontFamily: 'Inter',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Text(
      conversa.ultimaMensagem,
      style: TextStyle(
        color: conversa.mensagensNaoLidas > 0
            ? const Color(0xFF212621)
            : const Color(0xFF697282),
        fontSize: 12,
        fontFamily: 'Inter',
        fontWeight:
            conversa.mensagensNaoLidas > 0 ? FontWeight.w500 : FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBadgeNaoLidas(int quantidade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        quantidade > 99 ? '99+' : '$quantidade',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma conversa encontrada',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showModalNovaConversa,
      backgroundColor: const Color(0xFF4F4A34),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showModalNovaConversa() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nova conversa',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildOpcaoNovaConversa(
              icone: Icons.person_add,
              titulo: 'Novo paciente',
              subtitulo: 'Iniciar conversa com paciente',
              cor: const Color(0xFF4F4A34),
            ),
            _buildOpcaoNovaConversa(
              icone: Icons.group_add,
              titulo: 'Novo grupo',
              subtitulo: 'Criar grupo de discussão',
              cor: const Color(0xFF3B82F6),
            ),
            _buildOpcaoNovaConversa(
              icone: Icons.auto_awesome,
              titulo: 'Chat IA',
              subtitulo: 'Conversar com assistente IA',
              cor: const Color(0xFFA49E86),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoNovaConversa({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required Color cor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$titulo em breve!'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icone, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: Color(0xFF697282),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

}

// ==========================================
// TELA DE CONVERSA INDIVIDUAL
// ==========================================
class _ThirdPartyConversationScreen extends StatefulWidget {
  final _Conversa conversa;

  const _ThirdPartyConversationScreen({required this.conversa});

  @override
  State<_ThirdPartyConversationScreen> createState() =>
      _ThirdPartyConversationScreenState();
}

class _ThirdPartyConversationScreenState
    extends State<_ThirdPartyConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _inputHasText = false;
  bool _isRecording = false;

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Mensagens iniciais mock
    _messages.addAll([
      _ChatMessage(
        isFromUser: false,
        text: 'Olá! Como posso ajudar?',
        time: '09:00',
      ),
      _ChatMessage(
        isFromUser: true,
        text: 'Preciso de informações sobre o paciente',
        time: '09:05',
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInfoCard(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMessageBubble(_messages[index]),
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EF),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Color(0xFF212621), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4F4A34),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversa.nome,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    if (widget.conversa.status == _StatusConversa.online) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ] else
                      Text(
                        widget.conversa.subtitulo ?? '',
                        style: const TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Color(0xFF495565)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C75B7).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4F4A34),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contexto: ${widget.conversa.nome}',
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.conversa.subtitulo ?? '',
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Ver perfil',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isFromUser;

    if (message.isAudio) {
      return _buildAudioBubble(message, isUser);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: isUser ? const Color(0xFF4F4A34) : Colors.white,
          shape: RoundedRectangleBorder(
            side: isUser
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F4A34),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        widget.conversa.nome[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.conversa.nome,
                    style: const TextStyle(
                      color: Color(0xFF4F4A34),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF212621),
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    color: isUser
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF697282),
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioBubble(_ChatMessage message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF4F4A34) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isUser ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF4F4A34),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(12, (index) {
                      final height = ((index * 7) % 5 + 1) * 4.0;
                      return Container(
                        width: 2,
                        height: height,
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.white.withOpacity(0.6)
                              : const Color(0xFF4F4A34).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.audioDuration ?? '0:00',
                  style: TextStyle(
                    color: isUser
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF697282),
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    if (_isRecording) {
      return _buildRecordingUI();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anexar em breve!')),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.attach_file,
                  size: 20, color: Color(0xFF495565)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
                decoration: const InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  setState(() => _inputHasText = value.trim().isNotEmpty);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          _inputHasText
              ? GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F4A34),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                )
              : GestureDetector(
                  onLongPress: () {
                    setState(() => _isRecording = true);
                  },
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Segure para gravar áudio'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child:
                        const Icon(Icons.mic, color: Color(0xFF4F4A34), size: 24),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '00:00',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(20, (index) {
                  return Container(
                    width: 3,
                    height: ((index % 3) + 1) * 8.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _isRecording = false),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Color(0xFFEF4444), size: 20),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                // Enviar áudio
                setState(() {
                  _messages.add(_ChatMessage(
                    isFromUser: true,
                    text: '',
                    time: TimeOfDay.now().format(context),
                    isAudio: true,
                    audioDuration: '0:05',
                  ));
                  _isRecording = false;
                });
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F4A34),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final now = TimeOfDay.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(_ChatMessage(
        isFromUser: true,
        text: _messageController.text.trim(),
        time: timeString,
      ));
      _messageController.clear();
      _inputHasText = false;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

// ==========================================
// MODELS
// ==========================================
enum _TipoConversa { paciente, clinica, ia, grupo }

enum _StatusConversa { online, offline, digitando }

class _Conversa {
  final String id;
  final String nome;
  final String? subtitulo;
  final String ultimaMensagem;
  final String horario;
  final _TipoConversa tipo;
  final int mensagensNaoLidas;
  final bool isAudio;
  final String? duracaoAudio;
  final _StatusConversa status;

  _Conversa({
    required this.id,
    required this.nome,
    this.subtitulo,
    required this.ultimaMensagem,
    required this.horario,
    required this.tipo,
    this.mensagensNaoLidas = 0,
    this.isAudio = false,
    this.duracaoAudio,
    this.status = _StatusConversa.offline,
  });
}

class _ChatMessage {
  final bool isFromUser;
  final String text;
  final String time;
  final bool isAudio;
  final String? audioDuration;

  _ChatMessage({
    required this.isFromUser,
    required this.text,
    required this.time,
    this.isAudio = false,
    this.audioDuration,
  });
}
