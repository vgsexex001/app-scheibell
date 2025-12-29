import 'package:flutter/material.dart';

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
  // Mock de dados do paciente - virá da API
  late _PatientDetail _patient;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  void _loadPatientData() {
    // Mock - substituir por chamada API
    _patient = _PatientDetail(
      id: widget.patientId,
      name: widget.patientName,
      email: '${widget.patientName.toLowerCase().replaceAll(' ', '.')}@email.com',
      phone: widget.phone,
      birthDate: DateTime(1985, 5, 15),
      cpf: '123.456.789-00',
      address: 'Rua das Flores, 123 - São Paulo, SP',
      surgeryType: widget.surgeryType ?? 'Não definido',
      surgeryDate: widget.surgeryDate,
      surgeon: 'Dr. Carlos Mendes',
      medicalNotes: 'Paciente com boa evolução. Seguir protocolo padrão.',
      allergies: ['Dipirona', 'Látex'],
      medications: ['Paracetamol 500mg', 'Antibiótico 8/8h'],
      emergencyContact: 'João Silva - (11) 98888-7777',
      bloodType: 'O+',
      weight: 68.5,
      height: 165,
    );
  }

  int get _daysPostOp {
    if (widget.surgeryDate == null) return 0;
    return DateTime.now().difference(widget.surgeryDate!).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientCard(),
                    const SizedBox(height: 16),
                    if (widget.surgeryDate != null) ...[
                      _buildSurgeryInfo(),
                      const SizedBox(height: 16),
                    ],
                    _buildPersonalInfo(),
                    const SizedBox(height: 16),
                    _buildMedicalInfo(),
                    const SizedBox(height: 16),
                    _buildAllergiesAndMeds(),
                    const SizedBox(height: 16),
                    _buildNotes(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  widget.patientName,
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
              // TODO: Implementar ações
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar Paciente')),
              const PopupMenuItem(value: 'history', child: Text('Histórico')),
              const PopupMenuItem(value: 'documents', child: Text('Documentos')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard() {
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
                _getInitials(widget.patientName),
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
                  widget.patientName,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phone,
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
                if (widget.surgeryDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF155CFB).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Dia $_daysPostOp pós-operatório',
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
                onTap: () {
                  // TODO: Ligar
                },
              ),
              const SizedBox(height: 8),
              _CircleButton(
                icon: Icons.message,
                color: const Color(0xFF25D366),
                onTap: () {
                  // TODO: WhatsApp
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeryInfo() {
    return _SectionCard(
      title: 'Informações da Cirurgia',
      icon: Icons.medical_services_outlined,
      child: Column(
        children: [
          _InfoRow(label: 'Procedimento', value: widget.surgeryType ?? '-'),
          _InfoRow(
            label: 'Data da Cirurgia',
            value: widget.surgeryDate != null
                ? '${widget.surgeryDate!.day}/${widget.surgeryDate!.month}/${widget.surgeryDate!.year}'
                : '-',
          ),
          _InfoRow(label: 'Cirurgião', value: _patient.surgeon),
          _InfoRow(label: 'Dias Pós-Op', value: '$_daysPostOp dias'),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _SectionCard(
      title: 'Dados Pessoais',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _InfoRow(label: 'Email', value: _patient.email),
          _InfoRow(
            label: 'Data de Nascimento',
            value: '${_patient.birthDate.day}/${_patient.birthDate.month}/${_patient.birthDate.year}',
          ),
          _InfoRow(label: 'CPF', value: _patient.cpf),
          _InfoRow(label: 'Endereço', value: _patient.address),
          _InfoRow(label: 'Contato de Emergência', value: _patient.emergencyContact),
        ],
      ),
    );
  }

  Widget _buildMedicalInfo() {
    return _SectionCard(
      title: 'Informações Médicas',
      icon: Icons.favorite_outline,
      child: Column(
        children: [
          _InfoRow(label: 'Tipo Sanguíneo', value: _patient.bloodType),
          _InfoRow(label: 'Peso', value: '${_patient.weight} kg'),
          _InfoRow(label: 'Altura', value: '${_patient.height} cm'),
          _InfoRow(label: 'IMC', value: _calculateIMC()),
        ],
      ),
    );
  }

  Widget _buildAllergiesAndMeds() {
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
              children: _patient.allergies.isEmpty
                  ? [const Text('Nenhuma alergia registrada', style: TextStyle(color: Color(0xFF495565), fontSize: 14))]
                  : _patient.allergies.map((allergy) => Padding(
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
                          Text(
                            allergy,
                            style: const TextStyle(
                              color: Color(0xFF212621),
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Medicações
        Expanded(
          child: _SectionCard(
            title: 'Medicações',
            icon: Icons.medication_outlined,
            iconColor: const Color(0xFF155CFB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _patient.medications.isEmpty
                  ? [const Text('Nenhuma medicação', style: TextStyle(color: Color(0xFF495565), fontSize: 14))]
                  : _patient.medications.map((med) => Padding(
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
                              med,
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

  Widget _buildNotes() {
    return _SectionCard(
      title: 'Observações Médicas',
      icon: Icons.notes_outlined,
      child: Text(
        _patient.medicalNotes.isEmpty ? 'Nenhuma observação registrada.' : _patient.medicalNotes,
        style: const TextStyle(
          color: Color(0xFF495565),
          fontSize: 14,
          fontFamily: 'Inter',
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botão principal: Ajustar Conteúdos
        GestureDetector(
          onTap: () {
            // TODO: Navegar para tela de ajustes de conteúdo do paciente
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navegar para ajustes de conteúdo')),
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
                onTap: () {
                  // TODO
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.history,
                label: 'Ver Histórico',
                onTap: () {
                  // TODO
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

  String _calculateIMC() {
    final heightM = _patient.height / 100;
    final imc = _patient.weight / (heightM * heightM);
    return imc.toStringAsFixed(1);
  }
}

// ==================== MODEL ====================

class _PatientDetail {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime birthDate;
  final String cpf;
  final String address;
  final String surgeryType;
  final DateTime? surgeryDate;
  final String surgeon;
  final String medicalNotes;
  final List<String> allergies;
  final List<String> medications;
  final String emergencyContact;
  final String bloodType;
  final double weight;
  final int height;

  _PatientDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.cpf,
    required this.address,
    required this.surgeryType,
    this.surgeryDate,
    required this.surgeon,
    required this.medicalNotes,
    required this.allergies,
    required this.medications,
    required this.emergencyContact,
    required this.bloodType,
    required this.weight,
    required this.height,
  });
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
