import 'package:flutter/material.dart';
import 'patient_chat_screen.dart';
import 'appointment_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _selectedTabIndex = 0; // 0 = IA, 1 = Clínico, 2 = Agendamentos
  final int _selectedNavIndex = 2; // Chat tab
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mensagens mock do chat IA
  final List<ChatMessage> _messages = [
    ChatMessage(
      isFromUser: false,
      text:
          'Olá! Sou a assistente inteligente da Clínica Scheibel. Como posso ajudar você hoje?',
      time: '10:00',
    ),
    ChatMessage(
      isFromUser: true,
      text:
          'Preciso de ajuda para responder uma paciente sobre cuidados pós-operatórios',
      time: '10:02',
    ),
    ChatMessage(
      isFromUser: false,
      text:
          'Claro! Para criar uma resposta adequada, preciso de algumas informações:\n\n• Qual tipo de cirurgia foi realizada?\n• Quantos dias de pós-operatório?\n• Qual é a dúvida específica da paciente?',
      time: '10:02',
    ),
  ];

  // Lista de pacientes com conversas (mock)
  final List<PatientConversation> _patientConversations = [
    PatientConversation(
      id: '1',
      name: 'Maria Silva',
      procedure: 'Rinoplastia',
      daysPostOp: 7,
      lastMessage: 'Estou com um inchaço no nariz, é normal?',
      lastMessageTime: '10:45',
      unreadCount: 2,
      status: PatientStatus.attention,
    ),
    PatientConversation(
      id: '2',
      name: 'João Santos',
      procedure: 'Blefaroplastia',
      daysPostOp: 3,
      lastMessage: 'Obrigado pela orientação, doutor!',
      lastMessageTime: '09:30',
      unreadCount: 0,
      status: PatientStatus.normal,
    ),
    PatientConversation(
      id: '3',
      name: 'Ana Oliveira',
      procedure: 'Lifting Facial',
      daysPostOp: 14,
      lastMessage: 'Posso começar a usar maquiagem?',
      lastMessageTime: 'Ontem',
      unreadCount: 1,
      status: PatientStatus.normal,
    ),
    PatientConversation(
      id: '4',
      name: 'Carlos Mendes',
      procedure: 'Otoplastia',
      daysPostOp: 5,
      lastMessage: 'A faixa está incomodando muito',
      lastMessageTime: 'Ontem',
      unreadCount: 3,
      status: PatientStatus.urgent,
    ),
  ];

  // Lista de agendamentos (mock)
  final List<Appointment> _appointments = [
    Appointment(
      id: '1',
      patientName: 'Fernanda Lima',
      patientInitials: 'FL',
      procedure: 'Consulta Pré-Operatória',
      procedureType: AppointmentType.consultation,
      date: DateTime.now(),
      time: '09:00',
      duration: '30 min',
      status: AppointmentStatus.confirmed,
      notes: 'Primeira consulta - Rinoplastia',
    ),
    Appointment(
      id: '2',
      patientName: 'Ricardo Alves',
      patientInitials: 'RA',
      procedure: 'Retorno Pós-Operatório',
      procedureType: AppointmentType.followUp,
      date: DateTime.now(),
      time: '10:00',
      duration: '20 min',
      status: AppointmentStatus.confirmed,
      notes: 'Blefaroplastia - 7 dias pós-op',
    ),
    Appointment(
      id: '3',
      patientName: 'Juliana Costa',
      patientInitials: 'JC',
      procedure: 'Rinoplastia',
      procedureType: AppointmentType.surgery,
      date: DateTime.now(),
      time: '14:00',
      duration: '3h',
      status: AppointmentStatus.confirmed,
      notes: 'Cirurgia agendada - Centro Cirúrgico 2',
    ),
    Appointment(
      id: '4',
      patientName: 'Pedro Machado',
      patientInitials: 'PM',
      procedure: 'Consulta Pré-Operatória',
      procedureType: AppointmentType.consultation,
      date: DateTime.now().add(const Duration(days: 1)),
      time: '08:30',
      duration: '30 min',
      status: AppointmentStatus.pending,
      notes: 'Aguardando confirmação do paciente',
    ),
    Appointment(
      id: '5',
      patientName: 'Mariana Souza',
      patientInitials: 'MS',
      procedure: 'Avaliação de Fotos',
      procedureType: AppointmentType.evaluation,
      date: DateTime.now().add(const Duration(days: 1)),
      time: '11:00',
      duration: '15 min',
      status: AppointmentStatus.confirmed,
      notes: 'Revisão de resultado - Lifting',
    ),
    Appointment(
      id: '6',
      patientName: 'Lucas Ferreira',
      patientInitials: 'LF',
      procedure: 'Otoplastia',
      procedureType: AppointmentType.surgery,
      date: DateTime.now().add(const Duration(days: 2)),
      time: '09:00',
      duration: '2h',
      status: AppointmentStatus.confirmed,
      notes: 'Cirurgia bilateral',
    ),
  ];

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
            _buildTabBar(),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildIAChatContent();
      case 1:
        return _buildClinicoPatientsContent();
      case 2:
        return _buildAgendamentosContent();
      default:
        return _buildIAChatContent();
    }
  }

  /// Tab Bar com 3 abas
  Widget _buildTabBar() {
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
          Expanded(
            child: _buildTab(
              index: 0,
              icon: Icons.auto_awesome,
              label: 'IA',
              isActive: _selectedTabIndex == 0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTab(
              index: 1,
              icon: Icons.medical_services_outlined,
              label: 'Clínico',
              isActive: _selectedTabIndex == 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTab(
              index: 2,
              icon: Icons.calendar_today_outlined,
              label: 'Agenda',
              isActive: _selectedTabIndex == 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        height: 36,
        decoration: ShapeDecoration(
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment(0.00, 0.50),
                  end: Alignment(1.00, 0.50),
                  colors: [Color(0xFF4F4A34), Color(0xFF212621)],
                )
              : null,
          color: isActive ? null : const Color(0xFFF3F4F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: isActive
              ? [
                  const BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                    spreadRadius: -1,
                  ),
                  const BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF495565),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF495565),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.33,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ==========================================
  /// ABA IA - CHAT COM ASSISTENTE (SEM CARD CONTEXTO)
  /// ==========================================
  Widget _buildIAChatContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Banner de aviso (sem card de contexto)
                _buildAIWarningBanner(),
                const SizedBox(height: 12),
                ..._messages.map((msg) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMessageBubble(msg),
                    )),
              ],
            ),
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildAIWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFA49E86),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 12,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Este é um chat com IA. As respostas são sugestões e devem ser revisadas antes do envio.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isFromUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: EdgeInsets.only(
          top: isUser ? 8 : 9,
          left: isUser ? 12 : 13,
          right: isUser ? 12 : 13,
          bottom: 8,
        ),
        decoration: ShapeDecoration(
          color: isUser ? const Color(0xFF4F4A34) : Colors.white,
          shape: RoundedRectangleBorder(
            side: isUser
                ? BorderSide.none
                : const BorderSide(
                    width: 1,
                    color: Color(0xFFE5E7EB),
                  ),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: Color(0xFF4F4A34),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Assistente IA',
                    style: TextStyle(
                      color: Color(0xFF4F4A34),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF212621),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                color: isUser
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF697282),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
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
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Digite sua mensagem ou peça uma sugestão à IA...',
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
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botão de microfone para gravar áudio
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
          // Botão de enviar
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
      _messages.add(ChatMessage(
        isFromUser: true,
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

  /// ==========================================
  /// ABA CLÍNICO - LISTA DE PACIENTES
  /// ==========================================
  Widget _buildClinicoPatientsContent() {
    return Column(
      children: [
        _buildClinicoHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _patientConversations.length,
            itemBuilder: (context, index) {
              return _buildPatientConversationCard(_patientConversations[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClinicoHeader() {
    final unreadCount =
        _patientConversations.where((p) => p.unreadCount > 0).length;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Conversas com Pacientes',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F4A34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount novas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  color: Color(0xFFE5E7EB),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar paciente...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientConversationCard(PatientConversation patient) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientChatScreen(patient: patient),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: patient.status == PatientStatus.urgent
                  ? const Color(0xFFEF4444).withOpacity(0.3)
                  : patient.status == PatientStatus.attention
                      ? const Color(0xFFF59E0B).withOpacity(0.3)
                      : const Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF4F4A34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(patient.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Indicador de mensagem nova (verde) ou status urgente/atenção
                if (patient.unreadCount > 0 ||
                    patient.status != PatientStatus.normal)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: patient.unreadCount > 0
                            ? const Color(0xFF22C55E) // Verde para mensagens novas
                            : patient.status == PatientStatus.urgent
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          color: Color(0xFF212621),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        patient.lastMessageTime,
                        style: TextStyle(
                          color: patient.unreadCount > 0
                              ? const Color(0xFF4F4A34)
                              : const Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: patient.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${patient.procedure} • ${patient.daysPostOp}d pós-op',
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.lastMessage,
                          style: TextStyle(
                            color: patient.unreadCount > 0
                                ? const Color(0xFF212621)
                                : const Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: patient.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (patient.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${patient.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  /// ==========================================
  /// ABA AGENDAMENTOS - LISTA DE CONSULTAS
  /// ==========================================
  Widget _buildAgendamentosContent() {
    final today = DateTime.now();
    final todayAppointments = _appointments
        .where((a) =>
            a.date.day == today.day &&
            a.date.month == today.month &&
            a.date.year == today.year)
        .toList();

    final tomorrowAppointments = _appointments
        .where((a) =>
            a.date.day == today.add(const Duration(days: 1)).day &&
            a.date.month == today.add(const Duration(days: 1)).month &&
            a.date.year == today.add(const Duration(days: 1)).year)
        .toList();

    final laterAppointments = _appointments
        .where((a) => a.date.isAfter(today.add(const Duration(days: 1))))
        .toList();

    return Column(
      children: [
        _buildAgendamentosHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todayAppointments.isNotEmpty) ...[
                  _buildDateSection('Hoje', todayAppointments.length),
                  ...todayAppointments.map((a) => _buildAppointmentCard(a)),
                  const SizedBox(height: 16),
                ],
                if (tomorrowAppointments.isNotEmpty) ...[
                  _buildDateSection('Amanhã', tomorrowAppointments.length),
                  ...tomorrowAppointments.map((a) => _buildAppointmentCard(a)),
                  const SizedBox(height: 16),
                ],
                if (laterAppointments.isNotEmpty) ...[
                  _buildDateSection('Próximos dias', laterAppointments.length),
                  ...laterAppointments.map((a) => _buildAppointmentCard(a)),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgendamentosHeader() {
    final today = DateTime.now();
    final todayCount = _appointments
        .where((a) =>
            a.date.day == today.day &&
            a.date.month == today.month &&
            a.date.year == today.year)
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agendamentos',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F4A34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$todayCount hoje',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', true),
                const SizedBox(width: 8),
                _buildFilterChip('Consultas', false),
                const SizedBox(width: 8),
                _buildFilterChip('Cirurgias', false),
                const SizedBox(width: 8),
                _buildFilterChip('Retornos', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: isSelected ? const Color(0xFF4F4A34) : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color:
                isSelected ? const Color(0xFF4F4A34) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF495565),
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateSection(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF495565),
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

  Widget _buildAppointmentCard(Appointment appointment) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetailScreen(appointment: appointment),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: appointment.procedureType == AppointmentType.surgery
                  ? const Color(0xFF7C75B7).withOpacity(0.3)
                  : const Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: ShapeDecoration(
                color: _getAppointmentTypeColor(appointment.procedureType)
                    .withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    appointment.time,
                    style: TextStyle(
                      color:
                          _getAppointmentTypeColor(appointment.procedureType),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appointment.duration,
                    style: TextStyle(
                      color: _getAppointmentTypeColor(appointment.procedureType)
                          .withOpacity(0.7),
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF4F4A34),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            appointment.patientInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.patientName,
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildStatusBadge(appointment.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getAppointmentTypeIcon(appointment.procedureType),
                        size: 12,
                        color:
                            _getAppointmentTypeColor(appointment.procedureType),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment.procedure,
                          style: const TextStyle(
                            color: Color(0xFF495565),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (appointment.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      appointment.notes,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case AppointmentStatus.confirmed:
        bgColor = const Color(0xFF22C55E).withOpacity(0.1);
        textColor = const Color(0xFF22C55E);
        label = 'Confirmado';
        break;
      case AppointmentStatus.pending:
        bgColor = const Color(0xFFF59E0B).withOpacity(0.1);
        textColor = const Color(0xFFF59E0B);
        label = 'Pendente';
        break;
      case AppointmentStatus.cancelled:
        bgColor = const Color(0xFFEF4444).withOpacity(0.1);
        textColor = const Color(0xFFEF4444);
        label = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getAppointmentTypeColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return const Color(0xFF4F4A34);
      case AppointmentType.surgery:
        return const Color(0xFF7C75B7);
      case AppointmentType.followUp:
        return const Color(0xFF22C55E);
      case AppointmentType.evaluation:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getAppointmentTypeIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return Icons.event_note_outlined;
      case AppointmentType.surgery:
        return Icons.medical_services_outlined;
      case AppointmentType.followUp:
        return Icons.refresh;
      case AppointmentType.evaluation:
        return Icons.camera_alt_outlined;
    }
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  // ===== BOTTOM NAVIGATION =====
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Painel',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Pacientes',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Chat',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'Conteúdos',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Calendário',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _navigateToIndex(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFA49E86).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? const Color(0xFFA49E86)
                  : const Color(0xFF6B6B6B),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFFA49E86)
                    : const Color(0xFF6B6B6B),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToIndex(int index) {
    if (index == _selectedNavIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/clinic-dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/clinic-patients');
        break;
      case 2:
        // Já estamos aqui
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/clinic-content-management');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/clinic-calendar');
        break;
    }
  }
}

/// ==========================================
/// MODELOS DE DADOS
/// ==========================================

class ChatMessage {
  final bool isFromUser;
  final String text;
  final String time;

  ChatMessage({
    required this.isFromUser,
    required this.text,
    required this.time,
  });
}

enum PatientStatus { normal, attention, urgent }

class PatientConversation {
  final String id;
  final String name;
  final String procedure;
  final int daysPostOp;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final PatientStatus status;

  PatientConversation({
    required this.id,
    required this.name,
    required this.procedure,
    required this.daysPostOp,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.status,
  });
}

enum AppointmentType { consultation, surgery, followUp, evaluation }

enum AppointmentStatus { confirmed, pending, cancelled }

class Appointment {
  final String id;
  final String patientName;
  final String patientInitials;
  final String procedure;
  final AppointmentType procedureType;
  final DateTime date;
  final String time;
  final String duration;
  final AppointmentStatus status;
  final String notes;

  Appointment({
    required this.id,
    required this.patientName,
    required this.patientInitials,
    required this.procedure,
    required this.procedureType,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    required this.notes,
  });
}
