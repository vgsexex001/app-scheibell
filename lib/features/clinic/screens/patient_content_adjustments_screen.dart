import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinic_content_provider.dart';
import '../models/models.dart';
import '../../../core/services/training_service.dart';

/// Tela de Ajustes de Conteúdo do Paciente
/// Estrutura igual à Gestão de Conteúdos (clinic_symptoms_screen.dart)
/// com sub-abas por categoria (Normal, Avisar, Emergência) e botão de adicionar
class PatientContentAdjustmentsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientContentAdjustmentsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientContentAdjustmentsScreen> createState() =>
      _PatientContentAdjustmentsScreenState();
}

class _PatientContentAdjustmentsScreenState
    extends State<PatientContentAdjustmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  final List<_ContentType> _contentTypes = [
    _ContentType(
      id: 'SYMPTOMS',
      label: 'Sintomas',
      icon: Icons.thermostat_outlined,
      color: const Color(0xFFE53935),
      addButtonLabel: 'Adicionar Sintoma',
      categories: [
        _Category('NORMAL', 'Normais', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
        _Category('WARNING', 'Avisar', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.warning_amber_outlined),
        _Category('EMERGENCY', 'Emergência', const Color(0xFFE7000B), const Color(0xFFE7000B), Icons.emergency_outlined),
      ],
    ),
    _ContentType(
      id: 'DIET',
      label: 'Dietas',
      icon: Icons.restaurant_outlined,
      color: const Color(0xFF4CAF50),
      addButtonLabel: 'Adicionar Dieta',
      categories: [
        _Category('ALLOWED', 'Permitidos', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
        _Category('RESTRICTED', 'Restritos', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.warning_amber_outlined),
        _Category('PROHIBITED', 'Proibidos', const Color(0xFFE7000B), const Color(0xFFE7000B), Icons.block_outlined),
      ],
    ),
    _ContentType(
      id: 'TRAINING',
      label: 'Treinos',
      icon: Icons.fitness_center_outlined,
      color: const Color(0xFFFF9800),
      addButtonLabel: 'Adicionar Treino',
      categories: [
        _Category('ALLOWED', 'Permitidos', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
        _Category('RESTRICTED', 'Restritos', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.warning_amber_outlined),
        _Category('PROHIBITED', 'Proibidos', const Color(0xFFE7000B), const Color(0xFFE7000B), Icons.block_outlined),
      ],
    ),
    _ContentType(
      id: 'MEDICATIONS',
      label: 'Medicamentos',
      icon: Icons.medication_outlined,
      color: const Color(0xFFE91E63),
      addButtonLabel: 'Adicionar Medicamento',
      categories: [
        _Category('ALLOWED', 'Permitidos', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
        _Category('RESTRICTED', 'Restritos', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.warning_amber_outlined),
        _Category('PROHIBITED', 'Proibidos', const Color(0xFFE7000B), const Color(0xFFE7000B), Icons.block_outlined),
      ],
    ),
    _ContentType(
      id: 'CARE',
      label: 'Cuidados',
      icon: Icons.medical_services_outlined,
      color: const Color(0xFF9C27B0),
      addButtonLabel: 'Adicionar Cuidado',
      categories: [
        _Category('CARE', 'Cuidado', const Color(0xFFE7000B), const Color(0xFFC50009), Icons.medical_services_outlined),
        _Category('REQUIRED', 'Fazer', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
        _Category('OPTIONAL', 'Opcional', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.help_outline),
        _Category('NOT_REQUIRED', 'Não necessário', const Color(0xFF697282), const Color(0xFF495565), Icons.remove_circle_outline),
      ],
    ),
    _ContentType(
      id: 'ACTIVITIES',
      label: 'Atividades',
      icon: Icons.directions_run_outlined,
      color: const Color(0xFF2196F3),
      addButtonLabel: 'Adicionar Atividade',
      categories: [
        _Category('ALLOWED', 'Permitidas', const Color(0xFF00A63E), const Color(0xFF008235), Icons.check_circle_outline),
        _Category('RESTRICTED', 'Restritas', const Color(0xFFF0B100), const Color(0xFFD08700), Icons.warning_amber_outlined),
        _Category('PROHIBITED', 'Proibidas', const Color(0xFFE7000B), const Color(0xFFE7000B), Icons.block_outlined),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: _contentTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
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
            _buildMainTabBar(),
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: _contentTypes.map((type) {
                  // Usar view especial para Treinos (semanas do protocolo)
                  if (type.id == 'TRAINING') {
                    return _PatientTrainingView(
                      patientId: widget.patientId,
                      patientName: widget.patientName,
                    );
                  }
                  return _ContentTypeView(
                    patientId: widget.patientId,
                    patientName: widget.patientName,
                    contentType: type,
                  );
                }).toList(),
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
            'Ajustar Conteúdos',
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
                widget.patientName.isNotEmpty
                    ? widget.patientName.substring(0, 1).toUpperCase()
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
                  widget.patientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ajustes personalizados de conteúdo',
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

  Widget _buildMainTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: const Color(0xFFD7D1C5),
      child: TabBar(
        controller: _mainTabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelColor: const Color(0xFF4F4A34),
        unselectedLabelColor: const Color(0xFF697282),
        indicatorColor: const Color(0xFF4F4A34),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
        tabs: _contentTypes.map((type) => Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 18),
              const SizedBox(width: 6),
              Text(type.label),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ==================== MODELS ====================

class _ContentType {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String addButtonLabel;
  final List<_Category> categories;

  const _ContentType({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.addButtonLabel,
    required this.categories,
  });
}

class _Category {
  final String id;
  final String name;
  final Color color;
  final Color textColor;
  final IconData icon;

  const _Category(this.id, this.name, this.color, this.textColor, this.icon);
}

// ==================== CONTENT TYPE VIEW ====================

class _ContentTypeView extends StatefulWidget {
  final String patientId;
  final String patientName;
  final _ContentType contentType;

  const _ContentTypeView({
    required this.patientId,
    required this.patientName,
    required this.contentType,
  });

  @override
  State<_ContentTypeView> createState() => _ContentTypeViewState();
}

class _ContentTypeViewState extends State<_ContentTypeView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _categoryTabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(
      length: widget.contentType.categories.length,
      vsync: this,
    );
    // Carregar conteúdos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicContentProvider>().loadContentsByType(widget.contentType.id);
    });
  }

  @override
  void dispose() {
    _categoryTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildCategoryTabBar(),
        _buildAddButton(),
        Expanded(
          child: Consumer<ClinicContentProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingContents) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFA49E86),
                  ),
                );
              }

              return TabBarView(
                controller: _categoryTabController,
                children: widget.contentType.categories.map((cat) =>
                  _buildList(cat, provider)
                ).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabBar() {
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
        controller: _categoryTabController,
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        tabs: widget.contentType.categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          return Tab(
            child: AnimatedBuilder(
              animation: _categoryTabController,
              builder: (context, _) {
                final isSelected = _categoryTabController.index == index;
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                widget.contentType.addButtonLabel,
                style: const TextStyle(
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
            Text(
              'Toque em "${widget.contentType.addButtonLabel}"',
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
        final itemsCopy = List<ClinicContent>.from(items);
        final item = itemsCopy.removeAt(oldIndex);
        itemsCopy.insert(newIndex, item);

        // Chamar API de reorder
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
                  SnackBar(
                    content: Text(success ? 'Item excluído' : 'Erro ao excluir'),
                  ),
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
    final category = widget.contentType.categories[_categoryTabController.index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContentFormModal(
        contentType: widget.contentType,
        category: category,
        onSave: (title, description) async {
          final success = await context.read<ClinicContentProvider>().createContent(
            type: widget.contentType.id,
            category: category.id,
            title: title,
            description: description.isNotEmpty ? description : null,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Item adicionado' : 'Erro ao adicionar'),
              ),
            );
            // Atualizar stats
            if (success) {
              context.read<ClinicContentProvider>().loadStats();
            }
          }
        },
      ),
    );
  }

  void _showEditModal(ClinicContent item) {
    final category = widget.contentType.categories.firstWhere(
      (c) => c.id == item.category,
      orElse: () => widget.contentType.categories.first,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContentFormModal(
        contentType: widget.contentType,
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
              SnackBar(
                content: Text(success ? 'Item atualizado' : 'Erro ao atualizar'),
              ),
            );
          }
        },
      ),
    );
  }
}

// ==================== CONTENT CARD ====================

class _ContentCard extends StatelessWidget {
  final ClinicContent item;
  final _Category category;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

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
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        // Descrição
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
            // Botões
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
                          color: item.isActive
                              ? const Color(0xFF00A63E)
                              : const Color(0xFF697282),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isActive ? 'Ativo' : 'Inativo',
                          style: TextStyle(
                            color: item.isActive
                                ? const Color(0xFF00A63E)
                                : const Color(0xFF697282),
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
  final _ContentType contentType;
  final _Category category;
  final ClinicContent? item;
  final void Function(String title, String description) onSave;

  const _ContentFormModal({
    required this.contentType,
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
                  isEditing ? 'Editar ${widget.contentType.label}' : 'Novo ${widget.contentType.label}',
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

            // Categoria badge
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
                hintText: 'Ex: Inchaço moderado',
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

            // Descrição
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
                hintText: 'Orientação para o paciente...',
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

// ==================== PATIENT TRAINING VIEW (SEMANAS DO PROTOCOLO) ====================

class _PatientTrainingView extends StatefulWidget {
  final String patientId;
  final String patientName;

  const _PatientTrainingView({
    required this.patientId,
    required this.patientName,
  });

  @override
  State<_PatientTrainingView> createState() => _PatientTrainingViewState();
}

class _PatientTrainingViewState extends State<_PatientTrainingView>
    with AutomaticKeepAliveClientMixin {
  final TrainingService _trainingService = TrainingService();
  PatientTrainingData? _trainingData;
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTrainingData();
  }

  Future<void> _loadTrainingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _trainingService.getPatientTrainingData(widget.patientId);
      if (mounted) {
        setState(() {
          _trainingData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar treino do paciente: $e');
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar dados do treino';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA49E86)),
      );
    }

    if (_error != null || _trainingData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center_outlined, color: Color(0xFF697282), size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Nenhum protocolo encontrado',
              style: const TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadTrainingData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F4A34),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrainingData,
      color: const Color(0xFF4F4A34),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info do progresso
          _buildProgressCard(),
          const SizedBox(height: 16),
          // Lista de semanas
          ..._trainingData!.weeks.map((week) => _buildWeekCard(week)),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final data = _trainingData!;
    return Container(
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protocolo de Treino',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Semana ${data.currentWeek} de ${data.totalWeeks} • D+${data.daysSinceSurgery}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${data.progressPercent}%',
              style: const TextStyle(
                color: Colors.white,
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

  Widget _buildWeekCard(PatientWeekData week) {
    final isCurrent = week.status == 'CURRENT';
    final isCompleted = week.status == 'COMPLETED';

    return GestureDetector(
      onTap: () => _showWeekDetail(week),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? const Color(0xFF4F4A34) : const Color(0xFFC8C2B4),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getWeekColor(week.weekNumber).withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${week.weekNumber}',
                      style: TextStyle(
                        color: _getWeekColor(week.weekNumber),
                        fontSize: 18,
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
                          Expanded(
                            child: Text(
                              week.title,
                              style: const TextStyle(
                                color: Color(0xFF212621),
                                fontSize: 15,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F4A34),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ATUAL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (isCompleted)
                            const Icon(Icons.check_circle, color: Color(0xFF00A63E), size: 20),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        week.dayRange,
                        style: const TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (week.heartRateLabel != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7000B).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Color(0xFFE7000B), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      week.heartRateLabel!,
                      style: const TextStyle(
                        color: Color(0xFFE7000B),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Preview de canDo e avoid
            if (week.canDo.isNotEmpty || week.avoid.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 12),
              if (week.canDo.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF00A63E), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Pode fazer: ${week.canDo.take(2).join(", ")}${week.canDo.length > 2 ? "..." : ""}',
                        style: const TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
              if (week.avoid.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber, color: Color(0xFFD08700), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Evitar: ${week.avoid.take(2).join(", ")}${week.avoid.length > 2 ? "..." : ""}',
                        style: const TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            // Indicador de ajustes personalizados
            if (week.hasAdjustment ?? false) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note, color: Color(0xFF9C27B0), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Personalizado',
                      style: TextStyle(
                        color: Color(0xFF9C27B0),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getWeekColor(int weekNumber) {
    final colors = [
      const Color(0xFF4F4A34),
      const Color(0xFF5C5641),
      const Color(0xFF69624E),
      const Color(0xFF766E5B),
      const Color(0xFF837A68),
      const Color(0xFF908675),
      const Color(0xFF9D9282),
      const Color(0xFFA49E86),
    ];
    return colors[(weekNumber - 1) % colors.length];
  }

  void _showWeekDetail(PatientWeekData week) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WeekDetailModal(
        week: week,
        patientId: widget.patientId,
        onAdjustmentSaved: _loadTrainingData,
      ),
    );
  }
}

// ==================== WEEK DETAIL MODAL ====================

class _WeekDetailModal extends StatefulWidget {
  final PatientWeekData week;
  final String patientId;
  final VoidCallback onAdjustmentSaved;

  const _WeekDetailModal({
    required this.week,
    required this.patientId,
    required this.onAdjustmentSaved,
  });

  @override
  State<_WeekDetailModal> createState() => _WeekDetailModalState();
}

class _WeekDetailModalState extends State<_WeekDetailModal> {
  final TrainingService _trainingService = TrainingService();
  bool _isEditingCanDo = false;
  bool _isEditingAvoid = false;
  late List<String> _editedCanDo;
  late List<String> _editedAvoid;
  final TextEditingController _newItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editedCanDo = List.from(widget.week.canDo);
    _editedAvoid = List.from(widget.week.avoid);
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _saveAdjustment() async {
    try {
      // Calcular dias de início e fim da semana
      final validFromDay = (widget.week.weekNumber - 1) * 7 + 1;
      final validUntilDay = widget.week.weekNumber * 7;

      await _trainingService.createPatientAdjustment(
        widget.patientId,
        adjustmentType: 'MODIFY',
        weekId: widget.week.id,
        validFromDay: validFromDay,
        validUntilDay: validUntilDay,
        canDo: _editedCanDo,
        avoid: _editedAvoid,
        reason: 'Ajuste personalizado para semana ${widget.week.weekNumber}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajuste salvo com sucesso')),
        );
        widget.onAdjustmentSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Erro ao salvar ajuste: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  void _addItem(bool isCanDo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCanDo ? 'Adicionar Permitido' : 'Adicionar Evitar'),
        content: TextField(
          controller: _newItemController,
          decoration: const InputDecoration(hintText: 'Digite o item...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newItemController.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newItemController.text.trim().isNotEmpty) {
                setState(() {
                  if (isCanDo) {
                    _editedCanDo.add(_newItemController.text.trim());
                    _isEditingCanDo = true;
                  } else {
                    _editedAvoid.add(_newItemController.text.trim());
                    _isEditingAvoid = true;
                  }
                });
                _newItemController.clear();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F4A34)),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index, bool isCanDo) {
    setState(() {
      if (isCanDo) {
        _editedCanDo.removeAt(index);
        _isEditingCanDo = true;
      } else {
        _editedAvoid.removeAt(index);
        _isEditingAvoid = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _isEditingCanDo || _isEditingAvoid;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getWeekColor(widget.week.weekNumber).withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.week.weekNumber}',
                      style: TextStyle(
                        color: _getWeekColor(widget.week.weekNumber),
                        fontSize: 18,
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
                        widget.week.title,
                        style: const TextStyle(
                          color: Color(0xFF212621),
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.week.dayRange,
                        style: const TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF697282)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Conteúdo
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Objetivo
                if (widget.week.objective.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Objetivo',
                          style: TextStyle(
                            color: Color(0xFF4F4A34),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.week.objective,
                          style: const TextStyle(
                            color: Color(0xFF697282),
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Frequência cardíaca
                if (widget.week.heartRateLabel != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7000B).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE7000B).withAlpha(51)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Color(0xFFE7000B), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'FC Máxima: ${widget.week.heartRateLabel}',
                          style: const TextStyle(
                            color: Color(0xFFE7000B),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Pode Fazer (editável)
                _buildEditableSection(
                  title: 'Pode Fazer',
                  icon: Icons.check_circle,
                  color: const Color(0xFF00A63E),
                  items: _editedCanDo,
                  isCanDo: true,
                ),
                const SizedBox(height: 16),
                // Evitar (editável)
                _buildEditableSection(
                  title: 'Evitar',
                  icon: Icons.warning_amber,
                  color: const Color(0xFFD08700),
                  items: _editedAvoid,
                  isCanDo: false,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Botão salvar (se houve mudanças)
          if (hasChanges)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: GestureDetector(
                onTap: _saveAdjustment,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F4A34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Salvar Ajustes',
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
            ),
        ],
      ),
    );
  }

  Widget _buildEditableSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required bool isCanDo,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _addItem(isCanDo),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: color, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Adicionar',
                        style: TextStyle(
                          color: color,
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
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Nenhum item',
              style: TextStyle(
                color: color.withAlpha(179),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.asMap().entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withAlpha(77)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeItem(entry.key, isCanDo),
                        child: Icon(Icons.close, color: color, size: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Color _getWeekColor(int weekNumber) {
    final colors = [
      const Color(0xFF4F4A34),
      const Color(0xFF5C5641),
      const Color(0xFF69624E),
      const Color(0xFF766E5B),
      const Color(0xFF837A68),
      const Color(0xFF908675),
      const Color(0xFF9D9282),
      const Color(0xFFA49E86),
    ];
    return colors[(weekNumber - 1) % colors.length];
  }
}
