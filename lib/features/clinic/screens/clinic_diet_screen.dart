import 'package:flutter/material.dart';

class ClinicDietScreen extends StatefulWidget {
  const ClinicDietScreen({super.key});

  @override
  State<ClinicDietScreen> createState() => _ClinicDietScreenState();
}

class _ClinicDietScreenState extends State<ClinicDietScreen> {
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
              Icons.restaurant_outlined,
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
            'para visualizar e gerenciar\nas orientações nutricionais',
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
                              builder: (context) => _PatientDietDetailScreen(patient: patient),
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

// ==================== PATIENT DIET DETAIL SCREEN ====================

class _PatientDietDetailScreen extends StatefulWidget {
  final _PatientItem patient;

  const _PatientDietDetailScreen({required this.patient});

  @override
  State<_PatientDietDetailScreen> createState() => _PatientDietDetailScreenState();
}

class _PatientDietDetailScreenState extends State<_PatientDietDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_Category> _categories = [
    _Category('TODO', 'Fazer', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
    _Category('OPTIONAL', 'Opcional', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.help_outline),
    _Category('NOT_REQUIRED', 'Não necessário', const Color(0xFF697282), const Color(0xFF495565), Icons.remove_circle_outline),
  ];

  // Mock data - será substituído por chamadas de API
  List<_DietItem> _items = [
    _DietItem('1', 'Verduras', 'Alface, Rúcula, Espinafre, Couve', '+0', 'TODO', true),
    _DietItem('2', 'Proteínas Magras', 'Frango, Peixe, Ovos', '+0', 'TODO', true),
    _DietItem('3', 'Frutas', 'Maçã, Banana, Mamão, Melão', '+3', 'TODO', true),
    _DietItem('4', 'Grãos Integrais', 'Arroz integral, Aveia, Quinoa', '+7', 'TODO', true),
    _DietItem('5', 'Suplementos', 'Vitaminas, Minerais conforme prescrição', '+0', 'OPTIONAL', true),
    _DietItem('6', 'Chás naturais', 'Camomila, Erva-doce, Hortelã', '+0', 'OPTIONAL', true),
    _DietItem('7', 'Lanches leves', 'Frutas secas, Castanhas com moderação', '+7', 'OPTIONAL', true),
    _DietItem('8', 'Bebidas Alcoólicas', 'Cerveja, Vinho, Destilados', '+30', 'NOT_REQUIRED', true),
    _DietItem('9', 'Alimentos Ultraprocessados', 'Fast food, Salgadinhos, Doces industriais', '+0', 'NOT_REQUIRED', true),
    _DietItem('10', 'Refrigerantes', 'Refrigerantes, Sucos artificiais', '+0', 'NOT_REQUIRED', true),
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

  List<_DietItem> _filterByCategory(String categoryId) {
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
                'Adicionar Alimento',
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
              'Nenhum item cadastrado',
              style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque em "Adicionar Alimento"',
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
          child: _DietCard(
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
        title: const Text('Excluir item?'),
        content: const Text('Este item será removido da dieta do paciente.'),
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
                const SnackBar(content: Text('Item excluído')),
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
      builder: (ctx) => _DietFormModal(
        category: category,
        onSave: (categoryName, items, period) {
          setState(() {
            _items.add(_DietItem(
              DateTime.now().millisecondsSinceEpoch.toString(),
              categoryName,
              items,
              period,
              category.id,
              true,
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alimento adicionado')),
          );
        },
      ),
    );
  }

  void _showEditModal(_DietItem item) {
    final category = _categories.firstWhere((c) => c.id == item.category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DietFormModal(
        category: category,
        item: item,
        onSave: (categoryName, items, period) {
          setState(() {
            final idx = _items.indexWhere((i) => i.id == item.id);
            if (idx != -1) {
              _items[idx] = item.copyWith(
                categoryName: categoryName,
                items: items,
                period: period,
              );
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alimento atualizado')),
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

class _DietItem {
  final String id, categoryName, items, period, category;
  final bool isActive;

  _DietItem(this.id, this.categoryName, this.items, this.period, this.category, this.isActive);

  _DietItem copyWith({String? categoryName, String? items, String? period, bool? isActive}) {
    return _DietItem(
      id,
      categoryName ?? this.categoryName,
      items ?? this.items,
      period ?? this.period,
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

// ==================== DIET CARD ====================

class _DietCard extends StatelessWidget {
  final _DietItem item;
  final _Category category;
  final VoidCallback onDelete, onEdit;

  const _DietCard({
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.categoryName,
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.items,
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF697282)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Período: ${item.period}',
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
}

// ==================== FORM MODAL ====================

class _DietFormModal extends StatefulWidget {
  final _Category category;
  final _DietItem? item;
  final void Function(String categoryName, String items, String period) onSave;

  const _DietFormModal({
    required this.category,
    this.item,
    required this.onSave,
  });

  @override
  State<_DietFormModal> createState() => _DietFormModalState();
}

class _DietFormModalState extends State<_DietFormModal> {
  late TextEditingController _categoryController;
  late TextEditingController _itemsController;
  late TextEditingController _periodController;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.item?.categoryName ?? '');
    _itemsController = TextEditingController(text: widget.item?.items ?? '');
    _periodController = TextEditingController(text: widget.item?.period ?? '+0');
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _itemsController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final categoryName = _categoryController.text.trim();
    final items = _itemsController.text.trim();
    final period = _periodController.text.trim();

    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a categoria')),
      );
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe os itens')),
      );
      return;
    }

    widget.onSave(categoryName, items, period.isEmpty ? '+0' : period);
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
                  isEditing ? 'Editar Alimento' : 'Novo Alimento',
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
            const Text(
              'Categoria',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                hintText: 'Ex: Verduras',
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
            const Text(
              'Itens',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _itemsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ex: Alface, Rúcula, Espinafre...',
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
            const Text(
              'Período (a partir de qual dia)',
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
                hintText: 'Ex: +7 (após 7 dias)',
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
