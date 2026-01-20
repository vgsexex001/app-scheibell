import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinic_content_provider.dart';
import '../providers/patients_provider.dart';
import '../models/models.dart';

/// Categorias de medicamentos (espelha backend: ALLOWED, RESTRICTED, PROHIBITED)
enum MedicationCategory {
  allowed,    // Permitido
  restricted, // Evitar (usar RESTRICTED do backend)
  prohibited  // Proibido
}

extension MedicationCategoryExtension on MedicationCategory {
  String get displayName {
    switch (this) {
      case MedicationCategory.allowed:
        return 'Permitido';
      case MedicationCategory.restricted:
        return 'Evitar';
      case MedicationCategory.prohibited:
        return 'Proibido';
    }
  }

  String get apiValue {
    switch (this) {
      case MedicationCategory.allowed:
        return 'ALLOWED';
      case MedicationCategory.restricted:
        return 'RESTRICTED';
      case MedicationCategory.prohibited:
        return 'PROHIBITED';
    }
  }

  Color get color {
    switch (this) {
      case MedicationCategory.allowed:
        return const Color(0xFF00A63E); // Verde
      case MedicationCategory.restricted:
        return const Color(0xFFF59E0B); // Amarelo/Laranja
      case MedicationCategory.prohibited:
        return const Color(0xFFE7000B); // Vermelho
    }
  }

  IconData get icon {
    switch (this) {
      case MedicationCategory.allowed:
        return Icons.check_circle;
      case MedicationCategory.restricted:
        return Icons.warning_rounded;
      case MedicationCategory.prohibited:
        return Icons.cancel;
    }
  }
}

class ClinicMedicationsScreen extends StatefulWidget {
  const ClinicMedicationsScreen({super.key});

  @override
  State<ClinicMedicationsScreen> createState() => _ClinicMedicationsScreenState();
}

class _ClinicMedicationsScreenState extends State<ClinicMedicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientsProvider>().loadPatients(refresh: true);
      context.read<ClinicContentProvider>().loadContentsByType('MEDICATIONS');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.toLowerCase());
  }

  void _navigateToPatientDetail(PatientListItem patient) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => _PatientMedicationsDetailScreen(patient: patient)));
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
                child: Column(children: [_buildPatientSelector(), const SizedBox(height: 16), _buildSelectPatientCard()]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16, bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 32,
              decoration: BoxDecoration(color: const Color(0xFFD7D1C5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFA49E86))),
              child: const Icon(Icons.arrow_back, color: Color(0xFF4F4A34), size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Medicações', style: TextStyle(color: Color(0xFF4F4A34), fontSize: 24, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPatientSelector() {
    return Consumer<PatientsProvider>(
      builder: (context, provider, _) {
        final filteredPatients = _searchQuery.isEmpty ? provider.patients : provider.patients.where((p) => p.name.toLowerCase().contains(_searchQuery) || (p.phone?.toLowerCase().contains(_searchQuery) ?? false)).toList();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF4F4A34), width: 2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecione um Paciente', style: TextStyle(color: Color(0xFF212621), fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFFF5F3EF), borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Buscar paciente...', hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontFamily: 'Inter'), prefixIcon: Icon(Icons.search, color: Color(0xFF697282), size: 20), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: provider.isLoadingList
                    ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator(color: Color(0xFFA49E86))))
                    : filteredPatients.isEmpty
                        ? const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Nenhum paciente encontrado', style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'))))
                        : ListView.separated(shrinkWrap: true, itemCount: filteredPatients.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) => _PatientCard(patient: filteredPatients[i], onTap: () => _navigateToPatientDetail(filteredPatients[i]))),
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFC8C2B4))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFF5F3EF), borderRadius: BorderRadius.circular(32)), child: const Icon(Icons.medication_outlined, color: Color(0xFF697282), size: 32)),
          const SizedBox(height: 20),
          const Text('Selecione um paciente', style: TextStyle(color: Color(0xFF212621), fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('para visualizar e gerenciar\nas orientações de medicamentos', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w400)),
          const SizedBox(height: 24),
          // Legenda das categorias
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Categorias de medicamentos:', style: TextStyle(color: Color(0xFF4F4A34), fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildCategoryLegend(MedicationCategory.allowed),
                    const SizedBox(width: 16),
                    _buildCategoryLegend(MedicationCategory.restricted),
                    const SizedBox(width: 16),
                    _buildCategoryLegend(MedicationCategory.prohibited),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(MedicationCategory category) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(category.icon, color: category.color, size: 16),
        const SizedBox(width: 4),
        Text(category.displayName, style: TextStyle(color: category.color, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
      ],
    );
  }
}

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
        decoration: BoxDecoration(color: const Color(0xFFF5F3EF), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF4F4A34), borderRadius: BorderRadius.circular(20)), child: Center(child: Text(patient.name.isNotEmpty ? patient.name.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w600)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patient.name, style: const TextStyle(color: Color(0xFF212621), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)), const SizedBox(height: 2), Text((patient.phone?.isNotEmpty ?? false) ? patient.phone! : 'Sem telefone', style: const TextStyle(color: Color(0xFF697282), fontSize: 12, fontFamily: 'Inter'))])),
            if (patient.dayPostOp != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFA49E86).withAlpha(26), borderRadius: BorderRadius.circular(8)), child: Text('D+${patient.dayPostOp}', style: const TextStyle(color: Color(0xFF4F4A34), fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF697282), size: 20),
          ],
        ),
      ),
    );
  }
}

