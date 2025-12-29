import 'package:flutter/material.dart';
import 'chat_screen.dart' show PatientConversation, PatientStatus;

class PatientChatScreen extends StatefulWidget {
  final PatientConversation patient;

  const PatientChatScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mensagens mock do chat com paciente
  late List<PatientMessage> _messages;

  @override
  void initState() {
    super.initState();
    // Inicializar mensagens mock baseadas no paciente
    _messages = [
      PatientMessage(
        isFromPatient: true,
        text: 'Olá doutor, tudo bem?',
        time: '10:30',
      ),
      PatientMessage(
        isFromPatient: false,
        text:
            'Olá ${widget.patient.name.split(' ')[0]}! Tudo bem sim, como você está se sentindo?',
        time: '10:32',
      ),
      PatientMessage(
        isFromPatient: true,
        text: widget.patient.lastMessage,
        time: '10:45',
      ),
    ];
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
            // Header com info do paciente
            _buildHeader(),
            // Card de contexto do paciente
            _buildPatientInfoCard(),
            // Mensagens
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
            // Input de mensagem
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          // Botão voltar
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: const Color(0xFFF5F3EF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF495565),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: const Color(0xFF4F4A34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.patient.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nome e status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.name,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
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
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botão de opções
          GestureDetector(
            onTap: () {
              // TODO: Mostrar opções (ver perfil, histórico, etc)
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: const Color(0xFFF5F3EF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.more_vert,
                size: 20,
                color: Color(0xFF495565),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: const Color(0xFF7C75B7).withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: ShapeDecoration(
              color: const Color(0xFF4F4A34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contexto: ${widget.patient.name}',
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.patient.procedure} • ${widget.patient.daysPostOp}d pós-op',
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          // Botão ver perfil
          GestureDetector(
            onTap: () {
              // TODO: Navegar para perfil do paciente
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: ShapeDecoration(
                color: const Color(0xFFF5F3EF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(PatientMessage message) {
    final isPatient = message.isFromPatient;

    return Align(
      alignment: isPatient ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: isPatient ? Colors.white : const Color(0xFF4F4A34),
          shape: RoundedRectangleBorder(
            side: isPatient
                ? const BorderSide(
                    width: 1,
                    color: Color(0xFFE5E7EB),
                  )
                : BorderSide.none,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (apenas para mensagens do paciente)
            if (isPatient) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF4F4A34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(widget.patient.name)[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.patient.name,
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
            // Texto
            Text(
              message.text,
              style: TextStyle(
                color: isPatient ? const Color(0xFF212621) : Colors.white,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 4),
            // Horário
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    color: isPatient
                        ? const Color(0xFF697282)
                        : Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (!isPatient) ...[
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

  Widget _buildMessageInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            width: 1,
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          // Botão anexo
          Container(
            width: 36,
            height: 36,
            decoration: ShapeDecoration(
              color: const Color(0xFFF5F3EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.attach_file,
              size: 20,
              color: Color(0xFF495565),
            ),
          ),
          const SizedBox(width: 8),
          // Campo de texto
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: ShapeDecoration(
                color: const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 1,
                    color: Color(0xFFE0E0E0),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botão microfone (gravar áudio)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gravação de áudio em breve!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: const Color(0xFFF5F3EF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.mic,
                size: 20,
                color: Color(0xFF4F4A34),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botão IA (sugestão)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sugestões de IA em breve!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: const Color(0xFFF5F3EF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Color(0xFF4F4A34),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botão enviar
          GestureDetector(
            onTap: _sendMessage,
            child: Opacity(
              opacity: _messageController.text.isEmpty ? 0.5 : 1.0,
              child: Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  color: const Color(0xFF4F4A34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final now = TimeOfDay.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(PatientMessage(
        isFromPatient: false,
        text: _messageController.text.trim(),
        time: timeString,
      ));
      _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}

class PatientMessage {
  final bool isFromPatient;
  final String text;
  final String time;

  PatientMessage({
    required this.isFromPatient,
    required this.text,
    required this.time,
  });
}
