import 'package:flutter/material.dart';

class ClinicTrainingScreen extends StatefulWidget {
  const ClinicTrainingScreen({super.key});

  @override
  State<ClinicTrainingScreen> createState() => _ClinicTrainingScreenState();
}

class _ClinicTrainingScreenState extends State<ClinicTrainingScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data - será substituído por chamadas de API
  final List<_PatientItem> _allPatients = [
    _PatientItem('1', 'Maria Silva', 'PAC001', 'assets/images/avatar1.png'),
    _PatientItem('2', 'João Santos', 'PAC002', 'assets/images/avatar2.png'),
    _PatientItem('3', 'Ana Oliveira', 'PAC003', 'assets/images/avatar3.png'),
    _PatientItem('4', 'Carlos Lima', 'PAC004', 'assets/images/avatar4.png'),
    _PatientItem('5', 'Fernanda Costa', 'PAC005', 'assets/images/avatar5.png'),
    _PatientItem('6', 'Roberto Alves', 'PAC006', 'assets/images/avatar6.png'),
  ];

  List<_PatientItem> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _filteredPatients = List.from(_allPatients);
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List.from(_allPatients);
      } else {
        _filteredPatients = _allPatients.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.id.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  void _navigateToPatientDetail(_PatientItem patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PatientTrainingDetailScreen(patient: patient),
      ),
    );
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
            'Treinos',
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
        border: Border.all(color: const Color(0xFF4F4A34), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione um Paciente',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Campo de busca
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar paciente...',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
                prefixIcon: Icon(Icons.search, color: Color(0xFF697282), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Lista de pacientes com scroll
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
                        onTap: () => _navigateToPatientDetail(patient),
                      );
                    },
                  ),
          ),
        ],
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
              Icons.fitness_center_outlined,
              color: Color(0xFF697282),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Selecione um paciente',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'para visualizar e gerenciar\nos treinos de reabilitação',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF697282),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PATIENT MODEL ====================

class _PatientItem {
  final String id;
  final String name;
  final String patientId;
  final String avatarPath;

  _PatientItem(this.id, this.name, this.patientId, this.avatarPath);
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4F4A34),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  patient.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
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
                      color: Color(0xFF212621),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${patient.patientId}',
                    style: const TextStyle(
                      color: Color(0xFF697282),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF697282),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PATIENT TRAINING DETAIL SCREEN ====================

class _PatientTrainingDetailScreen extends StatefulWidget {
  final _PatientItem patient;

  const _PatientTrainingDetailScreen({required this.patient});

  @override
  State<_PatientTrainingDetailScreen> createState() => _PatientTrainingDetailScreenState();
}

