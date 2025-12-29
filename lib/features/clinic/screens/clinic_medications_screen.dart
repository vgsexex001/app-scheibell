import 'package:flutter/material.dart';

class ClinicMedicationsScreen extends StatefulWidget {
  const ClinicMedicationsScreen({super.key});

  @override
  State<ClinicMedicationsScreen> createState() => _ClinicMedicationsScreenState();
}

class _ClinicMedicationsScreenState extends State<ClinicMedicationsScreen> {
  String _searchQuery = '';

  // Mock data - será substituído por chamadas de API
  final List<_PatientItem> _patients = [
    _PatientItem(
      'PAC-2024-0157',
      'Maria Silva',
      'MS',
      'Abdominoplastia',
      '28 Nov 2024',
      'Em Recuperação',
    ),
    _PatientItem(
      'PAC-2024-0143',
      'João Santos',
      'JS',
      'Rinoplastia',
      '15 Nov 2024',
      'Em Recuperação',
    ),
    _PatientItem(
      'PAC-2024-0138',
      'Ana Costa',
      'AC',
      'Lipoaspiração',
      '10 Nov 2024',
      'Alta',
    ),
  ];

  List<_PatientItem> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    return _patients.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      p.id.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7D1C5),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPatientSelector(),
                    const SizedBox(height: 16),
                    _buildSelectPatientCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectPatientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: Color(0xFF697282),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Selecione um paciente',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF495565),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'para visualizar e gerenciar\nas medicações prescritas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF697282),
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFD7D1C5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA49E86)),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF4F4A34), size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Medicações',
            style: TextStyle(
              color: Color(0xFF4F4A34),
              fontSize: 24,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF4F4A34),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_search_outlined, color: Color(0xFF212621), size: 20),
              SizedBox(width: 8),
              Text(
                'Selecione um Paciente',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search field
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF697282), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: 'Buscar paciente...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
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
          const SizedBox(height: 12),
          // Patient list with scroll
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: _filteredPatients.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Nenhum paciente encontrado',
                        style: TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredPatients.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final patient = _filteredPatients[index];
                      return _PatientCard(
                        patient: patient,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _PatientMedicationsDetailScreen(patient: patient),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== PATIENT MEDICATIONS DETAIL SCREEN ====================

class _PatientMedicationsDetailScreen extends StatefulWidget {
  final _PatientItem patient;

  const _PatientMedicationsDetailScreen({required this.patient});

  @override
  State<_PatientMedicationsDetailScreen> createState() => _PatientMedicationsDetailScreenState();
}

class _PatientMedicationsDetailScreenState extends State<_PatientMedicationsDetailScreen> {
  // Mock data - será substituído por chamadas de API
  List<_MedicationItem> _medications = [
    _MedicationItem(
      '1',
      'Paracetamol',
      '750mg',
      '8 em 8 horas',
      '7 dias',
      'Tomar com água, após as refeições',
      true,
    ),
    _MedicationItem(
      '2',
      'Ibuprofeno',
      '400mg',
      '12 em 12 horas',
      '5 dias',
      'Tomar junto com alimentos',
      true,
    ),
    _MedicationItem(
      '3',
      'Amoxicilina',
      '500mg',
      '8 em 8 horas',
      '10 dias',
      'Não interromper o tratamento',
      true,
    ),
    _MedicationItem(
      '4',
      'Dipirona',
      '1g',
      '6 em 6 horas (se dor)',
      'Conforme necessidade',
      'Usar apenas em caso de dor moderada a forte',
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7D1C5),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildPatientInfo(),
            _buildAddMedicationButton(),
            Expanded(
              child: _buildMedicationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFD7D1C5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA49E86)),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF4F4A34), size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Medicações',
            style: TextStyle(
              color: Color(0xFF4F4A34),
              fontSize: 24,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    final patient = widget.patient;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F4A34), Color(0xFF212621)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withAlpha(77),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                patient.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  patient.id,
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMedicationButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showAddMedicationModal,
        child: Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF4F4A34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Adicionar Medicação',
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
    );
  }

  Widget _buildMedicationsList() {
    if (_medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication_outlined, color: Color(0xFF697282), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma medicação cadastrada',
              style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque em "Adicionar Medicação"',
              style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final medication = _medications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MedicationCard(
            medication: medication,
            onDelete: () => _deleteMedication(medication.id),
            onEdit: () => _showEditMedicationModal(medication),
            onToggleActive: () => _toggleMedicationActive(medication),
          ),
        );
      },
    );
  }

  void _toggleMedicationActive(_MedicationItem medication) {
    setState(() {
      final idx = _medications.indexWhere((m) => m.id == medication.id);
      if (idx != -1) {
        _medications[idx] = medication.copyWith(isActive: !medication.isActive);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(medication.isActive ? 'Medicação desativada' : 'Medicação ativada'),
      ),
    );
  }

  void _deleteMedication(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir medicação?'),
        content: const Text('Esta medicação será removida permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _medications.removeWhere((m) => m.id == id));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Medicação excluída')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE7000B)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAddMedicationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MedicationFormModal(
        onSave: (name, dose, frequency, duration, instructions) {
          setState(() {
            _medications.add(_MedicationItem(
              DateTime.now().millisecondsSinceEpoch.toString(),
              name,
              dose,
              frequency,
              duration,
              instructions,
              true,
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicação adicionada')),
          );
        },
      ),
    );
  }

  void _showEditMedicationModal(_MedicationItem medication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MedicationFormModal(
        medication: medication,
        onSave: (name, dose, frequency, duration, instructions) {
          setState(() {
            final idx = _medications.indexWhere((m) => m.id == medication.id);
            if (idx != -1) {
              _medications[idx] = medication.copyWith(
                name: name,
                dose: dose,
                frequency: frequency,
                duration: duration,
                instructions: instructions,
              );
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicação atualizada')),
          );
        },
      ),
    );
  }
}

// ==================== MODELS ====================

class _PatientItem {
  final String id, name, initials, procedure, date, status;

  _PatientItem(this.id, this.name, this.initials, this.procedure, this.date, this.status);
}

class _MedicationItem {
  final String id, name, dose, frequency, duration, instructions;
  final bool isActive;

  _MedicationItem(this.id, this.name, this.dose, this.frequency, this.duration, this.instructions, this.isActive);

  _MedicationItem copyWith({
    String? name,
    String? dose,
    String? frequency,
    String? duration,
    String? instructions,
    bool? isActive,
  }) {
    return _MedicationItem(
      id,
      name ?? this.name,
      dose ?? this.dose,
      frequency ?? this.frequency,
      duration ?? this.duration,
      instructions ?? this.instructions,
      isActive ?? this.isActive,
    );
  }
}

// ==================== PATIENT CARD ====================

class _PatientCard extends StatelessWidget {
  final _PatientItem patient;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x4CA49E86),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x334E4A33)),
              ),
              child: Center(
                child: Text(
                  patient.initials,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: patient.status == 'Em Recuperação'
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          patient.status,
                          style: TextStyle(
                            color: patient.status == 'Em Recuperação'
                                ? const Color(0xFF008235)
                                : const Color(0xFF697282),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${patient.id}',
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '${patient.procedure} • ${patient.date}',
                    style: const TextStyle(
                      color: Color(0xFF697282),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF697282), size: 20),
          ],
        ),
      ),
    );
  }
}