class _PatientMedicationsDetailScreen extends StatefulWidget {
  final PatientListItem patient;
  const _PatientMedicationsDetailScreen({required this.patient});

  @override
  State<_PatientMedicationsDetailScreen> createState() => _PatientMedicationsDetailScreenState();
}

class _PatientMedicationsDetailScreenState extends State<_PatientMedicationsDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MedicationCategory _selectedCategory = MedicationCategory.allowed;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = MedicationCategory.values[_tabController.index];
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ClinicContentProvider>();
      if (provider.currentType != 'MEDICATIONS') provider.loadContentsByType('MEDICATIONS');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Filtra conteúdos por categoria
  List<ClinicContent> _getItemsByCategory(List<ClinicContent> items, MedicationCategory category) {
    return items.where((item) => item.category == category.apiValue).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7D1C5),
      body: SafeArea(
        top: false,
        child: Column(children: [
          _buildHeader(),
          _buildPatientInfo(),
          _buildCategoryTabs(),
          _buildAddButton(),
          Expanded(child: Consumer<ClinicContentProvider>(builder: (context, provider, _) {
            if (provider.isLoadingContents) return const Center(child: CircularProgressIndicator(color: Color(0xFFA49E86)));
            return _buildList(provider);
          })),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16, bottom: 16),
      child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 38, height: 32, decoration: BoxDecoration(color: const Color(0xFFD7D1C5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFA49E86))), child: const Icon(Icons.arrow_back, color: Color(0xFF4F4A34), size: 16))),
        const SizedBox(width: 12),
        const Text('Medicações', style: TextStyle(color: Color(0xFF4F4A34), fontSize: 24, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4F4A34), Color(0xFF212621)]), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withAlpha(26), borderRadius: BorderRadius.circular(24)), child: Center(child: Text(widget.patient.name.isNotEmpty ? widget.patient.name.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w600)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.patient.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(widget.patient.dayPostOp != null ? 'D+${widget.patient.dayPostOp} pós-operatório' : (widget.patient.phone ?? 'Sem telefone'), style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 13, fontFamily: 'Inter'))])),
      ]),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _selectedCategory.color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: _selectedCategory.color,
        unselectedLabelColor: const Color(0xFF697282),
        labelStyle: const TextStyle(fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500),
        tabs: MedicationCategory.values.map((cat) => Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat.icon, size: 16),
              const SizedBox(width: 4),
              Text(cat.displayName),
            ],
          ),
        )).toList(),
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
          height: 40,
          decoration: BoxDecoration(
            color: _selectedCategory.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Adicionar em "${_selectedCategory.displayName}"',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(ClinicContentProvider provider) {
    final items = _getItemsByCategory(provider.contents, _selectedCategory);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_selectedCategory.icon, color: _selectedCategory.color.withAlpha(128), size: 48),
            const SizedBox(height: 16),
            Text(
              'Nenhum medicamento "${_selectedCategory.displayName}"',
              style: const TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão acima para adicionar',
              style: const TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
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
        final allItems = List<ClinicContent>.from(provider.contents);
        // Encontrar índices reais na lista completa
        final oldItem = items[oldIndex];
        final newItem = items[newIndex < items.length ? newIndex : items.length - 1];
        final realOldIndex = allItems.indexWhere((c) => c.id == oldItem.id);
        final realNewIndex = allItems.indexWhere((c) => c.id == newItem.id);
        if (realOldIndex != -1 && realNewIndex != -1) {
          final item = allItems.removeAt(realOldIndex);
          allItems.insert(realNewIndex, item);
          await provider.reorderContents(allItems.map((c) => c.id).toList());
        }
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _ContentCard(
            item: item,
            category: _selectedCategory,
            onToggle: () => context.read<ClinicContentProvider>().toggleContent(item.id),
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
        title: const Text('Excluir medicamento?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ClinicContentProvider>().deleteContent(id);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Medicamento excluído' : 'Erro ao excluir')));
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE7000B)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContentFormModal(
        category: _selectedCategory,
        onSave: (title, description, category) async {
          final success = await context.read<ClinicContentProvider>().createContent(
            type: 'MEDICATIONS',
            category: category.apiValue,
            title: title,
            description: description.isNotEmpty ? description : null,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Medicamento adicionado' : 'Erro ao adicionar')));
            if (success) context.read<ClinicContentProvider>().loadStats();
          }
        },
      ),
    );
  }

  void _showEditModal(ClinicContent item) {
    // Determinar categoria do item
    MedicationCategory itemCategory = MedicationCategory.allowed;
    for (final cat in MedicationCategory.values) {
      if (cat.apiValue == item.category) {
        itemCategory = cat;
        break;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContentFormModal(
        item: item,
        category: itemCategory,
        onSave: (title, description, category) async {
          final success = await context.read<ClinicContentProvider>().updateContent(
            item.id,
            title: title,
            description: description.isNotEmpty ? description : null,
            category: category.apiValue,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Medicamento atualizado' : 'Erro ao atualizar')));
            // Recarregar para refletir mudança de categoria
            if (success) context.read<ClinicContentProvider>().loadContentsByType('MEDICATIONS');
          }
        },
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ClinicContent item;
  final MedicationCategory category;
  final VoidCallback onToggle, onDelete, onEdit;
  const _ContentCard({required this.item, required this.category, required this.onToggle, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withAlpha(77), width: 1.5),
        ),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Ícone da categoria
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: category.color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(color: Color(0xFF212621), fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.description!, style: const TextStyle(color: Color(0xFF697282), fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w400), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.drag_indicator, color: Color(0xFFC8C2B4), size: 20)),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: item.isActive ? const Color(0xFF00A63E).withAlpha(26) : const Color(0xFF697282).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(item.isActive ? Icons.visibility : Icons.visibility_off, color: item.isActive ? const Color(0xFF00A63E) : const Color(0xFF697282), size: 16),
                  const SizedBox(width: 4),
                  Text(item.isActive ? 'Ativo' : 'Inativo', style: TextStyle(color: item.isActive ? const Color(0xFF00A63E) : const Color(0xFF697282), fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE7000B).withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.delete_outline, color: Color(0xFFE7000B), size: 16),
                  SizedBox(width: 4),
                  Text('Excluir', style: TextStyle(color: Color(0xFFE7000B), fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ContentFormModal extends StatefulWidget {
  final ClinicContent? item;
  final MedicationCategory category;
  final void Function(String title, String description, MedicationCategory category) onSave;
  const _ContentFormModal({this.item, required this.category, required this.onSave});

  @override
  State<_ContentFormModal> createState() => _ContentFormModalState();
}

class _ContentFormModalState extends State<_ContentFormModal> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late MedicationCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _selectedCategory = widget.category;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome do medicamento')));
      return;
    }
    widget.onSave(title, description, _selectedCategory);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(_selectedCategory.icon, color: _selectedCategory.color, size: 24),
                const SizedBox(width: 8),
                Text(isEditing ? 'Editar Medicamento' : 'Novo Medicamento', style: const TextStyle(color: Color(0xFF212621), fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              ]),
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF697282))),
            ]),
            const SizedBox(height: 24),

            // Seletor de categoria
            const Text('Categoria', style: TextStyle(color: Color(0xFF4F4A34), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: MedicationCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: EdgeInsets.only(right: cat != MedicationCategory.prohibited ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.color.withAlpha(26) : const Color(0xFFF5F3EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? cat.color : const Color(0xFFE0E0E0), width: isSelected ? 2 : 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, color: isSelected ? cat.color : const Color(0xFF697282), size: 20),
                          const SizedBox(height: 4),
                          Text(cat.displayName, style: TextStyle(color: isSelected ? cat.color : const Color(0xFF697282), fontSize: 11, fontFamily: 'Inter', fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Nome do medicamento
            const Text('Nome do Medicamento', style: TextStyle(color: Color(0xFF4F4A34), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Paracetamol, Ibuprofeno, AAS...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F3EF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Descrição/Observações
            const Text('Observações (opcional)', style: TextStyle(color: Color(0xFF4F4A34), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Motivo, instruções especiais...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F3EF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Botão salvar
            GestureDetector(
              onTap: _handleSave,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(color: _selectedCategory.color, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(isEditing ? 'Salvar Alterações' : 'Adicionar', style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w600))),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
