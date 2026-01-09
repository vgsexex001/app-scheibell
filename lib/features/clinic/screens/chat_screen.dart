import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'patient_chat_screen.dart';
import 'appointment_detail_screen.dart';
import '../providers/admin_chat_controller.dart';
import '../../chatbot/domain/entities/chat_message.dart' as domain;
import '../../../core/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _selectedTabIndex = 0; // 0 = IA, 1 = Clínico, 2 = Atendimento, 3 = Agendamentos
  final int _selectedNavIndex = 2; // Chat tab
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // API Service
  final ApiService _apiService = ApiService();

  // Estado para conversas de pacientes
  List<PatientConversation> _patientConversations = [];
  bool _isLoadingConversations = true;

  // Estado para agendamentos
  List<Appointment> _appointments = [];
  bool _isLoadingAppointments = true;

  // Estado para conversas em modo HUMAN (atendimento)
  List<HumanHandoffConversation> _humanConversations = [];
  bool _isLoadingHumanConversations = true;
  int _humanConversationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPatientConversations(),
      _loadAppointments(),
      _loadHumanConversations(),
    ]);
  }

  Future<void> _loadHumanConversations() async {
    setState(() => _isLoadingHumanConversations = true);
    try {
      final data = await _apiService.getHumanConversations(status: 'HUMAN');
      final items = data['items'] as List? ?? [];
      final conversations = items.map((item) {
        return HumanHandoffConversation(
          id: item['id'] ?? '',
          patientName: item['patientName'] ?? 'Paciente',
          patientId: item['patientId'] ?? '',
          lastMessage: item['lastMessage'] ?? '',
          lastMessageTime: item['lastMessageTime'] ?? '',
          handoffAt: item['handoffAt'] != null
              ? DateTime.tryParse(item['handoffAt'])
              : null,
          unreadCount: item['unreadFromPatient'] ?? 0,
        );
      }).toList();
      setState(() {
        _humanConversations = conversations;
        _humanConversationsCount = conversations.length;
        _isLoadingHumanConversations = false;
      });
    } catch (e) {
      print('Erro ao carregar conversas humanas: $e');
      setState(() {
        _humanConversations = [];
        _humanConversationsCount = 0;
        _isLoadingHumanConversations = false;
      });
    }
  }

  Future<void> _loadPatientConversations() async {
    setState(() => _isLoadingConversations = true);
    try {
      final data = await _apiService.getChatConversations();
      final conversations = data.map((item) {
        return PatientConversation(
          id: item['id'] ?? '',
          name: item['patientName'] ?? item['name'] ?? 'Paciente',
          procedure: item['procedure'] ?? 'Consulta',
          daysPostOp: item['daysPostOp'] ?? 0,
          lastMessage: item['lastMessage'] ?? '',
          lastMessageTime: item['lastMessageTime'] ?? '',
          unreadCount: item['unreadCount'] ?? 0,
          status: _mapPatientStatus(item['status']),
        );
      }).toList();
      setState(() {
        _patientConversations = conversations;
        _isLoadingConversations = false;
      });
    } catch (e) {
      print('Erro ao carregar conversas: $e');
      setState(() {
        _patientConversations = [];
        _isLoadingConversations = false;
      });
    }
  }

  PatientStatus _mapPatientStatus(String? status) {
    switch (status) {
      case 'URGENT':
        return PatientStatus.urgent;
      case 'ATTENTION':
        return PatientStatus.attention;
      default:
        return PatientStatus.normal;
    }
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoadingAppointments = true);
    try {
      final data = await _apiService.getAppointments();
      final appointments = data.map((item) => _mapAppointment(item)).toList();
      setState(() {
        _appointments = appointments;
        _isLoadingAppointments = false;
      });
    } catch (e) {
      print('Erro ao carregar agendamentos: $e');
      setState(() {
        _appointments = [];
        _isLoadingAppointments = false;
      });
    }
  }

  Appointment _mapAppointment(Map<String, dynamic> item) {
    final patientName = item['patientName'] ?? item['patient']?['name'] ?? 'Paciente';
    final initials = _getInitials(patientName);

    AppointmentType procedureType;
    switch (item['type']) {
      case 'RETURN_VISIT':
        procedureType = AppointmentType.returnVisit;
        break;
      case 'EVALUATION':
        procedureType = AppointmentType.evaluation;
        break;
      case 'PHYSIOTHERAPY':
        procedureType = AppointmentType.physiotherapy;
        break;
      case 'EXAM':
        procedureType = AppointmentType.exam;
        break;
      default:
        procedureType = AppointmentType.other;
    }

    AppointmentStatus status;
    switch (item['status']) {
      case 'CONFIRMED':
        status = AppointmentStatus.confirmed;
        break;
      case 'CANCELLED':
        status = AppointmentStatus.cancelled;
        break;
      default:
        status = AppointmentStatus.pending;
    }

    return Appointment(
      id: item['id'] ?? '',
      patientName: patientName,
      patientInitials: initials,
      procedure: item['title'] ?? item['procedure'] ?? 'Consulta',
      procedureType: procedureType,
      date: DateTime.tryParse(item['date'] ?? '') ?? DateTime.now(),
      time: item['time'] ?? '00:00',
      duration: item['duration'] ?? '30 min',
      status: status,
      notes: item['description'] ?? item['notes'] ?? '',
    );
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
        return _buildAtendimentoContent();
      case 3:
        return _buildAgendamentosContent();
      default:
        return _buildIAChatContent();
    }
  }

  /// Tab Bar com 4 abas
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
          const SizedBox(width: 6),
          Expanded(
            child: _buildTab(
              index: 1,
              icon: Icons.medical_services_outlined,
              label: 'Clínico',
              isActive: _selectedTabIndex == 1,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTab(
              index: 2,
              icon: Icons.support_agent,
              label: 'Atendimento',
              isActive: _selectedTabIndex == 2,
              badgeCount: _humanConversationsCount,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTab(
              index: 3,
              icon: Icons.calendar_today_outlined,
              label: 'Agenda',
              isActive: _selectedTabIndex == 3,
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
    int badgeCount = 0,
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isActive ? Colors.white : const Color(0xFF495565),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF495565),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.33,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
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
    return Consumer<AdminChatController>(
      builder: (context, controller, child) {
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
                    ...controller.messages.map((msg) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildDomainMessageBubble(msg),
                        )),
                    if (controller.isLoading)
                      _buildTypingIndicator(),
                  ],
                ),
              ),
            ),
            _buildMessageInput(),
          ],
        );
      },
    );
  }

  /// Converte mensagem de domínio para widget de UI
  Widget _buildDomainMessageBubble(domain.ChatMessage message) {
    final timeString = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    // Reutiliza o widget existente convertendo para formato local
    return _buildMessageBubble(ChatMessage(
      isFromUser: message.isUser,
      text: message.content,
      time: timeString,
    ));
  }

  /// Indicador de "digitando..." quando a IA está processando
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F4A34)),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Digitando...',
                  style: TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

    final controller = context.read<AdminChatController>();
    controller.sendMessage(_messageController.text.trim());
    _messageController.clear();

    // Scroll para baixo após envio
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

  /// ==========================================
  /// ABA CLÍNICO - LISTA DE PACIENTES
  /// ==========================================
  Widget _buildClinicoPatientsContent() {
    return Column(
      children: [
        _buildClinicoHeader(),
        Expanded(
          child: _isLoadingConversations
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4F4A34),
                  ),
                )
              : _patientConversations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Color(0xFFA49E86),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhuma conversa encontrada',
                            style: TextStyle(
                              color: Color(0xFF495565),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
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
  /// ABA ATENDIMENTO - HUMAN HANDOFF
  /// ==========================================
  Widget _buildAtendimentoContent() {
    return Column(
      children: [
        _buildAtendimentoHeader(),
        Expanded(
          child: _isLoadingHumanConversations
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                )
              : _humanConversations.isEmpty
                  ? _buildEmptyAtendimento()
                  : RefreshIndicator(
                      onRefresh: _loadHumanConversations,
                      color: const Color(0xFF3B82F6),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _humanConversations.length,
                        itemBuilder: (context, index) {
                          return _buildHumanConversationCard(
                              _humanConversations[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAtendimentoHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 20,
                    color: Color(0xFF3B82F6),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Atendimento Humano',
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_humanConversationsCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_humanConversationsCount aguardando',
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF3B82F6),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pacientes que solicitaram falar com a equipe',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
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

  Widget _buildEmptyAtendimento() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 40,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum atendimento pendente',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Todos os pacientes estão sendo\natendidos pelo assistente IA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF495565),
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumanConversationCard(HumanHandoffConversation conversation) {
    final waitingTime = conversation.handoffAt != null
        ? DateTime.now().difference(conversation.handoffAt!)
        : null;

    String waitingLabel = '';
    if (waitingTime != null) {
      if (waitingTime.inMinutes < 60) {
        waitingLabel = '${waitingTime.inMinutes}min';
      } else if (waitingTime.inHours < 24) {
        waitingLabel = '${waitingTime.inHours}h';
      } else {
        waitingLabel = '${waitingTime.inDays}d';
      }
    }

    return GestureDetector(
      onTap: () => _openHumanConversation(conversation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: conversation.unreadCount > 0
                  ? const Color(0xFF3B82F6).withOpacity(0.3)
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
                    color: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(conversation.patientName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (conversation.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
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
                        conversation.patientName,
                        style: const TextStyle(
                          color: Color(0xFF212621),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (waitingLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 10,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                waitingLabel,
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.support_agent,
                        size: 12,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Aguardando atendimento',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    style: TextStyle(
                      color: conversation.unreadCount > 0
                          ? const Color(0xFF212621)
                          : const Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  void _openHumanConversation(HumanHandoffConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HumanChatScreen(conversation: conversation),
      ),
    ).then((_) {
      // Recarrega as conversas ao voltar
      _loadHumanConversations();
    });
  }

  /// ==========================================
  /// ABA AGENDAMENTOS - LISTA DE CONSULTAS
  /// ==========================================
  Widget _buildAgendamentosContent() {
    if (_isLoadingAppointments) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4F4A34),
        ),
      );
    }

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

    if (_appointments.isEmpty) {
      return Column(
        children: [
          _buildAgendamentosHeader(),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: Color(0xFFA49E86),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum agendamento encontrado',
                    style: TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

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
              color: appointment.procedureType == AppointmentType.exam
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
      case AppointmentType.returnVisit:
        return const Color(0xFF22C55E);
      case AppointmentType.evaluation:
        return const Color(0xFF3B82F6);
      case AppointmentType.physiotherapy:
        return const Color(0xFF7C75B7);
      case AppointmentType.exam:
        return const Color(0xFFF59E0B);
      case AppointmentType.other:
        return const Color(0xFF4F4A34);
    }
  }

  IconData _getAppointmentTypeIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.returnVisit:
        return Icons.refresh;
      case AppointmentType.evaluation:
        return Icons.camera_alt_outlined;
      case AppointmentType.physiotherapy:
        return Icons.fitness_center_outlined;
      case AppointmentType.exam:
        return Icons.medical_services_outlined;
      case AppointmentType.other:
        return Icons.event_note_outlined;
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

enum AppointmentType { returnVisit, evaluation, physiotherapy, exam, other }

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

/// Modelo para conversas em modo HUMAN (atendimento humano)
class HumanHandoffConversation {
  final String id;
  final String patientName;
  final String patientId;
  final String lastMessage;
  final String lastMessageTime;
  final DateTime? handoffAt;
  final int unreadCount;

  HumanHandoffConversation({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.handoffAt,
    this.unreadCount = 0,
  });
}

/// ==========================================
/// TELA DE CHAT HUMANO (STAFF -> PACIENTE)
/// ==========================================
class HumanChatScreen extends StatefulWidget {
  final HumanHandoffConversation conversation;

  const HumanChatScreen({super.key, required this.conversation});

  @override
  State<HumanChatScreen> createState() => _HumanChatScreenState();
}

class _HumanChatScreenState extends State<HumanChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await _apiService.getConversationForAdmin(widget.conversation.id);
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Erro ao carregar conversa: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final response = await _apiService.sendHumanMessage(
        widget.conversation.id,
        text,
      );

      // Adiciona mensagem à lista
      setState(() {
        _messages.add({
          'id': response['id'],
          'content': text,
          'role': 'assistant',
          'senderType': 'staff',
          'createdAt': DateTime.now().toIso8601String(),
        });
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar mensagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _closeConversation({bool returnToAi = true}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(returnToAi ? 'Devolver para IA' : 'Encerrar atendimento'),
        content: Text(
          returnToAi
              ? 'O paciente voltará a ser atendido pelo assistente IA. Deseja continuar?'
              : 'A conversa será encerrada. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  returnToAi ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
            ),
            child: Text(returnToAi ? 'Devolver' : 'Encerrar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.closeHumanConversation(
          widget.conversation.id,
          returnToAi: returnToAi,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                returnToAi
                    ? 'Conversa devolvida para IA'
                    : 'Atendimento encerrado',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Erro ao fechar conversa: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao fechar conversa'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.patientName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'Atendimento humano',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'return_ai') {
                _closeConversation(returnToAi: true);
              } else if (value == 'close') {
                _closeConversation(returnToAi: false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'return_ai',
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Devolver para IA'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(Icons.close, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Encerrar atendimento',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF3B82F6)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Você está respondendo como equipe da clínica',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Mensagens
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          // Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final role = message['role'] as String?;
    final senderType = message['senderType'] as String?;
    final content = message['content'] as String? ?? '';

    final isFromPatient = role == 'user' || senderType == 'patient';
    final isFromStaff = senderType == 'staff';
    final isFromAi = senderType == 'ai' || (role == 'assistant' && senderType == null);
    final isSystem = role == 'system' || senderType == 'system';

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(
                color: Color(0xFF495565),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isFromPatient ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFromPatient
                ? Colors.white
                : isFromStaff
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF4F4A34),
            borderRadius: BorderRadius.circular(16),
            border: isFromPatient
                ? Border.all(color: const Color(0xFFE5E7EB))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isFromPatient)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFromStaff ? Icons.support_agent : Icons.smart_toy,
                        size: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFromStaff ? 'Equipe' : 'IA',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                content,
                style: TextStyle(
                  color: isFromPatient ? const Color(0xFF212621) : Colors.white,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Digite sua mensagem...',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF3B82F6)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isSending
                    ? const Color(0xFF3B82F6).withOpacity(0.5)
                    : const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
