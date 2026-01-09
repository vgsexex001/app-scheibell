import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinic_content_provider.dart';
import '../providers/patients_provider.dart';
import '../models/models.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFC8C2B4))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFF5F3EF), borderRadius: BorderRadius.circular(32)), child: const Icon(Icons.medication_outlined, color: Color(0xFF697282), size: 32)),
          const SizedBox(height: 20),
          const Text('Selecione um paciente', style: TextStyle(color: Color(0xFF212621), fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('para visualizar e gerenciar\nas medicações prescritas', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w400)),
        ],
      ),
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

class _PatientMedicationsDetailScreenState extends State<_PatientMedicationsDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ClinicContentProvider>();
      if (provider.currentType != 'MEDICATIONS') provider.loadContentsByType('MEDICATIONS');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7D1C5),
      body: SafeArea(
        top: false,
        child: Column(children: [_buildHeader(), _buildPatientInfo(), _buildAddButton(), Expanded(child: Consumer<ClinicContentProvider>(builder: (context, provider, _) {
          if (provider.isLoadingContents) return const Center(child: CircularProgressIndicator(color: Color(0xFFA49E86)));
          return _buildList(provider);
        }))]),
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

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showAddModal,
        child: Container(width: double.infinity, height: 36, decoration: BoxDecoration(color: const Color(0xFF4F4A34), borderRadius: BorderRadius.circular(12)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: Colors.white, size: 16), SizedBox(width: 8), Text('Adicionar Medicação', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500))])),
      ),
    );
  }

  Widget _buildList(ClinicContentProvider provider) {
    final items = provider.contents;
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.medication_outlined, color: Color(0xFF697282), size: 48), SizedBox(height: 16), Text('Nenhuma medicação cadastrada', style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter')), SizedBox(height: 8), Text('Toque em "Adicionar Medicação"', style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'))]));
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        final itemsCopy = List<ClinicContent>.from(items);
        final item = itemsCopy.removeAt(oldIndex);
        itemsCopy.insert(newIndex, item);
        await provider.reorderContents(itemsCopy.map((c) => c.id).toList());
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(key: ValueKey(item.id), padding: const EdgeInsets.only(bottom: 12), child: _ContentCard(item: item, onToggle: () => context.read<ClinicContentProvider>().toggleContent(item.id), onDelete: () => _deleteItem(item.id), onEdit: () => _showEditModal(item)));
      },
    );
  }

  void _deleteItem(String id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Text('Excluir item?'), content: const Text('Esta ação não pode ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), TextButton(onPressed: () async { Navigator.pop(ctx); final success = await context.read<ClinicContentProvider>().deleteContent(id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Item excluído' : 'Erro ao excluir'))); }, style: TextButton.styleFrom(foregroundColor: const Color(0xFFE7000B)), child: const Text('Excluir'))]));
  }

  void _showAddModal() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => _ContentFormModal(onSave: (title, description) async { final success = await context.read<ClinicContentProvider>().createContent(type: 'MEDICATIONS', category: 'INFO', title: title, description: description.isNotEmpty ? description : null); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Item adicionado' : 'Erro ao adicionar'))); if (success) context.read<ClinicContentProvider>().loadStats(); } }));
  }

  void _showEditModal(ClinicContent item) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => _ContentFormModal(item: item, onSave: (title, description) async { final success = await context.read<ClinicContentProvider>().updateContent(item.id, title: title, description: description.isNotEmpty ? description : null); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Item atualizado' : 'Erro ao atualizar'))); }));
  }
}

class _ContentCard extends StatelessWidget {
  final ClinicContent item;
  final VoidCallback onToggle, onDelete, onEdit;
  const _ContentCard({required this.item, required this.onToggle, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFC8C2B4))),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.drag_indicator, color: Color(0xFF697282), size: 20)),
            const SizedBox(width: 8),
            Expanded(child: Column(children: [Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF5F3EF), borderRadius: BorderRadius.circular(12)), child: Text(item.title, style: const TextStyle(color: Color(0xFF212621), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500))), if (item.description != null && item.description!.isNotEmpty) ...[const SizedBox(height: 8), Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF5F3EF), borderRadius: BorderRadius.circular(12)), child: Text(item.description!, style: const TextStyle(color: Color(0xFF212621), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w400)))]])),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            GestureDetector(onTap: onToggle, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: item.isActive ? const Color(0xFF00A63E).withAlpha(26) : const Color(0xFF697282).withAlpha(26), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(item.isActive ? Icons.visibility : Icons.visibility_off, color: item.isActive ? const Color(0xFF00A63E) : const Color(0xFF697282), size: 16), const SizedBox(width: 4), Text(item.isActive ? 'Ativo' : 'Inativo', style: TextStyle(color: item.isActive ? const Color(0xFF00A63E) : const Color(0xFF697282), fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500))]))),
            const SizedBox(width: 8),
            GestureDetector(onTap: onDelete, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE7000B).withAlpha(26), borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.delete_outline, color: Color(0xFFE7000B), size: 16), SizedBox(width: 4), Text('Excluir', style: TextStyle(color: Color(0xFFE7000B), fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500))]))),
          ]),
        ]),
      ),
    );
  }
}

class _ContentFormModal extends StatefulWidget {
  final ClinicContent? item;
  final void Function(String title, String description) onSave;
  const _ContentFormModal({this.item, required this.onSave});

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
  void dispose() { _titleController.dispose(); _descriptionController.dispose(); super.dispose(); }

  void _handleSave() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o título'))); return; }
    widget.onSave(title, description);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isEditing ? 'Editar Medicação' : 'Nova Medicação', style: const TextStyle(color: Color(0xFF212621), fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w600)), GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF697282)))]),
          const SizedBox(height: 24),
          const Text('Título', style: TextStyle(color: Color(0xFF4F4A34), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(controller: _titleController, decoration: InputDecoration(hintText: 'Ex: Paracetamol 750mg', hintStyle: const TextStyle(color: Color(0xFF9CA3AF)), filled: true, fillColor: const Color(0xFFF5F3EF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
          const SizedBox(height: 16),
          const Text('Descrição', style: TextStyle(color: Color(0xFF4F4A34), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(controller: _descriptionController, maxLines: 3, decoration: InputDecoration(hintText: 'Posologia e instruções...', hintStyle: const TextStyle(color: Color(0xFF9CA3AF)), filled: true, fillColor: const Color(0xFFF5F3EF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
          const SizedBox(height: 24),
          GestureDetector(onTap: _handleSave, child: Container(width: double.infinity, height: 48, decoration: BoxDecoration(color: const Color(0xFF4F4A34), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(isEditing ? 'Salvar Alterações' : 'Adicionar', style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w600))))),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