// ==================== MEDICATION CARD ====================

class _MedicationCard extends StatelessWidget {
  final _MedicationItem medication;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _MedicationCard({
    required this.medication,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com nome e status
          Row(
            children: [
              const Icon(Icons.medication_outlined, size: 16, color: Color(0xFF697282)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  medication.name,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: medication.isActive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  medication.isActive ? 'Ativo' : 'Inativo',
                  style: TextStyle(
                    color: medication.isActive
                        ? const Color(0xFF008235)
                        : const Color(0xFF697282),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Detalhes da medicação
          _buildDetailRow('Dose:', medication.dose),
          const SizedBox(height: 4),
          _buildDetailRow('Frequência:', medication.frequency),
          const SizedBox(height: 4),
          _buildDetailRow('Duração:', medication.duration),
          const SizedBox(height: 8),
          // Instruções
          Text(
            medication.instructions,
            style: const TextStyle(
              color: Color(0xFF495565),
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          // Divisor
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
          const SizedBox(height: 12),
          // Botões de ação
          Row(
            children: [
              // Botão Desativar/Ativar
              Expanded(
                child: GestureDetector(
                  onTap: onToggleActive,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: medication.isActive
                          ? const Color(0xFFD08700)
                          : const Color(0xFF008235),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: medication.isActive
                            ? const Color(0xFFFFDF20)
                            : const Color(0xFF00B341),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        medication.isActive ? 'Desativar' : 'Ativar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botão Editar
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF155DFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF8DC5FF)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Editar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botão Excluir
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 38,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7000B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8C2B4)),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF495565),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF101727),
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ==================== MEDICATION FORM MODAL ====================

class _MedicationFormModal extends StatefulWidget {
  final _MedicationItem? medication;
  final void Function(String name, String dose, String frequency, String duration, String instructions) onSave;

  const _MedicationFormModal({
    this.medication,
    required this.onSave,
  });

  @override
  State<_MedicationFormModal> createState() => _MedicationFormModalState();
}

class _MedicationFormModalState extends State<_MedicationFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _doseController;
  late TextEditingController _frequencyController;
  late TextEditingController _durationController;
  late TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name ?? '');
    _doseController = TextEditingController(text: widget.medication?.dose ?? '');
    _frequencyController = TextEditingController(text: widget.medication?.frequency ?? '');
    _durationController = TextEditingController(text: widget.medication?.duration ?? '');
    _instructionsController = TextEditingController(text: widget.medication?.instructions ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    final dose = _doseController.text.trim();
    final frequency = _frequencyController.text.trim();
    final duration = _durationController.text.trim();
    final instructions = _instructionsController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da medicação')),
      );
      return;
    }

    widget.onSave(name, dose.isEmpty ? '-' : dose, frequency, duration, instructions);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medication != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Editar Medicação' : 'Nova Medicação',
                    style: const TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Color(0xFF697282)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nome
              _buildLabel('Nome da Medicação'),
              const SizedBox(height: 8),
              _buildTextField(_nameController, 'Ex: Paracetamol'),
              const SizedBox(height: 16),

              // Dose
              _buildLabel('Dose'),
              const SizedBox(height: 8),
              _buildTextField(_doseController, 'Ex: 750mg'),
              const SizedBox(height: 16),

              // Frequência
              _buildLabel('Frequência'),
              const SizedBox(height: 8),
              _buildTextField(_frequencyController, 'Ex: 8 em 8 horas'),
              const SizedBox(height: 16),

              // Duração
              _buildLabel('Duração'),
              const SizedBox(height: 8),
              _buildTextField(_durationController, 'Ex: 7 dias'),
              const SizedBox(height: 16),

              // Instruções
              _buildLabel('Instruções'),
              const SizedBox(height: 8),
              TextField(
                controller: _instructionsController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ex: Tomar com água, após as refeições',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD0D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD0D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F4A34)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),

              // Botão Salvar
              GestureDetector(
                onTap: _handleSave,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F4A34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      isEditing ? 'Salvar Alterações' : 'Adicionar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4F4A34),
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF5F3EF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
