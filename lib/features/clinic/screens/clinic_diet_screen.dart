import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinic_content_provider.dart';
import '../providers/patients_provider.dart';
import '../models/models.dart';

class ClinicDietScreen extends StatefulWidget {
  const ClinicDietScreen({super.key});

  @override
  State<ClinicDietScreen> createState() => _ClinicDietScreenState();
}

class _ClinicDietScreenState extends State<ClinicDietScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientsProvider>().loadPatients(refresh: true);
      context.read<ClinicContentProvider>().loadContentsByType('DIET');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _navigateToPatientDetail(PatientListItem patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PatientDietDetailScreen(patient: patient),
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
            'Dieta',
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
    return Consumer<PatientsProvider>(
      builder: (context, provider, _) {
        final filteredPatients = _searchQuery.isEmpty
            ? provider.patients
            : provider.patients.where((p) =>
                p.name.toLowerCase().contains(_searchQuery) ||
                (p.phone?.toLowerCase().contains(_searchQuery) ?? false)).toList();

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
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: provider.isLoadingList
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: Color(0xFFA49E86)),
                        ),
                      )
                    : filteredPatients.isEmpty
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
                            itemCount: filteredPatients.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final patient = filteredPatients[index];
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
      },
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
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'para visualizar e gerenciar\nas orientações nutricionais',
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

// ==================== PATIENT CARD ====================

class _PatientCard extends StatelessWidget {
  final PatientListItem patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

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
                  patient.name.isNotEmpty ? patient.name.substring(0, 1).toUpperCase() : '?',
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
                    (patient.phone?.isNotEmpty ?? false) ? patient.phone! : 'Sem telefone',
                    style: const TextStyle(
                      color: Color(0xFF697282),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            if (patient.dayPostOp != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFA49E86).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'D+${patient.dayPostOp}',
                  style: const TextStyle(
                    color: Color(0xFF4F4A34),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF697282), size: 20),
          ],
        ),
      ),
    );
  }
}

// ==================== PATIENT DIET DETAIL SCREEN ====================

class _PatientDietDetailScreen extends StatefulWidget {
  final PatientListItem patient;

  const _PatientDietDetailScreen({required this.patient});

  @override
  State<_PatientDietDetailScreen> createState() => _PatientDietDetailScreenState();
}

class _PatientDietDetailScreenState extends State<_PatientDietDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_Category> _categories = [
    _Category('ALLOWED', 'Permitido', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
    _Category('RESTRICTED', 'Restrito', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.warning_amber_outlined),
    _Category('PROHIBITED', 'Proibido', const Color(0xFFE7000B), const Color(0xFFE7000B), Icons.block_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ClinicContentProvider>();
      if (provider.currentType != 'DIET') {
        provider.loadContentsByType('DIET');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              child: Consumer<ClinicContentProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoadingContents) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFA49E86)),
                    );
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: _categories.map((cat) => _buildList(cat, provider)).toList(),
                  );
                },
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
            'Dieta',
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
                widget.patient.name.isNotEmpty
                    ? widget.patient.name.substring(0, 1).toUpperCase()
                    : '?',
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
                  widget.patient.dayPostOp != null
                      ? 'D+${widget.patient.dayPostOp} pós-operatório'
                      : (widget.patient.phone ?? 'Sem telefone'),
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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

  Widget _buildList(_Category category, ClinicContentProvider provider) {
    final items = provider.getByCategory(category.id);

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
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        final itemsCopy = List<ClinicContent>.from(items);
        final item = itemsCopy.removeAt(oldIndex);
        itemsCopy.insert(newIndex, item);
        final ids = itemsCopy.map((c) => c.id).toList();
        await provider.reorderContents(ids);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _ContentCard(
            item: item,
            category: category,
            onToggle: () => _toggleItem(item.id),
            onDelete: () => _deleteItem(item.id),
            onEdit: () => _showEditModal(item),
          ),
        );
      },
    );
  }

  Future<void> _toggleItem(String id) async {
    await context.read<ClinicContentProvider>().toggleContent(id);
  }

  void _deleteItem(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir item?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ClinicContentProvider>().deleteContent(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Item excluído' : 'Erro ao excluir')),
                );
              }
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
      builder: (ctx) => _ContentFormModal(
        category: category,
        onSave: (title, description) async {
          final success = await context.read<ClinicContentProvider>().createContent(
            type: 'DIET',
            category: category.id,
            title: title,
            description: description.isNotEmpty ? description : null,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? 'Item adicionado' : 'Erro ao adicionar')),
            );
            if (success) {
              context.read<ClinicContentProvider>().loadStats();
            }
          }
        },
      ),
    );
  }

  void _showEditModal(ClinicContent item) {
    final category = _categories.firstWhere((c) => c.id == item.category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContentFormModal(
        category: category,
        item: item,
        onSave: (title, description) async {
          final success = await context.read<ClinicContentProvider>().updateContent(
            item.id,
            title: title,
            description: description.isNotEmpty ? description : null,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? 'Item atualizado' : 'Erro ao atualizar')),
            );
          }
        },
      ),
    );
  }
}

// ==================== MODELS ====================

class _Category {
  final String id, name;
  final Color color, textColor;
  final IconData icon;
  _Category(this.id, this.name, this.color, this.textColor, this.icon);
}

// ==================== CARD ====================

class _ContentCard extends StatelessWidget {
  final ClinicContent item;
  final _Category category;
  final VoidCallback onToggle, onDelete, onEdit;

  const _ContentCard({
    required this.item,
    required this.category,
    required this.onToggle,
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
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3EF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.description!,
                            style: const TextStyle(
                              color: Color(0xFF212621),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
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
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.isActive
                          ? const Color(0xFF00A63E).withAlpha(26)
                          : const Color(0xFF697282).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isActive ? Icons.visibility : Icons.visibility_off,
                          color: item.isActive ? const Color(0xFF00A63E) : const Color(0xFF697282),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isActive ? 'Ativo' : 'Inativo',
                          style: TextStyle(
                            color: item.isActive ? const Color(0xFF00A63E) : const Color(0xFF697282),
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
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7000B).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, color: Color(0xFFE7000B), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Excluir',
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
          ],
        ),
      ),
    );
  }
}

// ==================== FORM MODAL ====================

class _ContentFormModal extends StatefulWidget {
  final _Category category;
  final ClinicContent? item;
  final void Function(String title, String description) onSave;

  const _ContentFormModal({
    required this.category,
    this.item,
    required this.onSave,
  });

  @override
  State<_ContentFormModal> createState() => _ContentFormModalState();
}

class _ContentFormModalState extends State<_ContentFormModal> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título')),
      );
      return;
    }

    widget.onSave(title, description);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              'Descrição',
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
