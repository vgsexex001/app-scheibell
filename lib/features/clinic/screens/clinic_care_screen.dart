import 'package:flutter/material.dart';

class ClinicCareScreen extends StatefulWidget {
  const ClinicCareScreen({super.key});

  @override
  State<ClinicCareScreen> createState() => _ClinicCareScreenState();
}

class _ClinicCareScreenState extends State<ClinicCareScreen> {
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
        builder: (context) => _PatientCareDetailScreen(patient: patient),
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
            'Cuidados',
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
              Icons.medical_services_outlined,
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
            'para visualizar e gerenciar\nos cuidados pós-operatórios',
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

// ==================== PATIENT CARE DETAIL SCREEN ====================

class _PatientCareDetailScreen extends StatefulWidget {
  final _PatientItem patient;

  const _PatientCareDetailScreen({required this.patient});

  @override
  State<_PatientCareDetailScreen> createState() => _PatientCareDetailScreenState();
}

class _PatientCareDetailScreenState extends State<_PatientCareDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_Category> _categories = [
    _Category('CARE', 'Cuidado', const Color(0xFFE7000B), const Color(0xFFC50009), Icons.medical_services_outlined),
    _Category('TODO', 'Fazer', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
    _Category('OPTIONAL', 'Opcional', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.help_outline),
    _Category('NOT_REQUIRED', 'Não necessário', const Color(0xFF697282), const Color(0xFF495565), Icons.remove_circle_outline),
  ];

  // Mock data - será substituído por chamadas de API
  List<_CareItem> _items = [
    _CareItem(
      '0a',
      'Atenção aos sinais de infecção',
      'Diariamente',
      'Observar vermelhidão excessiva, inchaço, secreção amarelada/esverdeada ou odor forte na região operada. Em caso de febre acima de 38°C, procurar atendimento imediato.',
      'CARE',
      true,
    ),
    _CareItem(
      '0b',
      'Cuidado com movimentos bruscos',
      'Primeiros 15 dias',
      'Evitar movimentos bruscos, esforço físico e carregar peso. Levantar-se da cama devagar, apoiando-se nos braços.',
      'CARE',
      true,
    ),
    _CareItem(
      '1',
      'Limpeza do curativo',
      '3x ao dia',
      'Limpar com soro fisiológico e gaze estéril. Secar delicadamente sem esfregar. Aplicar a pomada prescrita em camada fina.',
      'TODO',
      true,
    ),
    _CareItem(
      '2',
      'Uso da cinta compressiva',
      '24 horas',
      'Usar a cinta compressiva 24 horas por dia nos primeiros 30 dias. Retirar apenas para o banho. Ajustar conforme orientação.',
      'TODO',
      true,
    ),
    _CareItem(
      '3',
      'Posição para dormir',
      'Todas as noites',
      'Dormir de barriga para cima nos primeiros 15 dias. Usar travesseiros para apoio. Evitar virar de lado.',
      'TODO',
      true,
    ),
    _CareItem(
      '4',
      'Drenagem linfática',
      '2-3x por semana',
      'Iniciar após 7-10 dias de cirurgia. Realizar apenas com profissional habilitado. Seguir cronograma de sessões.',
      'TODO',
      true,
    ),
    _CareItem(
      '5',
      'Massagem na cicatriz',
      'Após 30 dias',
      'Opcional após cicatrização inicial. Ajuda na mobilidade do tecido. Consultar médico antes.',
      'OPTIONAL',
      true,
    ),
    _CareItem(
      '6',
      'Uso de hidratante',
      'Diariamente',
      'Hidratação da pele ao redor da área operada. Evitar aplicar diretamente na incisão.',
      'OPTIONAL',
      true,
    ),
    _CareItem(
      '7',
      'Banho de banheira',
      '-',
      'Não é necessário evitar após 30 dias, se liberado pelo médico.',
      'NOT_REQUIRED',
      true,
    ),
    _CareItem(
      '8',
      'Cinta durante o dia todo',
      'Após 60 dias',
      'Após o período inicial, uso contínuo não é mais necessário.',
      'NOT_REQUIRED',
      true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    // TODO: Chamar API com widget.patient.id
  }

  List<_CareItem> _filterByCategory(String categoryId) {
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
            'Cuidados',
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.only(left: 4),
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
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      Icon(cat.icon, color: isSelected ? cat.textColor : const Color(0xFF697282), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected ? cat.textColor : const Color(0xFF697282),
                            fontSize: 11,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                'Adicionar Cuidado',
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
              'Nenhum cuidado cadastrado',
              style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque em "Adicionar Cuidado"',
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
        // TODO: Chamar API reorder
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _CareCard(
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
        title: const Text('Excluir cuidado?'),
        content: const Text('Esta ação não pode ser desfeita.'),
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
                const SnackBar(content: Text('Cuidado excluído')),
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

  void _showAddModal() {
    final category = _categories[_tabController.index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CareFormModal(
        category: category,
        onSave: (title, frequency, description) {
          setState(() {
            _items.add(_CareItem(
              DateTime.now().millisecondsSinceEpoch.toString(),
              title,
              frequency,
              description,
              category.id,
              true,
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuidado adicionado')),
          );
          // TODO: Chamar API create
        },
      ),
    );
  }

  void _showEditModal(_CareItem item) {
    final category = _categories.firstWhere((c) => c.id == item.category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CareFormModal(
        category: category,
        item: item,
        onSave: (title, frequency, description) {
          setState(() {
            final idx = _items.indexWhere((i) => i.id == item.id);
            if (idx != -1) {
              _items[idx] = item.copyWith(
                title: title,
                frequency: frequency,
                description: description,
              );
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuidado atualizado')),
          );
          // TODO: Chamar API update
        },
      ),
    );
  }
}

// ==================== CATEGORY MODEL ====================

class _Category {
  final String id, name;
  final Color color, textColor;
  final IconData icon;
  _Category(this.id, this.name, this.color, this.textColor, this.icon);
}

// ==================== CARE MODEL ====================

class _CareItem {
  final String id, title, frequency, description, category;
  final bool isActive;

  _CareItem(this.id, this.title, this.frequency, this.description, this.category, this.isActive);

  _CareItem copyWith({
    String? title,
    String? frequency,
    String? description,
    bool? isActive,
  }) {
    return _CareItem(
      id,
      title ?? this.title,
      frequency ?? this.frequency,
      description ?? this.description,
      category,
      isActive ?? this.isActive,
    );
  }
}

// ==================== CARE CARD ====================

class _CareCard extends StatelessWidget {
  final _CareItem item;
  final _Category category;
  final VoidCallback onDelete, onEdit;

  const _CareCard({
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
                      // Título
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Frequência
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule_outlined, size: 14, color: Color(0xFF697282)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.frequency,
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
                          item.description,
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Botão Excluir
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
}

// ==================== FORM MODAL ====================

class _CareFormModal extends StatefulWidget {
  final _Category category;
  final _CareItem? item;
  final void Function(String title, String frequency, String description) onSave;

  const _CareFormModal({
    required this.category,
    this.item,
    required this.onSave,
  });

  @override
  State<_CareFormModal> createState() => _CareFormModalState();
}

class _CareFormModalState extends State<_CareFormModal> {
  late TextEditingController _titleController;
  late TextEditingController _frequencyController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _frequencyController = TextEditingController(text: widget.item?.frequency ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _frequencyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final frequency = _frequencyController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título do cuidado')),
      );
      return;
    }

    widget.onSave(
      title,
      frequency.isEmpty ? '-' : frequency,
      description,
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Editar Cuidado' : 'Novo Cuidado',
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
            // Category badge
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
                hintText: 'Ex: Limpeza do curativo',
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

            // Frequência
            const Text(
              'Frequência',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _frequencyController,
              decoration: InputDecoration(
                hintText: 'Ex: 3x ao dia',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F3EF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: const Icon(Icons.schedule_outlined, color: Color(0xFF697282)),
              ),
            ),
            const SizedBox(height: 16),

            // Descrição
            const Text(
              'Descrição detalhada',
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
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Descreva o cuidado em detalhes...',
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
