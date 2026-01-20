import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'patient_chat_screen.dart';
import '../providers/admin_chat_controller.dart';
import '../../chatbot/domain/entities/chat_message.dart' as domain;
import '../../chatbot/presentation/widgets/audio_recorder_widget.dart';
import '../../chatbot/data/datasources/chat_api_datasource.dart';
import '../../../core/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _selectedTabIndex = 0; // 0 = IA, 1 = Clínico (atendimento humano)
  final int _selectedNavIndex = 2; // Chat tab
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isRecordingAudio = false;

  // API Service
  final ApiService _apiService = ApiService();
  final ChatApiDatasource _chatApiDatasource = ChatApiDatasource();

  // Estado para conversas de pacientes
  List<PatientConversation> _patientConversations = [];
  List<PatientConversation> _filteredPatientConversations = [];
  bool _isLoadingConversations = true;
  String _searchQuery = '';

  // Estado para conversas em modo HUMAN (atendimento)
  List<HumanHandoffConversation> _humanConversations = [];
  List<HumanHandoffConversation> _filteredHumanConversations = [];
  bool _isLoadingHumanConversations = true;
  int _humanConversationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      _filterConversations();
    });
  }

  void _filterConversations() {
    if (_searchQuery.isEmpty) {
      _filteredPatientConversations = List.from(_patientConversations);
      _filteredHumanConversations = List.from(_humanConversations);
    } else {
      _filteredPatientConversations = _patientConversations.where((conv) {
        final nameMatch = conv.name.toLowerCase().contains(_searchQuery);
        final idMatch = conv.id.toLowerCase().contains(_searchQuery);
        // Também permite buscar por status
        final statusMatch = conv.status.label.toLowerCase().contains(_searchQuery);
        return nameMatch || idMatch || statusMatch;
      }).toList();

      _filteredHumanConversations = _humanConversations.where((conv) {
        final nameMatch = conv.patientName.toLowerCase().contains(_searchQuery);
        final idMatch = conv.patientId.toLowerCase().contains(_searchQuery);
        return nameMatch || idMatch;
      }).toList();
    }
    // Aplica ordenação por prioridade
    _sortConversationsByPriority();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterConversations();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPatientConversations(),
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
        _filterConversations();
        _isLoadingHumanConversations = false;
      });
    } catch (e) {
      print('Erro ao carregar conversas humanas: $e');
      setState(() {
        _humanConversations = [];
        _filteredHumanConversations = [];
        _humanConversationsCount = 0;
        _isLoadingHumanConversations = false;
      });
    }
  }

  Future<void> _loadPatientConversations() async {
    setState(() => _isLoadingConversations = true);
    try {
      // Usa endpoint de admin para listar TODAS as conversas de pacientes da clínica
      final data = await _apiService.getAdminAllConversations();
      final conversations = data.map((item) {
        final lastMessage = item['lastMessage'] ?? '';
        final backendStatus = item['status'] as String?;
        // Analisa automaticamente a mensagem para detectar sinais
        final autoStatus = _analyzeMessageForStatus(lastMessage, backendStatus);

        return PatientConversation(
          id: item['id'] ?? '',
          name: item['patientName'] ?? item['name'] ?? 'Paciente',
          procedure: item['procedure'] ?? 'Consulta',
          daysPostOp: item['daysPostOp'] ?? 0,
          lastMessage: lastMessage,
          lastMessageTime: item['lastMessageTime'] ?? '',
          unreadCount: item['unreadCount'] ?? 0,
          status: autoStatus,
        );
      }).toList();
      setState(() {
        _patientConversations = conversations;
        _filterConversations();
        _sortConversationsByPriority();
        _isLoadingConversations = false;
      });
    } catch (e) {
      print('Erro ao carregar conversas: $e');
      setState(() {
        _patientConversations = [];
        _filteredPatientConversations = [];
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
      case 'MEDICATION':
        return PatientStatus.medication;
      case 'EXAM':
        return PatientStatus.exam;
      case 'ANXIOUS':
        return PatientStatus.anxious;
      default:
        return PatientStatus.normal;
    }
  }

  /// Analisa a última mensagem e detecta sinais de urgência/atenção automaticamente
  PatientStatus _analyzeMessageForStatus(String message, String? backendStatus) {
    // Se o backend já definiu um status urgente, mantém
    final mapped = _mapPatientStatus(backendStatus);
    if (mapped == PatientStatus.urgent) return mapped;

    final lowerMessage = message.toLowerCase();

    // Palavras-chave para URGENTE (alta prioridade)
    final urgentKeywords = [
      'sangramento', 'sangrando', 'muito sangue',
      'febre alta', 'febre forte',
      'não consigo respirar', 'falta de ar', 'dificuldade respirar',
      'dor muito forte', 'dor insuportável', 'dor intensa',
      'emergência', 'urgente', 'socorro',
      'desmaiei', 'desmaiar', 'tontura forte',
      'vomitando muito', 'vômito constante',
      'inchaço muito grande', 'inchaço grave',
    ];

    for (final keyword in urgentKeywords) {
      if (lowerMessage.contains(keyword)) {
        return PatientStatus.urgent;
      }
    }

    // Palavras-chave para ATENÇÃO
    final attentionKeywords = [
      'preocupado', 'preocupada',
      'não está normal', 'está estranho',
      'piorou', 'piorando',
      'vermelho', 'vermelhidão',
      'secreção', 'pus',
      'febre', 'temperatura',
      'dor que não passa', 'dor constante',
      'inchaço', 'inchado',
      'hematoma',
    ];

    for (final keyword in attentionKeywords) {
      if (lowerMessage.contains(keyword)) {
        return PatientStatus.attention;
      }
    }

    // Palavras-chave para ANSIOSO
    final anxiousKeywords = [
      'ansioso', 'ansiosa', 'ansiedade',
      'nervoso', 'nervosa',
      'medo', 'com medo',
      'preocupado', 'preocupada',
      'não consigo dormir', 'insônia',
      'estressado', 'estressada',
      'angústia', 'angustiado',
    ];

    for (final keyword in anxiousKeywords) {
      if (lowerMessage.contains(keyword)) {
        return PatientStatus.anxious;
      }
    }

    // Palavras-chave para MEDICAÇÃO
    final medicationKeywords = [
      'remédio', 'medicamento', 'medicação',
      'tomar', 'horário',
      'esqueci de tomar', 'posso tomar',
      'dipirona', 'paracetamol', 'ibuprofeno',
      'antibiótico', 'analgésico',
      'receita', 'prescrição',
      'dose', 'dosagem',
    ];

    for (final keyword in medicationKeywords) {
      if (lowerMessage.contains(keyword)) {
        return PatientStatus.medication;
      }
    }

    // Palavras-chave para EXAME
    final examKeywords = [
      'exame', 'resultado',
      'ultrassom', 'raio-x', 'tomografia',
      'hemograma', 'análise',
      'laboratório', 'coleta',
      'retorno', 'consulta',
      'avaliação',
    ];

    for (final keyword in examKeywords) {
      if (lowerMessage.contains(keyword)) {
        return PatientStatus.exam;
      }
    }

    // Se o backend definiu algo, mantém
    if (mapped != PatientStatus.normal) return mapped;

    return PatientStatus.normal;
  }

  /// Retorna o número de pacientes que precisam de atenção (urgente, atenção ou não lidas)
  int _getAttentionCount() {
    return _patientConversations.where((p) =>
        p.status == PatientStatus.urgent ||
        p.status == PatientStatus.attention ||
        p.unreadCount > 0).length;
  }

  /// Ordena conversas por prioridade (urgente primeiro)
  void _sortConversationsByPriority() {
    _filteredPatientConversations.sort((a, b) {
      // Primeiro por prioridade do status
      final priorityCompare = a.status.priority.compareTo(b.status.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Depois por mensagens não lidas (mais não lidas primeiro)
      final unreadCompare = b.unreadCount.compareTo(a.unreadCount);
      if (unreadCompare != 0) return unreadCompare;

      // Por último, alfabeticamente
      return a.name.compareTo(b.name);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
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
        return _buildClinicoPatientsContent(); // Clínico (lista de pacientes com flags automáticas)
      default:
        return _buildIAChatContent();
    }
  }

  /// Tab Bar com 2 abas: IA e Clínico
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
              icon: Icons.support_agent,
              label: 'Clínico',
              isActive: _selectedTabIndex == 1,
              badgeCount: _getAttentionCount(),
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
            Icons.auto_awesome,
            size: 12,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assistente de comunicação médico-paciente. Peça sugestões de respostas para seus pacientes.',
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            width: 1,
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sugestões rápidas de IA (oculta durante gravação)
          if (!_isRecordingAudio) _buildQuickSuggestions(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quando está gravando, mostra o AudioRecorderWidget
                if (_isRecordingAudio) ...[
                  Expanded(
                    child: AudioRecorderWidget(
                      primaryColor: const Color(0xFF4F4A34),
                      onAudioRecorded: (audioFile, durationSeconds) {
                        setState(() {
                          _isRecordingAudio = false;
                        });
                        _handleAudioRecorded(audioFile, durationSeconds);
                      },
                      onRecordingStarted: () {},
                      onRecordingCancelled: () {
                        setState(() {
                          _isRecordingAudio = false;
                        });
                      },
                    ),
                  ),
                ] else ...[
                  // Botão anexo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: _showAttachmentOptions,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.attach_file,
                          size: 20,
                          color: Color(0xFF495565),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Campo de texto
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3EF),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: (_) => setState(() {}),
                        textAlignVertical: TextAlignVertical.center,
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: 'Peça ajuda para responder seu paciente...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botão de microfone - só aparece quando não há texto
                  if (_messageController.text.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRecordingAudio = true;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3EF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mic,
                            size: 20,
                            color: Color(0xFF4F4A34),
                          ),
                        ),
                      ),
                    ),
                  if (_messageController.text.isEmpty)
                    const SizedBox(width: 8),
                  // Botão de enviar - sempre visível
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: _messageController.text.isEmpty ? null : _sendMessage,
                      child: Opacity(
                        opacity: _messageController.text.isEmpty ? 0.5 : 1.0,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F4A34),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
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
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Processa áudio gravado - transcreve e envia para a IA
  Future<void> _handleAudioRecorded(File audioFile, int durationSeconds) async {
    // Formata duração
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final durationStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Mostra indicador de processamento
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Transcrevendo áudio...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Usa a OpenAI Whisper API via backend para transcrever
      final transcription = await _transcribeAudioLocally(audioFile);

      // Fecha o SnackBar de loading
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (transcription != null && transcription.isNotEmpty) {
        // Envia a transcrição para a IA
        final chatController = context.read<AdminChatController>();
        await chatController.sendMessage(transcription);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível transcrever o áudio. Tente digitar sua mensagem.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[AUDIO] Error transcribing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar áudio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Limpa o arquivo de áudio temporário
      try {
        if (audioFile.existsSync()) {
          audioFile.deleteSync();
        }
      } catch (_) {}
    }
  }

  /// Transcreve áudio usando OpenAI Whisper API via backend
  Future<String?> _transcribeAudioLocally(File audioFile) async {
    try {
      // Valida o arquivo
      if (!_chatApiDatasource.isValidAudioFile(audioFile)) {
        debugPrint('[AUDIO] Invalid audio file format');
        return null;
      }

      // Faz upload do áudio via ChatApiDatasource
      final uploadResponse = await _chatApiDatasource.uploadAudio(
        audioFile,
        durationSeconds: 0,
      );

      debugPrint('[AUDIO] Upload successful, attachmentId: ${uploadResponse.id}');

      // Solicita transcrição
      final transcribeResponse = await _chatApiDatasource.transcribeAudio(
        attachmentId: uploadResponse.id,
      );

      debugPrint('[AUDIO] Transcription: ${transcribeResponse.transcription}');
      return transcribeResponse.transcription;
    } catch (e) {
      debugPrint('[AUDIO] Transcription error: $e');
      return null;
    }
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      'Sugerir resposta para dúvida sobre medicação',
      'Como explicar cuidados pós-operatórios?',
      'Resposta para sintoma relatado pelo paciente',
      'Orientação sobre retorno e consultas',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  _messageController.text = suggestion;
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Color(0xFF4F4A34),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        suggestion,
                        style: const TextStyle(
                          color: Color(0xFF495565),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Anexar arquivo',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Câmera',
                  color: const Color(0xFF4F4A34),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Galeria',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        // Mostrar preview e opção de enviar
        _showImagePreview();
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao selecionar imagem')),
        );
      }
    }
  }

  void _showImagePreview() {
    if (_selectedImage == null) return;
    final TextEditingController captionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F3EF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Enviar imagem',
                      style: TextStyle(
                        color: Color(0xFF212621),
                        fontSize: 18,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedImage = null);
                        Navigator.pop(ctx);
                      },
                      child: const Icon(Icons.close, color: Color(0xFF697282)),
                    ),
                  ],
                ),
              ),
              // Card branco com imagem e campo de texto
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Imagem
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        // Divisor
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        // Campo de texto para legenda
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            controller: captionController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Adicione uma descrição (opcional)...',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              color: Color(0xFF212621),
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Botões
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedImage = null);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Color(0xFF495565),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _sendImageMessage(caption: captionController.text);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F4A34),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Enviar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendImageMessage({String? caption}) {
    if (_selectedImage == null) return;

    // Por enquanto, apenas mostra feedback
    final message = caption != null && caption.isNotEmpty
        ? 'Imagem com descrição será enviada em breve!'
        : 'Envio de imagem em breve!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() => _selectedImage = null);
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
              : _filteredPatientConversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.chat_bubble_outline,
                            size: 48,
                            color: const Color(0xFFA49E86),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Nenhum paciente encontrado para "$_searchQuery"'
                                : 'Nenhuma conversa encontrada',
                            style: const TextStyle(
                              color: Color(0xFF495565),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _clearSearch,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F4A34),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Limpar busca',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredPatientConversations.length,
                      itemBuilder: (context, index) {
                        return _buildPatientConversationCard(_filteredPatientConversations[index]);
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
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar paciente por nome ou ID...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF9CA3AF),
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
    final statusColor = patient.status.color;
    final hasSpecialStatus = patient.status != PatientStatus.normal;

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
              width: hasSpecialStatus ? 1.5 : 1,
              color: hasSpecialStatus
                  ? statusColor.withOpacity(0.4)
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
                // Indicador de mensagem nova ou status especial
                if (patient.unreadCount > 0 || hasSpecialStatus)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: patient.unreadCount > 0
                            ? const Color(0xFF22C55E) // Verde para mensagens novas
                            : statusColor,
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
                    children: [
                      Expanded(
                        child: Text(
                          patient.name,
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge de status automático
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              patient.status.icon,
                              size: 10,
                              color: statusColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              patient.status.label,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${patient.procedure} • ${patient.daysPostOp}d pós-op',
                          style: const TextStyle(
                            color: Color(0xFF495565),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
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
        // Barra de busca para atendimento
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar paciente por nome ou ID...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoadingHumanConversations
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                )
              : _filteredHumanConversations.isEmpty
                  ? (_searchQuery.isNotEmpty
                      ? _buildSearchEmptyState()
                      : _buildEmptyAtendimento())
                  : RefreshIndicator(
                      onRefresh: _loadHumanConversations,
                      color: const Color(0xFF3B82F6),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filteredHumanConversations.length,
                        itemBuilder: (context, index) {
                          return _buildHumanConversationCard(
                              _filteredHumanConversations[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum paciente encontrado para "$_searchQuery"',
            style: const TextStyle(
              color: Color(0xFF495565),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _clearSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Limpar busca',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
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
                    'Atendimento Clínico',
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
    // Usa PatientChatScreen para manter consistência com todas as funcionalidades
    // (perguntas rápidas, envio de fotos, etc.)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientChatScreen(
          patient: PatientConversation(
            id: conversation.patientId,
            name: conversation.patientName,
            procedure: 'Atendimento Humano',
            daysPostOp: 0,
            lastMessage: conversation.lastMessage,
            lastMessageTime: conversation.lastMessageTime,
            unreadCount: conversation.unreadCount,
            status: PatientStatus.attention,
          ),
        ),
      ),
    ).then((_) {
      // Recarrega as conversas ao voltar
      _loadHumanConversations();
    });
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

/// Status de prioridade do paciente com flags automáticas
enum PatientStatus {
  normal,      // Rotina
  attention,   // Atenção
  urgent,      // Urgente
  medication,  // Medicação
  exam,        // Exame
  anxious,     // Ansioso
}

/// Extensão para obter informações visuais do status
extension PatientStatusExtension on PatientStatus {
  String get label {
    switch (this) {
      case PatientStatus.urgent: return 'URGENTE';
      case PatientStatus.attention: return 'ATENÇÃO';
      case PatientStatus.medication: return 'MEDICAÇÃO';
      case PatientStatus.exam: return 'EXAME';
      case PatientStatus.anxious: return 'ANSIOSO';
      case PatientStatus.normal: return 'ROTINA';
    }
  }

  Color get color {
    switch (this) {
      case PatientStatus.urgent: return const Color(0xFFEF4444);      // Vermelho
      case PatientStatus.attention: return const Color(0xFFF59E0B);   // Laranja
      case PatientStatus.medication: return const Color(0xFF8B5CF6); // Roxo
      case PatientStatus.exam: return const Color(0xFF3B82F6);        // Azul
      case PatientStatus.anxious: return const Color(0xFFEC4899);     // Rosa
      case PatientStatus.normal: return const Color(0xFF22C55E);      // Verde
    }
  }

  IconData get icon {
    switch (this) {
      case PatientStatus.urgent: return Icons.warning_amber_rounded;
      case PatientStatus.attention: return Icons.error_outline;
      case PatientStatus.medication: return Icons.medication;
      case PatientStatus.exam: return Icons.assignment;
      case PatientStatus.anxious: return Icons.sentiment_dissatisfied;
      case PatientStatus.normal: return Icons.check_circle_outline;
    }
  }

  int get priority {
    switch (this) {
      case PatientStatus.urgent: return 0;
      case PatientStatus.attention: return 1;
      case PatientStatus.anxious: return 2;
      case PatientStatus.medication: return 3;
      case PatientStatus.exam: return 4;
      case PatientStatus.normal: return 5;
    }
  }
}

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
