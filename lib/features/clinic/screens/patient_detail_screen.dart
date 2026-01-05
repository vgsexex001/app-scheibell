import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/patients_provider.dart';
import '../models/patient_detail.dart';
import 'patient_history_screen.dart';
import 'patient_content_adjustments_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String phone;
  final String? surgeryType;
  final DateTime? surgeryDate;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.phone,
    this.surgeryType,
    this.surgeryDate,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega detalhes do paciente via API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[PATIENT_DETAILS] init patientId=${widget.patientId}');
      debugPrint('[PATIENT_DETAILS] patientName=${widget.patientName}');
      debugPrint('[PATIENT_DETAILS] phone=${widget.phone}');

      // Health check em debug para verificar conectividade
      if (kDebugMode) {
        _debugHealthCheck();
      }

      context.read<PatientsProvider>().loadPatientDetail(widget.patientId);
    });
  }

  /// Health check para debug - verifica se backend está acessível
  Future<void> _debugHealthCheck() async {
    debugPrint('[DEBUG] ========== HEALTH CHECK ==========');
    debugPrint('[DEBUG] Base URL: ${ApiConfig.baseUrl}');
    debugPrint('[DEBUG] Patients endpoint: ${ApiConfig.patientsEndpoint}');
    debugPrint('[DEBUG] Full URL: ${ApiConfig.baseUrl}${ApiConfig.patientsEndpoint}/${widget.patientId}');

    try {
      final apiService = ApiService();
      final healthy = await apiService.healthCheck();
      debugPrint('[DEBUG] Health check result: ${healthy ? "OK ✅" : "FAIL ❌"}');
    } catch (e) {
      debugPrint('[DEBUG] Health check ERROR: $e');
    }
    debugPrint('[DEBUG] ====================================');
  }

  @override
  void dispose() {
    // Limpa paciente selecionado ao sair
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PatientsProvider>().clearSelectedPatient();
      }
    });
    super.dispose();
  }

  // ==================== AÇÕES ====================

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel abrir o discador')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneWithCountry = cleanPhone.startsWith('55') ? cleanPhone : '55$cleanPhone';
    final url = Uri.parse('https://wa.me/$phoneWithCountry');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel abrir o WhatsApp')),
        );
      }
    }
  }

  void _showAddAllergyDialog() {
    final nameController = TextEditingController();
    String? selectedSeverity;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adicionar Alergia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da alergia',
                  hintText: 'Ex: Dipirona, Penicilina',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Gravidade'),
                value: selectedSeverity,
                items: const [
                  DropdownMenuItem(value: 'MILD', child: Text('Leve')),
                  DropdownMenuItem(value: 'MODERATE', child: Text('Moderada')),
                  DropdownMenuItem(value: 'SEVERE', child: Text('Grave')),
                ],
                onChanged: (v) => setDialogState(() => selectedSeverity = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe o nome da alergia')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                final provider = this.context.read<PatientsProvider>();
                final success = await provider.addAllergy(
                  widget.patientId,
                  name: nameController.text.trim(),
                  severity: selectedSeverity,
                );

                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Alergia adicionada com sucesso'
                            : provider.error ?? 'Erro ao adicionar alergia',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F4A34),
              ),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adicionar Nota Medica'),
        content: TextField(
          controller: contentController,
          decoration: const InputDecoration(
            labelText: 'Observacao',
            hintText: 'Digite a observacao medica...',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (contentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe o conteudo da nota')),
                );
                return;
              }

              Navigator.pop(dialogContext);

              final provider = this.context.read<PatientsProvider>();
              final success = await provider.addMedicalNote(
                widget.patientId,
                content: contentController.text.trim(),
              );

              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Nota adicionada com sucesso'
                          : provider.error ?? 'Erro ao adicionar nota',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F4A34),
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showCreateAppointmentDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    String selectedType = 'RETURN_VISIT';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agendar Consulta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titulo'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'RETURN_VISIT', child: Text('Retorno')),
                    DropdownMenuItem(value: 'EVALUATION', child: Text('Avaliacao')),
                    DropdownMenuItem(value: 'PHYSIOTHERAPY', child: Text('Fisioterapia')),
                    DropdownMenuItem(value: 'EXAM', child: Text('Exame')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Outro')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data'),
                  subtitle: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Horario'),
                  subtitle: Text(
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Local (opcional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe o titulo da consulta')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                final provider = this.context.read<PatientsProvider>();
                final dateStr = selectedDate.toIso8601String().split('T')[0];
                final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                final success = await provider.createAppointment(
                  widget.patientId,
                  title: titleController.text.trim(),
                  date: dateStr,
                  time: timeStr,
                  type: selectedType,
                  description: descriptionController.text.isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  location: locationController.text.isNotEmpty
                      ? locationController.text.trim()
                      : null,
                );

                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Consulta agendada com sucesso'
                            : provider.error ?? 'Erro ao agendar consulta',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F4A34),
              ),
              child: const Text('Agendar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        top: false,
        child: Consumer<PatientsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingDetail) {
              return Column(
                children: [
                  _buildHeader(null),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F4A34),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (provider.error != null) {
              return Column(
                children: [
                  _buildHeader(null),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFFE7000B),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: const TextStyle(
                              color: Color(0xFF495565),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              provider.loadPatientDetail(widget.patientId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F4A34),
                            ),
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final patient = provider.selectedPatient;
            if (patient == null) {
              return Column(
                children: [
                  _buildHeader(null),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Paciente não encontrado',
                        style: TextStyle(
                          color: Color(0xFF495565),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildHeader(patient),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPatientCard(patient),
                        const SizedBox(height: 16),
                        if (patient.surgeryDate != null) ...[
                          _buildSurgeryInfo(patient),
                          const SizedBox(height: 16),
                        ],
                        _buildPersonalInfo(patient),
                        const SizedBox(height: 16),
                        _buildMedicalInfo(patient),
                        const SizedBox(height: 16),
                        _buildAllergiesAndMeds(patient),
                        const SizedBox(height: 16),
                        _buildNotes(patient),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(PatientDetail? patient) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF4F4A34),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(51)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalhes do Paciente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  patient?.name ?? widget.patientName,
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          // Menu de ações
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              final provider = context.read<PatientsProvider>();
              final patientData = provider.selectedPatient;
              switch (value) {
                case 'history':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: PatientHistoryScreen(
                          patientId: widget.patientId,
                          patientName: patientData?.name ?? widget.patientName,
                        ),
                      ),
                    ),
                  );
                  break;
                case 'add_allergy':
                  _showAddAllergyDialog();
                  break;
                case 'add_note':
                  _showAddNoteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'history', child: Text('Ver Historico')),
              const PopupMenuItem(value: 'add_allergy', child: Text('Adicionar Alergia')),
              const PopupMenuItem(value: 'add_note', child: Text('Adicionar Nota')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientDetail patient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF4F4A34),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _getInitials(patient.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  patient.phone ?? widget.phone,
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
                if (patient.dayPostOp != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF155CFB).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      patient.dayPostOpLabel,
                      style: const TextStyle(
                        color: Color(0xFF155CFB),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Botões de contato
          Column(
            children: [
              _CircleButton(
                icon: Icons.phone,
                color: const Color(0xFF00A63E),
                onTap: () => _makePhoneCall(patient.phone ?? widget.phone),
              ),
              const SizedBox(height: 8),
              _CircleButton(
                icon: Icons.message,
                color: const Color(0xFF25D366),
                onTap: () => _openWhatsApp(patient.phone ?? widget.phone),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeryInfo(PatientDetail patient) {
    return _SectionCard(
      title: 'Informações da Cirurgia',
      icon: Icons.medical_services_outlined,
      child: Column(
        children: [
          _InfoRow(label: 'Procedimento', value: patient.surgeryType ?? '-'),
          _InfoRow(
            label: 'Data da Cirurgia',
            value: patient.surgeryDateFormatted,
          ),
          _InfoRow(label: 'Cirurgião', value: patient.surgeon ?? '-'),
          _InfoRow(label: 'Dias Pós-Op', value: patient.dayPostOp != null ? '${patient.dayPostOp} dias' : '-'),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(PatientDetail patient) {
    String birthDateFormatted = '-';
    if (patient.birthDate != null) {
      try {
        final dt = DateTime.parse(patient.birthDate!);
        birthDateFormatted = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (e) {
        birthDateFormatted = patient.birthDate!;
      }
    }

    return _SectionCard(
      title: 'Dados Pessoais',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _InfoRow(label: 'Email', value: patient.email),
          _InfoRow(label: 'Data de Nascimento', value: birthDateFormatted),
          _InfoRow(label: 'CPF', value: patient.cpf ?? '-'),
          _InfoRow(label: 'Endereço', value: patient.address ?? '-'),
          _InfoRow(label: 'Contato de Emergência', value: patient.emergencyContact ?? '-'),
        ],
      ),
    );
  }

  Widget _buildMedicalInfo(PatientDetail patient) {
    return _SectionCard(
      title: 'Informacoes Medicas',
      icon: Icons.favorite_outline,
      child: Column(
        children: [
          _InfoRow(label: 'Tipo Sanguineo', value: patient.bloodType ?? '-'),
          _InfoRow(label: 'Peso', value: patient.weightKg != null ? '${patient.weightKg} kg' : '-'),
          _InfoRow(label: 'Altura', value: patient.heightCm != null ? '${patient.heightCm!.toInt()} cm' : '-'),
          _InfoRow(label: 'IMC', value: patient.imcFormatted),
          if (patient.emergencyContact != null) ...[
            _InfoRow(label: 'Contato Emerg.', value: patient.emergencyContact!),
          ],
          if (patient.emergencyPhone != null) ...[
            _InfoRow(label: 'Tel. Emerg.', value: patient.emergencyPhone!),
          ],
        ],
      ),
    );
  }

  Widget _buildAllergiesAndMeds(PatientDetail patient) {
    final allergies = patient.allergies;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alergias
        Expanded(
          child: _SectionCard(
            title: 'Alergias',
            icon: Icons.warning_amber_outlined,
            iconColor: const Color(0xFFE7000B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: allergies.isEmpty
                  ? [const Text('Nenhuma alergia registrada', style: TextStyle(color: Color(0xFF495565), fontSize: 14))]
                  : allergies.map((allergy) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE7000B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              allergy.name,
                              style: const TextStyle(
                                color: Color(0xFF212621),
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Medicações - usando dados das consultas/alertas já que não temos campo específico
        Expanded(
          child: _SectionCard(
            title: 'Próximas Consultas',
            icon: Icons.calendar_today_outlined,
            iconColor: const Color(0xFF155CFB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: patient.upcomingAppointments.isEmpty
                  ? [const Text('Nenhuma consulta agendada', style: TextStyle(color: Color(0xFF495565), fontSize: 14))]
                  : patient.upcomingAppointments.take(3).map((apt) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF155CFB),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${apt.displayDate} - ${apt.title}',
                              style: const TextStyle(
                                color: Color(0xFF212621),
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(PatientDetail patient) {
    final notes = patient.medicalNotes;

    return _SectionCard(
      title: 'Observações Médicas',
      icon: Icons.notes_outlined,
      child: notes.isEmpty
          ? const Text(
              'Nenhuma observação registrada.',
              style: TextStyle(
                color: Color(0xFF495565),
                fontSize: 14,
                fontFamily: 'Inter',
                height: 1.5,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: notes.take(5).map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.content,
                      style: const TextStyle(
                        color: Color(0xFF212621),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        height: 1.5,
                      ),
                    ),
                    Text(
                      '${note.author ?? 'Anônimo'} - ${note.displayDate}',
                      style: const TextStyle(
                        color: Color(0xFF495565),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botão principal: Ajustar Conteúdos
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientContentAdjustmentsScreen(
                  patientId: widget.patientId,
                  patientName: context.read<PatientsProvider>().selectedPatient?.name ?? 'Paciente',
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4F4A34),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Ajustar Conteúdos do Paciente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Botões secundários
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: Icons.calendar_today_outlined,
                label: 'Agendar Consulta',
                onTap: _showCreateAppointmentDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.history,
                label: 'Ver Histórico',
                onTap: () {
                  final provider = context.read<PatientsProvider>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: PatientHistoryScreen(
                          patientId: widget.patientId,
                          patientName: provider.selectedPatient?.name ?? 'Paciente',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.substring(0, 2).toUpperCase();
  }
}

// ==================== WIDGETS ====================

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor ?? const Color(0xFF4F4A34)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF495565),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8C2B4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF4F4A34), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
