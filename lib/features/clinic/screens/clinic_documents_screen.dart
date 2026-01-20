import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/patients_provider.dart';
import '../models/models.dart';
import '../../../core/services/api_service.dart';

/// Converte URLs de localhost para 10.0.2.2 no emulador Android
String _fixImageUrl(String url) {
  if (url.isEmpty) return url;
  if (kIsWeb) return url;
  if (Platform.isAndroid) {
    return url.replaceAll('localhost', '10.0.2.2');
  }
  return url;
}

class ClinicDocumentsScreen extends StatefulWidget {
  const ClinicDocumentsScreen({super.key});

  @override
  State<ClinicDocumentsScreen> createState() => _ClinicDocumentsScreenState();
}

class _ClinicDocumentsScreenState extends State<ClinicDocumentsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  String _searchQuery = '';
  late TabController _tabController;

  // Indica se há documentos pendentes de revisão (enviados por pacientes)
  bool _hasUnreadRecebidos = false;

  // Lista de IDs de pacientes que têm documentos pendentes de revisão
  Set<String> _patientsWithNewDocs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientsProvider>().loadPatients(refresh: true);
      _loadPendingReviewDocuments();
    });
  }

  Future<void> _loadPendingReviewDocuments() async {
    try {
      // Buscar documentos pendentes de revisão usando o endpoint que filtra por DOCUMENT
      final response = await _apiService.get('/exams/admin/pending?fileType=DOCUMENT');
      final data = response.data;
      if (data != null && data['items'] != null) {
        final items = List<Map<String, dynamic>>.from(data['items']);
        final patientIds = items.map((e) => e['patientId']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
        if (mounted) {
          setState(() {
            _patientsWithNewDocs = patientIds;
            _hasUnreadRecebidos = patientIds.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar documentos pendentes: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.toLowerCase());
  }

  void _navigateToPatientDocuments(PatientListItem patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PatientDocumentsDetailScreen(patient: patient),
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
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEnviarTab(),
                  _buildRecebidosTab(),
                ],
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
            'Documentos',
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF4F4A34),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF697282),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          const Tab(text: 'Enviar'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Recebidos'),
                if (_hasUnreadRecebidos) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnviarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPatientSelector(onSelectPatient: _navigateToPatientDocuments),
          const SizedBox(height: 16),
          _buildEnviarCard(),
        ],
      ),
    );
  }

  Widget _buildRecebidosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPatientSelectorRecebidos(),
          const SizedBox(height: 16),
          _buildRecebidosCard(),
        ],
      ),
    );
  }

  Widget _buildPatientSelector({required Function(PatientListItem) onSelectPatient}) {
    return Consumer<PatientsProvider>(
      builder: (context, provider, _) {
        final filteredPatients = _searchQuery.isEmpty
            ? provider.patients
            : provider.patients
                .where((p) =>
                    p.name.toLowerCase().contains(_searchQuery) ||
                    (p.phone?.toLowerCase().contains(_searchQuery) ?? false))
                .toList();
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
                'Selecione um Paciente para Enviar',
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
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontFamily: 'Inter'),
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
                                style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredPatients.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _PatientCard(
                              patient: filteredPatients[i],
                              onTap: () => onSelectPatient(filteredPatients[i]),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientSelectorRecebidos() {
    return Consumer<PatientsProvider>(
      builder: (context, provider, _) {
        final filteredPatients = _searchQuery.isEmpty
            ? provider.patients
            : provider.patients
                .where((p) =>
                    p.name.toLowerCase().contains(_searchQuery) ||
                    (p.phone?.toLowerCase().contains(_searchQuery) ?? false))
                .toList();
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
                'Filtrar por Paciente',
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
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontFamily: 'Inter'),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF697282), size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
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
                                style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredPatients.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _PatientCard(
                              patient: filteredPatients[i],
                              hasNewContent: _patientsWithNewDocs.contains(filteredPatients[i].id),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _PatientReceivedDocumentsScreen(patient: filteredPatients[i]),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnviarCard() {
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
            child: const Icon(Icons.upload_file, color: Color(0xFF697282), size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Enviar Documento',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecione um paciente para\nenviar documentos importantes',
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

  Widget _buildRecebidosCard() {
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
            child: const Icon(Icons.inbox, color: Color(0xFF697282), size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Documentos Recebidos',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecione um paciente para\nvisualizar os documentos enviados',
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

class _PatientCard extends StatelessWidget {
  final PatientListItem patient;
  final VoidCallback onTap;
  final bool hasNewContent;
  const _PatientCard({required this.patient, required this.onTap, this.hasNewContent = false});

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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          patient.name,
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hasNewContent) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
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

// ========== TELA DE ENVIAR DOCUMENTOS PARA PACIENTE ==========
class _PatientDocumentsDetailScreen extends StatefulWidget {
  final PatientListItem patient;
  const _PatientDocumentsDetailScreen({required this.patient});

  @override
  State<_PatientDocumentsDetailScreen> createState() => _PatientDocumentsDetailScreenState();
}

class _PatientDocumentsDetailScreenState extends State<_PatientDocumentsDetailScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _documentsEnviados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentsEnviados();
  }

  Future<void> _loadDocumentsEnviados() async {
    setState(() => _isLoading = true);
    try {
      final patientId = widget.patient.id;
      final response = await _apiService.get('/exams/admin/patients/$patientId?fileType=DOCUMENT');
      final data = response.data;
      if (data != null && data['items'] != null) {
        // Filtrar apenas os enviados pelo admin
        final allItems = List<Map<String, dynamic>>.from(data['items']);
        _documentsEnviados = allItems.where((e) =>
          e['createdByRole'] == 'CLINIC_ADMIN' || e['createdByRole'] == 'CLINIC_STAFF'
        ).toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar documentos: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showUploadModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UploadDocumentModal(
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        fileType: 'DOCUMENT',
      ),
    );
    if (result == true) {
      _loadDocumentsEnviados();
    }
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
            _buildUploadButton(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA49E86)))
                  : _documentsEnviados.isEmpty
                      ? _buildEmptyState()
                      : _buildDocumentsList(),
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
            'Enviar Documentos',
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
                widget.patient.name.isNotEmpty ? widget.patient.name.substring(0, 1).toUpperCase() : '?',
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
                      ? 'D+${widget.patient.dayPostOp} pos-operatorio'
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

  Widget _buildUploadButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showUploadModal,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF4F4A34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Enviar Documento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.folder_outlined, color: Color(0xFF697282), size: 48),
          SizedBox(height: 16),
          Text(
            'Nenhum documento enviado',
            style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
          ),
          SizedBox(height: 8),
          Text(
            'Toque em "Enviar Documento" para adicionar',
            style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _documentsEnviados.length,
      itemBuilder: (context, index) {
        final doc = _documentsEnviados[index];
        return _DocumentCard(document: doc, onDelete: () => _deleteDocument(doc['id']));
      },
    );
  }

  Future<void> _deleteDocument(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir documento?'),
        content: const Text('Esta acao nao pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE7000B)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('/exams/$docId');
        _loadDocumentsEnviados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento excluido com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir documento')),
          );
        }
      }
    }
  }
}

// ========== TELA DE DOCUMENTOS RECEBIDOS DO PACIENTE ==========
class _PatientReceivedDocumentsScreen extends StatefulWidget {
  final PatientListItem patient;
  const _PatientReceivedDocumentsScreen({required this.patient});

  @override
  State<_PatientReceivedDocumentsScreen> createState() => _PatientReceivedDocumentsScreenState();
}

class _PatientReceivedDocumentsScreenState extends State<_PatientReceivedDocumentsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _documentsRecebidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentsRecebidos();
  }

  Future<void> _loadDocumentsRecebidos() async {
    setState(() => _isLoading = true);
    try {
      final patientId = widget.patient.id;
      final response = await _apiService.get('/exams/admin/patients/$patientId?fileType=DOCUMENT');
      final data = response.data;
      if (data != null && data['items'] != null) {
        // Filtrar apenas os enviados pelo paciente
        final allItems = List<Map<String, dynamic>>.from(data['items']);
        _documentsRecebidos = allItems.where((e) => e['createdByRole'] == 'PATIENT').toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar documentos: $e');
    }
    if (mounted) setState(() => _isLoading = false);
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA49E86)))
                  : _documentsRecebidos.isEmpty
                      ? _buildEmptyState()
                      : _buildDocumentsList(),
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
            'Documentos Recebidos',
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
                widget.patient.name.isNotEmpty ? widget.patient.name.substring(0, 1).toUpperCase() : '?',
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
                      ? 'D+${widget.patient.dayPostOp} pos-operatorio'
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox_outlined, color: Color(0xFF697282), size: 48),
          SizedBox(height: 16),
          Text(
            'Nenhum documento recebido',
            style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
          ),
          SizedBox(height: 8),
          Text(
            'O paciente ainda nao enviou documentos',
            style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documentsRecebidos.length,
      itemBuilder: (context, index) {
        final doc = _documentsRecebidos[index];
        final status = doc['status'] ?? '';
        return _DocumentCard(
          document: doc,
          showAiAnalysis: false,
          onDelete: () => _deleteDocument(doc['id']),
          onApprove: status != 'AVAILABLE' ? () => _showApprovalModal(doc) : null,
          onAdjust: status == 'AVAILABLE' ? () => _showApprovalModal(doc) : null,
        );
      },
    );
  }

  Future<void> _showApprovalModal(Map<String, dynamic> doc) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DocumentApprovalModal(
        document: doc,
        patientName: widget.patient.name,
      ),
    );
    if (result == true) {
      _loadDocumentsRecebidos();
    }
  }

  Future<void> _deleteDocument(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir documento?'),
        content: const Text('Esta acao nao pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE7000B)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('/exams/$docId');
        _loadDocumentsRecebidos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento excluido com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir documento')),
          );
        }
      }
    }
  }
}