class _PatientTrainingDetailScreenState extends State<_PatientTrainingDetailScreen> {
  // Mock data - será substituído por chamadas de API
  List<_WeekItem> _weeks = [
    _WeekItem(
      '1',
      'Semana 1',
      '+0 até +6 dias',
      [
        _ExerciseItem('1', '90 bpm', '15 min', 'Caminhada leve em superfície plana. Respeitar limites do corpo.'),
        _ExerciseItem('2', '85 bpm', '10 min', 'Alongamentos suaves sem forçar.'),
      ],
      true,
    ),
    _WeekItem(
      '2',
      'Semana 2',
      '+7 até +13 dias',
      [
        _ExerciseItem('3', '95 bpm', '20 min', 'Caminhada com leve inclinação.'),
      ],
      false,
    ),
    _WeekItem(
      '3',
      'Semana 3',
      '+14 até +20 dias',
      [],
      false,
    ),
    _WeekItem(
      '4',
      'Semana 4',
      '+21 até +27 dias',
      [],
      false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    // TODO: Chamar API com widget.patient.id
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
            _buildPatientInfo(),
            _buildAddWeekButton(),
            Expanded(
              child: _buildList(),
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
            'Treinos',
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F4A34), Color(0xFF212621)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                widget.patient.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
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
                  widget.patient.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${widget.patient.patientId}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddWeekButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showAddWeekModal,
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
                'Adicionar Semana',
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

  Widget _buildList() {
    if (_weeks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.fitness_center_outlined, color: Color(0xFF697282), size: 48),
            SizedBox(height: 16),
            Text(
              'Nenhuma semana cadastrada',
              style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
            ),
            SizedBox(height: 8),
            Text(
              'Toque em "Adicionar Semana"',
              style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _weeks.length,
      itemBuilder: (context, index) {
        final week = _weeks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _WeekCard(
            week: week,
            onToggleExpand: () => _toggleWeekExpand(week.id),
            onAddExercise: () => _showAddExerciseModal(week),
            onDeleteWeek: () => _deleteWeek(week.id),
            onDeleteExercise: (exerciseId) => _deleteExercise(week.id, exerciseId),
            onEditExercise: (exercise) => _showEditExerciseModal(week, exercise),
          ),
        );
      },
    );
  }

  void _toggleWeekExpand(String weekId) {
    setState(() {
      final idx = _weeks.indexWhere((w) => w.id == weekId);
      if (idx != -1) {
        _weeks[idx] = _weeks[idx].copyWith(isExpanded: !_weeks[idx].isExpanded);
      }
    });
  }

  void _deleteWeek(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir semana?'),
        content: const Text('Todos os exercícios desta semana serão removidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _weeks.removeWhere((w) => w.id == id));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semana excluída')),
              );
              // TODO: Chamar API delete
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE7000B)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _deleteExercise(String weekId, String exerciseId) {
    setState(() {
      final weekIdx = _weeks.indexWhere((w) => w.id == weekId);
      if (weekIdx != -1) {
        final exercises = List<_ExerciseItem>.from(_weeks[weekIdx].exercises);
        exercises.removeWhere((e) => e.id == exerciseId);
        _weeks[weekIdx] = _weeks[weekIdx].copyWith(exercises: exercises);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercício excluído')),
    );
    // TODO: Chamar API delete
  }

  void _showAddWeekModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WeekFormModal(
        onSave: (title, period) {
          setState(() {
            _weeks.add(_WeekItem(
              DateTime.now().millisecondsSinceEpoch.toString(),
              title,
              period,
              [],
              true,
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semana adicionada')),
          );
          // TODO: Chamar API create
        },
      ),
    );
  }

  void _showAddExerciseModal(_WeekItem week) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExerciseFormModal(
        onSave: (fcMax, duration, description) {
          setState(() {
            final weekIdx = _weeks.indexWhere((w) => w.id == week.id);
            if (weekIdx != -1) {
              final exercises = List<_ExerciseItem>.from(_weeks[weekIdx].exercises);
              exercises.add(_ExerciseItem(
                DateTime.now().millisecondsSinceEpoch.toString(),
                fcMax,
                duration,
                description,
              ));
              _weeks[weekIdx] = _weeks[weekIdx].copyWith(exercises: exercises);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercício adicionado')),
          );
          // TODO: Chamar API create
        },
      ),
    );
  }

  void _showEditExerciseModal(_WeekItem week, _ExerciseItem exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExerciseFormModal(
        exercise: exercise,
        onSave: (fcMax, duration, description) {
          setState(() {
            final weekIdx = _weeks.indexWhere((w) => w.id == week.id);
            if (weekIdx != -1) {
              final exercises = List<_ExerciseItem>.from(_weeks[weekIdx].exercises);
              final exIdx = exercises.indexWhere((e) => e.id == exercise.id);
              if (exIdx != -1) {
                exercises[exIdx] = exercise.copyWith(
                  fcMax: fcMax,
                  duration: duration,
                  description: description,
                );
              }
              _weeks[weekIdx] = _weeks[weekIdx].copyWith(exercises: exercises);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercício atualizado')),
          );
          // TODO: Chamar API update
        },
      ),
    );
  }
}

// ==================== MODELS ====================

class _WeekItem {
  final String id, title, period;
  final List<_ExerciseItem> exercises;
  final bool isExpanded;

  _WeekItem(this.id, this.title, this.period, this.exercises, this.isExpanded);

  _WeekItem copyWith({
    String? title,
    String? period,
    List<_ExerciseItem>? exercises,
    bool? isExpanded,
  }) {
    return _WeekItem(
      id,
      title ?? this.title,
      period ?? this.period,
      exercises ?? this.exercises,
      isExpanded ?? this.isExpanded,
    );
  }
}

class _ExerciseItem {
  final String id, fcMax, duration, description;

  _ExerciseItem(this.id, this.fcMax, this.duration, this.description);

  _ExerciseItem copyWith({
    String? fcMax,
    String? duration,
    String? description,
  }) {
    return _ExerciseItem(
      id,
      fcMax ?? this.fcMax,
      duration ?? this.duration,
      description ?? this.description,
    );
  }
}

// ==================== WEEK CARD ====================

class _WeekCard extends StatelessWidget {
  final _WeekItem week;
  final VoidCallback onToggleExpand;
  final VoidCallback onAddExercise;
  final VoidCallback onDeleteWeek;
  final void Function(String exerciseId) onDeleteExercise;
  final void Function(_ExerciseItem exercise) onEditExercise;

  const _WeekCard({
    required this.week,
    required this.onToggleExpand,
    required this.onAddExercise,
    required this.onDeleteWeek,
    required this.onDeleteExercise,
    required this.onEditExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header da semana
          GestureDetector(
            onTap: onToggleExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator, color: Color(0xFF697282), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          week.title,
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          week.period,
                          style: const TextStyle(
                            color: Color(0xFF495565),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    week.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF697282),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandido
          if (week.isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Column(
                children: [
                  // Lista de exercícios
                  ...week.exercises.map((exercise) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExerciseCard(
                      exercise: exercise,
                      onDelete: () => onDeleteExercise(exercise.id),
                      onEdit: () => onEditExercise(exercise),
                    ),
                  )),

                  // Botão adicionar exercício
                  GestureDetector(
                    onTap: onAddExercise,
                    child: Container(
                      width: double.infinity,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F4A34),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Adicionar Exercício',
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

                  const SizedBox(height: 12),

                  // Botão excluir semana
                  GestureDetector(
                    onTap: onDeleteWeek,
                    child: Container(
                      width: double.infinity,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE7000B)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, color: Color(0xFFE7000B), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Excluir Semana',
                            style: TextStyle(
                              color: Color(0xFFE7000B),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== EXERCISE CARD ====================

class _ExerciseCard extends StatelessWidget {
  final _ExerciseItem exercise;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ExerciseCard({
    required this.exercise,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FC Máx e Duração
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    Icons.favorite_outline,
                    'FC Máx: ${exercise.fcMax}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildField(
                    Icons.timer_outlined,
                    exercise.duration,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Descrição
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD0D5DB)),
              ),
              child: Text(
                exercise.description,
                style: const TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Botão excluir
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 32,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7000B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF697282)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== WEEK FORM MODAL ====================

class _WeekFormModal extends StatefulWidget {
  final void Function(String title, String period) onSave;

  const _WeekFormModal({required this.onSave});

  @override
  State<_WeekFormModal> createState() => _WeekFormModalState();
}

class _WeekFormModalState extends State<_WeekFormModal> {
  final _titleController = TextEditingController();
  final _periodController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final period = _periodController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título da semana')),
      );
      return;
    }

    widget.onSave(title, period.isEmpty ? '-' : period);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                const Text(
                  'Nova Semana',
                  style: TextStyle(
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

            // Título
            const Text(
              'Título',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Semana 5',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F3EF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Período
            const Text(
              'Período',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _periodController,
              decoration: InputDecoration(
                hintText: 'Ex: +28 até +34 dias',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F3EF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF697282)),
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
                child: const Center(
                  child: Text(
                    'Adicionar',
                    style: TextStyle(
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
    );
  }
}

// ==================== EXERCISE FORM MODAL ====================

class _ExerciseFormModal extends StatefulWidget {
  final _ExerciseItem? exercise;
  final void Function(String fcMax, String duration, String description) onSave;

  const _ExerciseFormModal({
    this.exercise,
    required this.onSave,
  });

  @override
  State<_ExerciseFormModal> createState() => _ExerciseFormModalState();
}

class _ExerciseFormModalState extends State<_ExerciseFormModal> {
  late TextEditingController _fcMaxController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _fcMaxController = TextEditingController(text: widget.exercise?.fcMax ?? '');
    _durationController = TextEditingController(text: widget.exercise?.duration ?? '');
    _descriptionController = TextEditingController(text: widget.exercise?.description ?? '');
  }

  @override
  void dispose() {
    _fcMaxController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final fcMax = _fcMaxController.text.trim();
    final duration = _durationController.text.trim();
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descreva o exercício')),
      );
      return;
    }

    widget.onSave(
      fcMax.isEmpty ? '-' : fcMax,
      duration.isEmpty ? '-' : duration,
      description,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.exercise != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  isEditing ? 'Editar Exercício' : 'Novo Exercício',
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

            // FC Máx
            const Text(
              'FC Máx (Frequência Cardíaca)',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fcMaxController,
              decoration: InputDecoration(
                hintText: 'Ex: 90 bpm',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F3EF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: const Icon(Icons.favorite_outline, color: Color(0xFF697282)),
              ),
            ),
            const SizedBox(height: 16),

            // Duração
            const Text(
              'Duração',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(
                hintText: 'Ex: 15 min',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F3EF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: const Icon(Icons.timer_outlined, color: Color(0xFF697282)),
              ),
            ),
            const SizedBox(height: 16),

            // Descrição
            const Text(
              'Descrição do exercício',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Liste os exercícios permitidos...',
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
    );
  }
}
