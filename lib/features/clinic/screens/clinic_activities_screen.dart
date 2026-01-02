import 'package:flutter/material.dart';

class ClinicActivitiesScreen extends StatefulWidget {
  const ClinicActivitiesScreen({super.key});

  @override
  State<ClinicActivitiesScreen> createState() => _ClinicActivitiesScreenState();
}

class _ClinicActivitiesScreenState extends State<ClinicActivitiesScreen> {
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
              Icons.directions_run_outlined,
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
            'para visualizar e gerenciar\nas atividades permitidas',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD7D1C5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA49E86)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Color(0xFF4F4A34), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Voltar',
                    style: TextStyle(
                      color: Color(0xFF4F4A34),
                      fontSize: 14,
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
        mainAxisSize: MainAxisSize.min,
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
                              builder: (context) => _PatientActivitiesDetailScreen(patient: patient),
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

// ==================== PATIENT ACTIVITIES DETAIL SCREEN ====================

class _PatientActivitiesDetailScreen extends StatefulWidget {
  final _PatientItem patient;

  const _PatientActivitiesDetailScreen({required this.patient});

  @override
  State<_PatientActivitiesDetailScreen> createState() => _PatientActivitiesDetailScreenState();
}

class _PatientActivitiesDetailScreenState extends State<_PatientActivitiesDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_Category> _categories = [
    _Category('ALLOWED', 'Permitidas', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
    _Category('RESTRICTED', 'A evitar', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.warning_amber_outlined),
    _Category('PROHIBITED', 'Proibidas', const Color(0xFFE7000B), const Color(0xFFE7000B), Icons.block_outlined),
  ];

  // Mock data - será substituído por chamadas de API
  final List<_ActivityItem> _items = [
    _ActivityItem('1', 'Caminhada leve', '90 bpm', '15 min', '+3', 'ALLOWED', true),
    _ActivityItem('2', 'Subir escadas', '100 bpm', '5 min', '+7', 'ALLOWED', true),
    _ActivityItem('3', 'Trabalho remoto', '-', '4 horas', '+7', 'ALLOWED', true),
    _ActivityItem('4', 'Dirigir', '80 bpm', '30 min', '+14', 'ALLOWED', true),
    _ActivityItem('5', 'Atividades domésticas', '90 bpm', '20 min', '+14', 'ALLOWED', true),
    _ActivityItem('6', 'Yoga leve', '85 bpm', '30 min', '+21', 'ALLOWED', true),
    _ActivityItem('7', 'Relações sexuais', '120 bpm', '-', '+21', 'RESTRICTED', true),
    _ActivityItem('8', 'Pegar peso (até 5kg)', '100 bpm', '-', '+14', 'RESTRICTED', true),
    _ActivityItem('9', 'Banho de piscina', '-', '-', '+30', 'RESTRICTED', true),
    _ActivityItem('10', 'Exercícios intensos', '140+ bpm', '-', '+60', 'PROHIBITED', true),
    _ActivityItem('11', 'Musculação pesada', '150+ bpm', '-', '+60', 'PROHIBITED', true),
    _ActivityItem('12', 'Esportes de contato', '-', '-', '+90', 'PROHIBITED', true),
    _ActivityItem('13', 'Natação', '110 bpm', '30 min', '+45', 'PROHIBITED', true),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_ActivityItem> _filterByCategory(String categoryId) {
    return _items.where((i) => i.category == categoryId).toList();
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
            _buildTabBar(),
            _buildAddButton(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((cat) => _buildList(cat)).toList(),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD7D1C5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA49E86)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Color(0xFF4F4A34), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Voltar',
                    style: TextStyle(
                      color: Color(0xFF4F4A34),
                      fontSize: 14,
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
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
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
                    color: Colors.white.withValues(alpha: 0.80),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
          left: BorderSide(color: Color(0xFFE5E7EB)),
          right: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          return Tab(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final isSelected = _tabController.index == index;
                return Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? cat.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, color: isSelected ? cat.textColor : const Color(0xFF697282), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected ? cat.textColor : const Color(0xFF697282),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showAddModal,
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
                'Adicionar Atividade',
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

  Widget _buildList(_Category category) {
    final items = _filterByCategory(category.id);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: const Color(0xFF697282), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma atividade cadastrada',
              style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque em "Adicionar Atividade"',
              style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _ActivityCard(
            item: item,
            category: category,
            onDelete: () => _deleteItem(item.id),
            onEdit: () => _showEditModal(item),
          ),
        );
      },
    );
  }

  void _deleteItem(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir atividade?'),
        content: const Text('Esta atividade será removida do paciente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _items.removeWhere((i) => i.id == id));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Atividade excluída')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE7000B)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAddModal() {
    final category = _categories[_tabController.index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActivityFormModal(
        category: category,
        onSave: (activity, fcMax, duration, startDay) {
          setState(() {
            _items.add(_ActivityItem(
              DateTime.now().millisecondsSinceEpoch.toString(),
              activity,
              fcMax,
              duration,
              startDay,
              category.id,
              true,
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Atividade adicionada')),
          );
        },
      ),
    );
  }

  void _showEditModal(_ActivityItem item) {
    final category = _categories.firstWhere((c) => c.id == item.category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActivityFormModal(
        category: category,
        item: item,
        onSave: (activity, fcMax, duration, startDay) {
          setState(() {
            final idx = _items.indexWhere((i) => i.id == item.id);
            if (idx != -1) {
              _items[idx] = item.copyWith(
                activity: activity,
                fcMax: fcMax,
                duration: duration,
                startDay: startDay,
              );
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Atividade atualizada')),
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

class _Category {
  final String id, name;
  final Color color, textColor;
  final IconData icon;
  _Category(this.id, this.name, this.color, this.textColor, this.icon);
}

class _ActivityItem {
  final String id, activity, fcMax, duration, startDay, category;
  final bool isActive;

  _ActivityItem(this.id, this.activity, this.fcMax, this.duration, this.startDay, this.category, this.isActive);

  _ActivityItem copyWith({
    String? activity,
    String? fcMax,
    String? duration,
    String? startDay,
    bool? isActive,
  }) {
    return _ActivityItem(
      id,
      activity ?? this.activity,
      fcMax ?? this.fcMax,
      duration ?? this.duration,
      startDay ?? this.startDay,
      category,
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

// ==================== ACTIVITY CARD ====================

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  final _Category category;
  final VoidCallback onDelete, onEdit;

  const _ActivityCard({
    required this.item,
    required this.category,
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC8C2B4)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.drag_indicator, color: Color(0xFF697282), size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      _buildField(item.activity, isBold: true),
                      const SizedBox(height: 8),
                      _buildFieldWithIcon(Icons.favorite_outline, 'FC Máx: ${item.fcMax}'),
                      const SizedBox(height: 8),
                      _buildFieldWithIcon(Icons.timer_outlined, 'Duração: ${item.duration}'),
                      const SizedBox(height: 8),
                      _buildFieldWithIcon(Icons.calendar_today_outlined, 'Início: ${item.startDay}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
      ),
    );
  }

  Widget _buildField(String text, {bool isBold = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF212621),
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildFieldWithIcon(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF697282)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF212621),
                fontSize: 14,
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

// ==================== FORM MODAL ====================

class _ActivityFormModal extends StatefulWidget {
  final _Category category;
  final _ActivityItem? item;
  final void Function(String activity, String fcMax, String duration, String startDay) onSave;

  const _ActivityFormModal({
    required this.category,
    this.item,
    required this.onSave,
  });

  @override
  State<_ActivityFormModal> createState() => _ActivityFormModalState();
}

class _ActivityFormModalState extends State<_ActivityFormModal> {
  late TextEditingController _activityController;
  late TextEditingController _fcMaxController;
  late TextEditingController _durationController;
  late TextEditingController _startDayController;

  @override
  void initState() {
    super.initState();
    _activityController = TextEditingController(text: widget.item?.activity ?? '');
    _fcMaxController = TextEditingController(text: widget.item?.fcMax ?? '');
    _durationController = TextEditingController(text: widget.item?.duration ?? '');
    _startDayController = TextEditingController(text: widget.item?.startDay ?? '+0');
  }

  @override
  void dispose() {
    _activityController.dispose();
    _fcMaxController.dispose();
    _durationController.dispose();
    _startDayController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final activity = _activityController.text.trim();
    final fcMax = _fcMaxController.text.trim();
    final duration = _durationController.text.trim();
    final startDay = _startDayController.text.trim();

    if (activity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a atividade')),
      );
      return;
    }

    widget.onSave(
      activity,
      fcMax.isEmpty ? '-' : fcMax,
      duration.isEmpty ? '-' : duration,
      startDay.isEmpty ? '+0' : startDay,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Editar Atividade' : 'Nova Atividade',
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.category.color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.category.icon, color: widget.category.color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    widget.category.name,
                    style: TextStyle(
                      color: widget.category.textColor,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Atividade'),
            const SizedBox(height: 8),
            _buildTextField(_activityController, 'Ex: Caminhada'),
            const SizedBox(height: 16),
            _buildLabel('FC Máx (Frequência Cardíaca)'),
            const SizedBox(height: 8),
            _buildTextField(_fcMaxController, 'Ex: 90 bpm', icon: Icons.favorite_outline),
            const SizedBox(height: 16),
            _buildLabel('Duração'),
            const SizedBox(height: 8),
            _buildTextField(_durationController, 'Ex: 15 min', icon: Icons.timer_outlined),
            const SizedBox(height: 16),
            _buildLabel('Início (a partir de qual dia)'),
            const SizedBox(height: 8),
            _buildTextField(_startDayController, 'Ex: +7 (após 7 dias)', icon: Icons.calendar_today_outlined),
            const SizedBox(height: 24),
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

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon}) {
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
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF697282)) : null,
      ),
    );
  }
}