// ========== CARD DE DOCUMENTO ==========
class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onAdjust;
  // ignore: unused_field - mantido para compatibilidade
  final bool showAiAnalysis;

  const _DocumentCard({
    required this.document,
    required this.onDelete,
    this.showAiAnalysis = false,
    this.onApprove,
    this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final title = document['title'] ?? 'Sem titulo';
    final fileName = document['fileName'] ?? '';
    final date = document['date'] != null ? _formatDate(document['date']) : '';
    final fileUrl = document['fileUrl'] ?? '';
    final status = document['status'] ?? '';
    final approvedAt = document['approvedAt'];
    final isApproved = status == 'AVAILABLE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Color(0xFF4F4A34), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF212621),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (fileName.isNotEmpty)
                      Text(
                        fileName,
                        style: const TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
          // Status "Enviado" para documentos aprovados
          if (isApproved) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00A63E).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00A63E).withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00A63E),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enviado ao paciente',
                          style: TextStyle(
                            color: Color(0xFF00A63E),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (approvedAt != null)
                          Text(
                            'em ${_formatDate(approvedAt)}',
                            style: const TextStyle(
                              color: Color(0xFF697282),
                              fontSize: 11,
                              fontFamily: 'Inter',
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onAdjust != null)
                    GestureDetector(
                      onTap: onAdjust,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD08700).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD08700)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Color(0xFFD08700), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Ajustar',
                              style: TextStyle(
                                color: Color(0xFFD08700),
                                fontSize: 11,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (fileUrl.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _showFileViewer(context, fileUrl, title, fileName);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F4A34).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, color: Color(0xFF4F4A34), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Ver',
                          style: TextStyle(
                            color: Color(0xFF4F4A34),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Botão Aprovar para documentos pendentes
              if (!isApproved && onApprove != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onApprove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A63E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Aprovar',
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
              ],
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
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  void _showFileViewer(BuildContext context, String fileUrl, String title, String fileName) {
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final fixedUrl = _fixImageUrl(fileUrl);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF4F4A34),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.image,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (fileName.isNotEmpty)
                            Text(
                              fileName,
                              style: TextStyle(
                                color: Colors.white.withAlpha(179),
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: isPdf
                    ? _buildPdfViewer(fixedUrl)
                    : _buildImageViewer(fixedUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageViewer(String fileUrl) {
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Image.network(
          fileUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFFA49E86),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Carregando imagem...',
                    style: TextStyle(
                      color: Color(0xFF697282),
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: Color(0xFF697282),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Erro ao carregar imagem',
                    style: TextStyle(
                      color: Color(0xFF697282),
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fileUrl,
                    style: const TextStyle(
                      color: Color(0xFF697282),
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPdfViewer(String fileUrl) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            color: Color(0xFFE7000B),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Visualizacao de PDF',
            style: TextStyle(
              color: Color(0xFF4F4A34),
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O arquivo PDF esta disponivel para download',
            style: TextStyle(
              color: Color(0xFF697282),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            fileUrl,
            style: const TextStyle(
              color: Color(0xFF697282),
              fontSize: 10,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ========== MODAL DE UPLOAD ==========
class _UploadDocumentModal extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String fileType;

  const _UploadDocumentModal({
    required this.patientId,
    required this.patientName,
    required this.fileType,
  });

  @override
  State<_UploadDocumentModal> createState() => _UploadDocumentModalState();
}

class _UploadDocumentModalState extends State<_UploadDocumentModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ApiService _apiService = ApiService();
  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _fileName = picked.name;
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o titulo do documento')),
      );
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um arquivo')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _apiService.uploadFile(
        '/exams/admin/upload',
        _selectedFile!,
        fields: {
          'patientId': widget.patientId,
          'title': _titleController.text.trim(),
          'fileType': widget.fileType,
          'notes': _notesController.text.trim(),
          'date': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento enviado com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Erro ao enviar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    }

    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enviar Documento',
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
            const SizedBox(height: 8),
            Text(
              'Para: ${widget.patientName}',
              style: const TextStyle(
                color: Color(0xFF697282),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Titulo do Documento',
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
                hintText: 'Ex: Atestado Medico',
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
              'Observacoes (opcional)',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Detalhes sobre o documento...',
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
              'Arquivo',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedFile != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00A63E)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF00A63E), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fileName ?? 'Arquivo selecionado',
                        style: const TextStyle(
                          color: Color(0xFF212621),
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedFile = null;
                        _fileName = null;
                      }),
                      child: const Icon(Icons.close, color: Color(0xFF697282), size: 20),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.camera),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt, color: Color(0xFF4F4A34), size: 24),
                            SizedBox(height: 4),
                            Text(
                              'Camera',
                              style: TextStyle(
                                color: Color(0xFF4F4A34),
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.photo_library, color: Color(0xFF4F4A34), size: 24),
                            SizedBox(height: 4),
                            Text(
                              'Galeria',
                              style: TextStyle(
                                color: Color(0xFF4F4A34),
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickPdf,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Color(0xFF4F4A34), size: 24),
                            SizedBox(height: 4),
                            Text(
                              'PDF',
                              style: TextStyle(
                                color: Color(0xFF4F4A34),
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isUploading ? null : _upload,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: _isUploading ? const Color(0xFF697282) : const Color(0xFF4F4A34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Enviar',
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

// ========== MODAL DE APROVAÇÃO DE DOCUMENTO ==========
class _DocumentApprovalModal extends StatefulWidget {
  final Map<String, dynamic> document;
  final String patientName;

  const _DocumentApprovalModal({
    required this.document,
    required this.patientName,
  });

  @override
  State<_DocumentApprovalModal> createState() => _DocumentApprovalModalState();
}

class _DocumentApprovalModalState extends State<_DocumentApprovalModal> {
  final ApiService _apiService = ApiService();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pré-preencher com observações existentes
    _notesController.text = widget.document['aiSummary'] ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _approveDocument() async {
    setState(() => _isSubmitting = true);

    try {
      final docId = widget.document['id'];
      await _apiService.put('/exams/admin/$docId/approve', data: {
        'status': 'normal',
        'analysis': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : 'Documento aprovado pela equipe médica.',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento aprovado e enviado ao paciente!'),
            backgroundColor: Color(0xFF00A63E),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Erro ao aprovar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao aprovar: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.document['title'] ?? 'Documento';
    final fileUrl = widget.document['fileUrl'] ?? '';
    final fileName = widget.document['fileName'] ?? '';
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final fixedFileUrl = _fixImageUrl(fileUrl);
    final status = widget.document['status'] ?? '';
    final isApproved = status == 'AVAILABLE';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
                  isApproved ? 'Ajustar Documento' : 'Revisar Documento',
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF697282)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.patientName} • $title',
              style: const TextStyle(
                color: Color(0xFF697282),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 16),

            // Preview da imagem/arquivo
            if (fixedFileUrl.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showFullScreenViewer(context, fixedFileUrl, title, fileName, isPdf),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8C2B4)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      children: [
                        isPdf
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf,
                                      color: Color(0xFFE7000B),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      fileName.isNotEmpty ? fileName : 'Documento PDF',
                                      style: const TextStyle(
                                        color: Color(0xFF697282),
                                        fontSize: 12,
                                        fontFamily: 'Inter',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              )
                            : Image.network(
                                fixedFileUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: const Color(0xFFA49E86),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Color(0xFF697282), size: 48),
                                        SizedBox(height: 8),
                                        Text(
                                          'Erro ao carregar imagem',
                                          style: TextStyle(color: Color(0xFF697282), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        // Overlay "Toque para ampliar"
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Toque para ampliar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Campo de observações
            const Text(
              'Observações para o paciente',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Adicione observações sobre o documento...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F3EF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                // Botão Cancelar
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC8C2B4)),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFF697282),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botão Aprovar/Salvar
                Expanded(
                  child: GestureDetector(
                    onTap: _isSubmitting ? null : _approveDocument,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isSubmitting ? const Color(0xFF697282) : const Color(0xFF00A63E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isApproved ? Icons.save : Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isApproved ? 'Salvar' : 'Aprovar',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
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

  void _showFullScreenViewer(BuildContext context, String fileUrl, String title, String fileName, bool isPdf) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF4F4A34),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.image,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: isPdf
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Color(0xFFE7000B), size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'Documento PDF',
                              style: TextStyle(
                                color: Color(0xFF4F4A34),
                                fontSize: 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Image.network(
                            fileUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFFA49E86),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: Color(0xFF697282), size: 48),
                                    SizedBox(height: 16),
                                    Text(
                                      'Erro ao carregar imagem',
                                      style: TextStyle(color: Color(0xFF697282), fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
