import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart' show PatientConversation, PatientStatus, PatientStatusExtension;
import 'patient_detail_screen.dart';
import '../providers/patients_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/audio_upload_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../chatbot/data/datasources/openai_datasource.dart';
import '../../chatbot/domain/entities/chat_message.dart' as domain;
import '../../chatbot/presentation/widgets/audio_player_widget.dart';
import '../../chatbot/presentation/widgets/audio_recorder_widget.dart';

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
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  List<PatientMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  File? _selectedImage;
  bool _isPatientTyping = false; // Indica se o paciente está digitando
  bool _isGeneratingSuggestion = false; // Indica se está gerando sugestão IA
  bool _isRecordingAudio = false; // Indica se está gravando áudio
  final OpenAiDatasource _aiDatasource = OpenAiDatasource();

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  /// Carrega histórico de mensagens do backend usando patientId
  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Usa o patientId do widget.patient.id para buscar conversa
      final patientId = widget.patient.id;
      debugPrint('[PATIENT_CHAT] Loading history for patient=$patientId');

      // Usa o novo endpoint que busca por patientId
      final data = await _apiService.getPatientConversation(patientId);

      final messagesData = data['messages'] as List<dynamic>? ?? [];
      final loadedMessages = messagesData.map((m) {
        final senderTypeStr = m['senderType'] as String? ?? 'patient';
        final role = m['role'] as String? ?? 'user';
        final isFromPatient = senderTypeStr == 'patient' || role == 'user';
        final createdAt = DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now();
        final timeString = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

        // Mapeia o senderType para o enum
        // IMPORTANTE: verificar senderType primeiro, depois role como fallback
        SenderType senderType;
        if (senderTypeStr == 'patient') {
          senderType = SenderType.patient;
        } else if (senderTypeStr == 'staff' || senderTypeStr == 'admin') {
          senderType = SenderType.staff;
        } else if (senderTypeStr == 'ai') {
          senderType = SenderType.ai;
        } else if (role == 'user') {
          senderType = SenderType.patient;
        } else if (role == 'assistant') {
          // Fallback: se não tem senderType mas tem role assistant, assume IA
          senderType = SenderType.ai;
        } else {
          senderType = SenderType.ai; // Default para respostas não-paciente
        }

        // Determina o status da mensagem
        MessageStatus status = MessageStatus.sent;
        if (!isFromPatient) {
          final readAt = m['readAt'] as String?;
          final deliveredAt = m['deliveredAt'] as String?;
          if (readAt != null) {
            status = MessageStatus.read;
          } else if (deliveredAt != null) {
            status = MessageStatus.delivered;
          } else {
            status = MessageStatus.sent;
          }
        }

        // Parse attachments
        final attachmentsData = m['attachments'] as List<dynamic>? ?? [];
        final attachments = attachmentsData.map((a) {
          return PatientMessageAttachment(
            id: a['id'] as String? ?? '',
            type: a['type'] as String? ?? 'IMAGE',
            mimeType: a['mimeType'] as String?,
            durationSeconds: a['durationSeconds'] as int?,
            transcription: a['transcription'] as String?,
            storagePath: a['storagePath'] as String?,
            audioUrl: a['audioUrl'] as String?,
          );
        }).toList();

        return PatientMessage(
          isFromPatient: isFromPatient,
          text: m['content'] as String? ?? '',
          time: timeString,
          status: status,
          senderType: senderType,
          attachments: attachments,
        );
      }).toList();

      setState(() {
        _messages = loadedMessages;
        _isLoading = false;
      });

      debugPrint('[PATIENT_CHAT] Loaded ${_messages.length} messages');

      // Scroll para o final após carregar
      _scrollToBottom();
    } catch (e) {
      debugPrint('[PATIENT_CHAT] Error loading history: $e');
      // Em caso de erro, mostra tela vazia em vez de erro
      setState(() {
        _isLoading = false;
        _messages = [];
      });
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F4A34),
                      ),
                    )
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length + (_isPatientTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Mostra indicador de digitação como último item
                            if (_isPatientTyping && index == _messages.length) {
                              return _buildTypingIndicator();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildMessageBubble(_messages[index]),
                            );
                          },
                        ),
            ),
            // Sugestões rápidas de IA
            _buildQuickSuggestions(),
            // Input de mensagem
            _buildMessageInput(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4F4A34).withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Color(0xFF4F4A34),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Iniciar conversa',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envie uma mensagem para ${widget.patient.name}',
            style: const TextStyle(
              color: Color(0xFF697282),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EF),
                borderRadius: BorderRadius.circular(12),
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
            decoration: BoxDecoration(
              color: const Color(0xFF4F4A34),
              borderRadius: BorderRadius.circular(12),
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
          // Botão de opções (menu)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearChatDialog();
              } else if (value == 'profile') {
                _navigateToPatientProfile();
              }
            },
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: Color(0xFF495565)),
                    SizedBox(width: 12),
                    Text(
                      'Ver perfil',
                      style: TextStyle(
                        color: Color(0xFF212621),
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                    SizedBox(width: 12),
                    Text(
                      'Limpar conversa',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EF),
                borderRadius: BorderRadius.circular(12),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1,
          color: const Color(0xFF7C75B7).withAlpha(51),
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
            onTap: _navigateToPatientProfile,
            child: Container(
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(PatientMessage message) {
    final isPatient = message.isFromPatient;

    // Cores diferentes para cada tipo de remetente
    // Paciente: branco com borda
    // IA: roxo/lilás (gradiente)
    // Staff/Médico: marrom (cor principal)
    Color bubbleColor;
    Color textColor;
    bool showGradient = false;

    if (isPatient) {
      bubbleColor = Colors.white;
      textColor = const Color(0xFF212621);
    } else if (message.isFromAI) {
      // IA tem cor roxa/lilás para diferenciar
      bubbleColor = const Color(0xFF7C75B7);
      textColor = Colors.white;
      showGradient = true;
    } else {
      // Staff/Médico tem cor marrom (principal)
      bubbleColor = const Color(0xFF4F4A34);
      textColor = Colors.white;
    }

    // Label do remetente (para mensagens não-paciente)
    String senderLabel = '';
    IconData? senderIcon;
    if (!isPatient) {
      if (message.isFromAI) {
        senderLabel = 'Assistente IA';
        senderIcon = Icons.auto_awesome;
      } else {
        senderLabel = 'Equipe Médica';
        senderIcon = Icons.medical_services_outlined;
      }
    }

    return Align(
      alignment: isPatient ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: showGradient ? null : bubbleColor,
          gradient: showGradient
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9B93D5), Color(0xFF7C75B7)],
                )
              : null,
          borderRadius: BorderRadius.circular(24),
          border: isPatient
              ? Border.all(
                  width: 1,
                  color: const Color(0xFFE5E7EB),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header para mensagens do paciente
            if (isPatient) ...[
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
            // Header para mensagens não-paciente (IA ou Staff)
            if (!isPatient) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    senderIcon,
                    size: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    senderLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            // Audio player (se houver attachment de audio)
            if (message.hasAudioAttachment) ...[
              _buildAudioPlayerWidget(message.audioAttachment!, isFromPatient: isPatient),
              const SizedBox(height: 8),
            ],
            // Texto (ocultar se for mensagem padrao de audio)
            if (!_isAudioFallbackText(message))
              Text(
                message.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
              ),
            const SizedBox(height: 4),
            // Horário e status de leitura
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    color: isPatient
                        ? const Color(0xFF697282)
                        : Colors.white.withAlpha(179),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (!isPatient) ...[
                  const SizedBox(width: 4),
                  _buildMessageStatusIcon(message.status, isPatient),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o ícone de status da mensagem
  Widget _buildMessageStatusIcon(MessageStatus status, bool isPatient) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time,
          size: 14,
          color: isPatient ? const Color(0xFF697282) : Colors.white.withAlpha(179),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: isPatient ? const Color(0xFF697282) : Colors.white.withAlpha(179),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: isPatient ? const Color(0xFF697282) : Colors.white.withAlpha(179),
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Color(0xFF3B82F6), // Azul para lido
        );
    }
  }

  /// Verifica se o texto e apenas fallback de audio
  bool _isAudioFallbackText(PatientMessage message) {
    final text = message.text.trim();
    if (!message.hasAudioAttachment) return false;

    // Padroes de fallback a ocultar
    if (text == '[Mensagem de audio]' || text == '[Mensagem de áudio]') {
      return true;
    }
    if (text.startsWith('[Audio transcrito]:') || text.startsWith('[Áudio transcrito]:')) {
      return true;
    }
    if (text.isEmpty) return true;

    return false;
  }

  /// Constroi o widget de player de audio
  Widget _buildAudioPlayerWidget(PatientMessageAttachment attachment, {required bool isFromPatient}) {
    // Usa a URL do Supabase Storage se disponível, senão usa o endpoint do backend
    String audioUrl;
    if (attachment.playableUrl != null && attachment.playableUrl!.startsWith('http')) {
      // URL completa do Supabase Storage
      audioUrl = attachment.playableUrl!;
    } else {
      // URL do endpoint admin do backend
      audioUrl = '${ApiConfig.baseUrl}/chat/admin/audio/${attachment.id}/file';
    }

    debugPrint('[AUDIO_PLAYER] Playing from URL: $audioUrl (isFromPatient: $isFromPatient)');

    // Se for mensagem do paciente (fundo branco), usar cores padrão
    // Se for mensagem do staff/admin (fundo escuro), usar cores claras
    if (isFromPatient) {
      return AudioPlayerWidget(
        audioUrl: audioUrl,
        durationSeconds: attachment.durationSeconds,
        transcription: attachment.transcription,
        isFromUser: true,
        primaryColor: const Color(0xFF4F4A34),
      );
    } else {
      // Player customizado para fundo escuro (mensagem do staff)
      return _buildStaffAudioPlayer(audioUrl, attachment);
    }
  }

  /// Player de áudio customizado para mensagens do staff (fundo escuro)
  Widget _buildStaffAudioPlayer(String audioUrl, PatientMessageAttachment attachment) {
    return AudioPlayerWidget(
      audioUrl: audioUrl,
      durationSeconds: attachment.durationSeconds,
      transcription: attachment.transcription,
      isFromUser: false,
      primaryColor: Colors.white,
      isDarkBackground: true, // Fundo escuro das mensagens do staff
    );
  }

  /// Widget de indicador de digitação (3 pontinhos animados)
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            width: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
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
            const SizedBox(width: 8),
            const _TypingDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      'Como está se sentindo hoje?',
      'Alguma dúvida sobre medicação?',
      'Precisa remarcar consulta?',
      'Orientações pós-operatórias',
    ];

    return Container(
      color: Colors.white,
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
                  _sendAudioMessage(audioFile, durationSeconds);
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
            // Botão anexo (câmera/galeria)
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
            // Campo de texto - Expande com múltiplas linhas
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
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua mensagem...',
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
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botão IA sugerir resposta
            GestureDetector(
              onTap: _isGeneratingSuggestion ? null : _generateAISuggestion,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(0.00, 0.50),
                    end: Alignment(1.00, 0.50),
                    colors: [Color(0xFF7C75B7), Color(0xFF4F4A34)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C75B7).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isGeneratingSuggestion
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            // Botão microfone (gravar áudio) - só aparece quando não há texto
            if (_messageController.text.isEmpty)
              GestureDetector(
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
            if (_messageController.text.isEmpty)
              const SizedBox(width: 8),
            // Botão enviar - sempre visível
            GestureDetector(
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
          ],
        ],
      ),
    );
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
                              hintText: 'Adicione uma mensagem (opcional)...',
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
        ? 'Imagem com mensagem será enviada em breve!'
        : 'Envio de imagem em breve!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() => _selectedImage = null);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final now = TimeOfDay.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Adiciona mensagem localmente para feedback imediato (status: enviando)
    // Mensagens enviadas pelo admin são marcadas como 'staff'
    setState(() {
      _isSending = true;
      _messages.add(PatientMessage(
        isFromPatient: false,
        text: text,
        time: timeString,
        status: MessageStatus.sending,
        senderType: SenderType.staff, // Admin/médico enviando
      ));
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      // Usa o patientId para enviar mensagem (cria conversa se necessário)
      final patientId = widget.patient.id;
      debugPrint('[PATIENT_CHAT] Sending message to patient=$patientId');
      await _apiService.sendMessageToPatient(patientId, text);
      debugPrint('[PATIENT_CHAT] Message sent successfully');

      // Atualiza status para entregue após enviar
      if (mounted) {
        setState(() {
          final lastIndex = _messages.length - 1;
          if (lastIndex >= 0) {
            _messages[lastIndex] = PatientMessage(
              isFromPatient: false,
              text: text,
              time: timeString,
              status: MessageStatus.delivered,
              senderType: SenderType.staff,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[PATIENT_CHAT] Error sending message: $e');
      // Remove a mensagem otimista em caso de erro
      setState(() {
        _messages.removeLast();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar mensagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// Envia mensagem de áudio gravado pelo admin
  /// Faz upload para Supabase Storage e envia URL ao backend
  Future<void> _sendAudioMessage(File audioFile, int durationSeconds) async {
    if (_isSending) return;

    final now = TimeOfDay.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Formata duração
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final durationStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    setState(() {
      _isSending = true;
      // Mensagem temporária mostrando que está enviando
      // Não adiciona attachment ainda pois não tem URL para reproduzir
      _messages.add(PatientMessage(
        isFromPatient: false,
        text: 'Enviando áudio ($durationStr)...',
        time: timeString,
        status: MessageStatus.sending,
        senderType: SenderType.staff,
        attachments: [], // Sem attachment durante upload
      ));
    });

    _scrollToBottom();

    try {
      final patientId = widget.patient.id;
      final authProvider = context.read<AuthProvider>();
      final clinicId = authProvider.user?.clinicId ?? 'default-clinic';

      debugPrint('[PATIENT_CHAT] Uploading audio to Supabase Storage...');
      debugPrint('[PATIENT_CHAT] clinicId=$clinicId, patientId=$patientId');

      // Verifica se Supabase está disponível
      final audioUploadService = AudioUploadService();
      if (!audioUploadService.isSupabaseInitialized) {
        throw Exception('Supabase não está configurado. Verifique o arquivo .env');
      }

      // Faz upload para Supabase Storage
      final uploadResult = await audioUploadService.uploadAudio(
        audioFile: audioFile,
        clinicId: clinicId,
        patientId: patientId,
      );

      debugPrint('[PATIENT_CHAT] Audio uploaded! URL: ${uploadResult.url}');

      // Envia mensagem com URL do áudio ao backend
      await _apiService.sendMessageToPatient(
        patientId,
        '[Mensagem de áudio]',
        audioUrl: uploadResult.url,
        audioDuration: durationSeconds,
      );

      debugPrint('[PATIENT_CHAT] Audio message sent successfully');

      if (mounted) {
        setState(() {
          final lastIndex = _messages.length - 1;
          if (lastIndex >= 0) {
            debugPrint('[PATIENT_CHAT] Updating message with audio URL: ${uploadResult.url}');
            _messages[lastIndex] = PatientMessage(
              isFromPatient: false,
              text: '[Mensagem de áudio]', // Texto padrão que será ocultado pelo player
              time: timeString,
              status: MessageStatus.delivered,
              senderType: SenderType.staff,
              attachments: [
                PatientMessageAttachment(
                  id: 'audio_${DateTime.now().millisecondsSinceEpoch}',
                  type: 'AUDIO',
                  mimeType: 'audio/m4a',
                  durationSeconds: durationSeconds,
                  audioUrl: uploadResult.url,
                  storagePath: uploadResult.url, // Também salva no storagePath
                ),
              ],
            );
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[PATIENT_CHAT] Error sending audio message: $e');
      setState(() {
        _messages.removeLast();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar áudio: $e'),
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

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  /// Navega para a tela de detalhes do paciente
  void _navigateToPatientProfile() {
    debugPrint('[NAV] opening PatientDetails patientId=${widget.patient.id} source=patient_chat');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => PatientsProvider(),
          child: PatientDetailScreen(
            patientId: widget.patient.id,
            patientName: widget.patient.name,
            phone: '', // Telefone não disponível no contexto atual
            surgeryType: widget.patient.procedure,
            surgeryDate: null, // Data da cirurgia calculada a partir de daysPostOp se necessário
          ),
        ),
      ),
    );
  }

  /// Mostra diálogo de confirmação para limpar o chat
  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 12),
            Text(
              'Limpar conversa',
              style: TextStyle(
                color: Color(0xFF212621),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Tem certeza que deseja limpar todas as mensagens desta conversa com ${widget.patient.name}?\n\nEsta ação não pode ser desfeita.',
          style: const TextStyle(
            color: Color(0xFF495565),
            fontSize: 14,
            fontFamily: 'Inter',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF697282),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Limpar',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Limpa as mensagens do chat (local, servidor e áudios no Supabase)
  Future<void> _clearChat() async {
    try {
      // Chama a API para limpar a conversa no servidor
      final patientId = widget.patient.id;
      final authProvider = context.read<AuthProvider>();
      final clinicId = authProvider.user?.clinicId ?? 'default-clinic';

      debugPrint('[PATIENT_CHAT] Clearing chat for patient=$patientId');

      // 1. Deleta os áudios do Supabase Storage
      final audioUploadService = AudioUploadService();
      if (audioUploadService.isSupabaseInitialized) {
        debugPrint('[PATIENT_CHAT] Deleting audio files from Supabase...');
        final deletedCount = await audioUploadService.deleteAllAudiosForPatient(
          clinicId: clinicId,
          patientId: patientId,
        );
        debugPrint('[PATIENT_CHAT] Deleted $deletedCount audio files');
      }

      // 2. Limpa a conversa no backend
      await _apiService.clearPatientConversation(patientId);

      // 3. Limpa as mensagens localmente
      setState(() {
        _messages.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Conversa e áudios limpos com sucesso'),
              ],
            ),
            backgroundColor: Color(0xFF22C55E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[PATIENT_CHAT] Error clearing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao limpar conversa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Gera uma sugestão de resposta usando IA baseado no contexto da conversa
  Future<void> _generateAISuggestion() async {
    if (_isGeneratingSuggestion || _messages.isEmpty) return;

    setState(() {
      _isGeneratingSuggestion = true;
    });

    try {
      // Busca as últimas mensagens do paciente para contexto
      final patientMessages = _messages
          .where((m) => m.isFromPatient)
          .toList();

      if (patientMessages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma mensagem do paciente para analisar'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return;
      }

      // Pega a última mensagem do paciente
      final lastPatientMessage = patientMessages.last.text;

      // Monta o contexto com histórico recente
      final recentHistory = _messages.take(10).map((m) {
        final role = m.isFromPatient ? 'Paciente' : 'Equipe';
        return '$role: ${m.text}';
      }).join('\n');

      // System prompt específico para sugestão de resposta (tom de secretária da clínica)
      const systemPrompt = '''Voce e uma secretaria virtual da Clinica Scheibell, auxiliando a equipe medica a responder pacientes.

Sua tarefa e GERAR UMA SUGESTAO DE RESPOSTA para o paciente baseado na mensagem dele.

CONTEXTO DO PACIENTE:
- Nome: [PATIENT_NAME]
- Procedimento: [PROCEDURE]
- Dias pos-operatorio: [DAYS_POST_OP]

DIRETRIZES PARA A RESPOSTA SUGERIDA:
1. Seja acolhedora, educada e profissional (como uma secretaria atenciosa)
2. Use linguagem simples, clara e humanizada
3. Responda diretamente a duvida ou preocupacao do paciente
4. Para questoes medicas especificas, diga que vai comunicar nosso doutor/nossa equipe medica
5. Para sintomas preocupantes, diga que vai encaminhar para avaliacao do doutor com urgencia
6. Mantenha a resposta concisa (2-3 frases)
7. NAO use saudacao inicial (o contexto ja esta estabelecido)
8. NAO mencione pronto-socorro ou outras clinicas - o paciente ja esta em contato conosco
9. Use "nosso doutor", "nossa equipe", "vamos verificar", "ja estou encaminhando"

EXEMPLOS DE TOM:
- "Entendo sua preocupacao! Vou comunicar nosso doutor sobre isso para que ele possa orientar voce melhor."
- "Fico feliz que esteja se recuperando bem! Qualquer duvida, estamos aqui."
- "Vou encaminhar sua mensagem para nossa equipe medica avaliar. Em breve entraremos em contato."

IMPORTANTE: Retorne APENAS o texto da resposta sugerida, sem explicacoes ou formatacao adicional.''';

      // Substitui as variaveis de contexto
      final contextualPrompt = systemPrompt
          .replaceAll('[PATIENT_NAME]', widget.patient.name)
          .replaceAll('[PROCEDURE]', widget.patient.procedure)
          .replaceAll('[DAYS_POST_OP]', '${widget.patient.daysPostOp}');

      // Monta as mensagens para a OpenAI
      final messages = <domain.ChatMessage>[
        domain.ChatMessage.fromUser(
          'Historico recente da conversa:\n$recentHistory\n\nUltima mensagem do paciente: "$lastPatientMessage"\n\nGere uma sugestao de resposta apropriada.',
        ),
      ];

      // Chama a OpenAI
      final response = await _aiDatasource.sendMessageWithCustomPrompt(
        messages,
        contextualPrompt,
      );

      if (response.isError) {
        throw Exception(response.content);
      }

      // Coloca a sugestão no campo de texto
      setState(() {
        _messageController.text = response.content;
      });

      // Feedback visual
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Sugestão gerada! Revise e envie.')),
              ],
            ),
            backgroundColor: Color(0xFF4F4A34),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[AI_SUGGEST] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar sugestão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSuggestion = false;
        });
      }
    }
  }

  // ===== BOTTOM NAVIGATION BAR =====
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Painel',
                route: '/clinic-dashboard',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Pacientes',
                route: '/clinic-patients',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Chat',
                route: '/clinic-chat',
                isSelected: true, // Chat está ativo nesta tela
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'Conteúdos',
                route: '/clinic-content-management',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month,
                label: 'Calendário',
                route: '/clinic-calendar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F4A34).withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF4F4A34) : const Color(0xFF697282),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4F4A34) : const Color(0xFF697282),
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status de entrega/leitura da mensagem
enum MessageStatus {
  sending,    // Enviando (relógio)
  sent,       // Enviado (1 check)
  delivered,  // Entregue (2 checks cinza)
  read,       // Lido (2 checks azul)
}

/// Tipo de remetente da mensagem
enum SenderType {
  patient,  // Mensagem do paciente
  ai,       // Resposta da IA
  staff,    // Resposta do médico/equipe
}

/// Representa um attachment na mensagem (imagem ou audio)
class PatientMessageAttachment {
  final String id;
  final String type; // 'IMAGE' ou 'AUDIO'
  final String? mimeType;
  final int? durationSeconds;
  final String? transcription;
  final String? audioUrl; // URL do áudio no Supabase Storage
  final String? storagePath; // Path relativo no storage

  PatientMessageAttachment({
    required this.id,
    required this.type,
    this.mimeType,
    this.durationSeconds,
    this.transcription,
    this.audioUrl,
    this.storagePath,
  });

  bool get isAudio => type == 'AUDIO';
  bool get isImage => type == 'IMAGE';

  /// Retorna a URL do áudio (storagePath pode ser uma URL completa do Supabase)
  String? get playableUrl => audioUrl ?? storagePath;
}

class PatientMessage {
  final bool isFromPatient;
  final String text;
  final String time;
  final MessageStatus status;
  final SenderType senderType;
  final List<PatientMessageAttachment> attachments;

  PatientMessage({
    required this.isFromPatient,
    required this.text,
    required this.time,
    this.status = MessageStatus.sent,
    this.senderType = SenderType.patient,
    this.attachments = const [],
  });

  /// Verifica se a mensagem é da IA
  bool get isFromAI => senderType == SenderType.ai;

  /// Verifica se a mensagem é do staff/médico
  bool get isFromStaff => senderType == SenderType.staff;

  /// Verifica se tem attachment de audio
  bool get hasAudioAttachment => attachments.any((a) => a.isAudio);

  /// Retorna o primeiro attachment de audio
  PatientMessageAttachment? get audioAttachment =>
      attachments.where((a) => a.isAudio).firstOrNull;
}

/// Widget animado de 3 pontinhos para indicar que alguém está digitando
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + (0.5 * (1 - (2 * value - 1).abs()));
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
