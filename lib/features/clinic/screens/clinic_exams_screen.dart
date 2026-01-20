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

class ClinicExamsScreen extends StatefulWidget {
  const ClinicExamsScreen({super.key});

  @override
  State<ClinicExamsScreen> createState() => _ClinicExamsScreenState();
}

class _ClinicExamsScreenState extends State<ClinicExamsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  String _searchQuery = '';
  late TabController _tabController;

  // Indica se há exames pendentes de revisão (enviados por pacientes)
  bool _hasUnreadRecebidos = false;

  // Lista de IDs de pacientes que têm exames pendentes de revisão
  Set<String> _patientsWithNewExams = {};

  @override
  void initState() {
    super.initState();
    debugPrint('========================================');
    debugPrint('🔴 TELA DE EXAMES ADMIN CARREGADA');
    debugPrint('🔴 Arquivo: clinic_exams_screen.dart');
    debugPrint('🔴 TabController com 2 tabs: Enviar, Recebidos');
    debugPrint('========================================');
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientsProvider>().loadPatients(refresh: true);
      _loadPendingReviewExams();
    });
  }

  Future<void> _loadPendingReviewExams() async {
    try {
      final response = await _apiService.get('/exams/admin/pending?fileType=EXAM');
      final data = response.data;
      if (data != null && data['items'] != null) {
        final items = List<Map<String, dynamic>>.from(data['items']);
        final patientIds = items.map((e) => e['patientId']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
        if (mounted) {
          setState(() {
            _patientsWithNewExams = patientIds;
            _hasUnreadRecebidos = patientIds.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar exames pendentes: $e');
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

  void _navigateToPatientExams(PatientListItem patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PatientExamsDetailScreen(patient: patient),
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
            'Exames',
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
          _buildPatientSelector(onSelectPatient: _navigateToPatientExams),
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
                              hasNewContent: _patientsWithNewExams.contains(filteredPatients[i].id),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _PatientReceivedExamsScreen(patient: filteredPatients[i]),
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
            'Enviar Exame',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecione um paciente para\nenviar exames ou documentos',
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
            'Exames Recebidos',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecione um paciente para\nvisualizar os exames enviados',
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

// ========== TELA DE ENVIAR EXAMES PARA PACIENTE ==========
class _PatientExamsDetailScreen extends StatefulWidget {
  final PatientListItem patient;
  const _PatientExamsDetailScreen({required this.patient});

  @override
  State<_PatientExamsDetailScreen> createState() => _PatientExamsDetailScreenState();
}

class _PatientExamsDetailScreenState extends State<_PatientExamsDetailScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _examsEnviados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamsEnviados();
  }

  Future<void> _loadExamsEnviados() async {
    setState(() => _isLoading = true);
    try {
      final patientId = widget.patient.id;
      final response = await _apiService.get('/exams/admin/patients/$patientId?fileType=EXAM');
      final data = response.data;
      if (data != null && data['items'] != null) {
        // Filtrar apenas os enviados pelo admin
        final allItems = List<Map<String, dynamic>>.from(data['items']);
        _examsEnviados = allItems.where((e) =>
          e['createdByRole'] == 'CLINIC_ADMIN' || e['createdByRole'] == 'CLINIC_STAFF'
        ).toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar exames: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showUploadModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UploadExamModal(
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        fileType: 'EXAM',
      ),
    );
    if (result == true) {
      _loadExamsEnviados();
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
                  : _examsEnviados.isEmpty
                      ? _buildEmptyState()
                      : _buildExamsList(),
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
            'Enviar Exames',
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
                'Enviar Exame',
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
          Icon(Icons.science_outlined, color: Color(0xFF697282), size: 48),
          SizedBox(height: 16),
          Text(
            'Nenhum exame enviado',
            style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
          ),
          SizedBox(height: 8),
          Text(
            'Toque em "Enviar Exame" para adicionar',
            style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _examsEnviados.length,
      itemBuilder: (context, index) {
        final exam = _examsEnviados[index];
        return _ExamCard(exam: exam, onDelete: () => _deleteExam(exam['id']));
      },
    );
  }

  Future<void> _deleteExam(String examId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir exame?'),
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
        await _apiService.delete('/exams/$examId');
        _loadExamsEnviados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exame excluido com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir exame')),
          );
        }
      }
    }
  }
}

// ========== TELA DE EXAMES RECEBIDOS DO PACIENTE ==========
class _PatientReceivedExamsScreen extends StatefulWidget {
  final PatientListItem patient;
  const _PatientReceivedExamsScreen({required this.patient});

  @override
  State<_PatientReceivedExamsScreen> createState() => _PatientReceivedExamsScreenState();
}

class _PatientReceivedExamsScreenState extends State<_PatientReceivedExamsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _examsRecebidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamsRecebidos();
  }

  Future<void> _loadExamsRecebidos() async {
    setState(() => _isLoading = true);
    try {
      final patientId = widget.patient.id;
      final response = await _apiService.get('/exams/admin/patients/$patientId?fileType=EXAM');
      final data = response.data;
      if (data != null && data['items'] != null) {
        // Filtrar apenas os enviados pelo paciente
        final allItems = List<Map<String, dynamic>>.from(data['items']);
        _examsRecebidos = allItems.where((e) => e['createdByRole'] == 'PATIENT').toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar exames: $e');
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
                  : _examsRecebidos.isEmpty
                      ? _buildEmptyState()
                      : _buildExamsList(),
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
            'Exames Recebidos',
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
            'Nenhum exame recebido',
            style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
          ),
          SizedBox(height: 8),
          Text(
            'O paciente ainda nao enviou exames',
            style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _examsRecebidos.length,
      itemBuilder: (context, index) {
        final exam = _examsRecebidos[index];
        final status = exam['status'] ?? '';
        return _ExamCard(
          exam: exam,
          showAiAnalysis: true,
          onDelete: () => _deleteExam(exam['id']),
          onReview: () => _showReviewModal(exam),
          onAdjust: status == 'AVAILABLE' ? () => _showReviewModal(exam) : null,
        );
      },
    );
  }

  Future<void> _showReviewModal(Map<String, dynamic> exam) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewExamModal(
        exam: exam,
        patientName: widget.patient.name,
      ),
    );
    if (result == true) {
      _loadExamsRecebidos();
    }
  }

  Future<void> _deleteExam(String examId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir exame?'),
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
        await _apiService.delete('/exams/$examId');
        _loadExamsRecebidos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exame excluido com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir exame')),
          );
        }
      }
    }
  }
}

// ========== CARD DE EXAME ==========
class _ExamCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final VoidCallback onDelete;
  final bool showAiAnalysis;
  final VoidCallback? onReview;
  final VoidCallback? onAdjust;

  const _ExamCard({
    required this.exam,
    required this.onDelete,
    this.showAiAnalysis = false,
    this.onReview,
    this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final title = exam['title'] ?? 'Sem titulo';
    final fileName = exam['fileName'] ?? '';
    final date = exam['date'] != null ? _formatDate(exam['date']) : '';
    final aiStatus = exam['aiStatus'] ?? 'PENDING';
    final aiSummary = exam['aiSummary'] ?? '';
    final fileUrl = exam['fileUrl'] ?? '';
    final status = exam['status'] ?? '';
    final approvedAt = exam['approvedAt'];
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
                child: const Icon(Icons.description, color: Color(0xFF4F4A34), size: 20),
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
          // Status de "Enviado" para exames aprovados
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
          if (showAiAnalysis && aiSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getAiStatusColor(aiStatus).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getAiStatusColor(aiStatus).withAlpha(51)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getAiStatusIcon(aiStatus),
                        color: _getAiStatusColor(aiStatus),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Análise: ${_getAiStatusText(aiStatus)}',
                        style: TextStyle(
                          color: _getAiStatusColor(aiStatus),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (aiSummary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      aiSummary,
                      style: const TextStyle(
                        color: Color(0xFF4F4A34),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Botao de revisar (apenas para exames PENDING_REVIEW)
              if (onReview != null && exam['status'] == 'PENDING_REVIEW')
                GestureDetector(
                  onTap: onReview,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF155DFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rate_review, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Revisar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (onReview != null && exam['status'] == 'PENDING_REVIEW')
                const SizedBox(width: 8),
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
                          'Ver exame',
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
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Color _getAiStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF00A63E);
      case 'PROCESSING':
      case 'PENDING':
        return const Color(0xFFD08700);
      case 'FAILED':
        return const Color(0xFFE7000B);
      default:
        return const Color(0xFF697282);
    }
  }

  IconData _getAiStatusIcon(String status) {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'PROCESSING':
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'FAILED':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getAiStatusText(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'Concluida';
      case 'PROCESSING':
        return 'Processando';
      case 'PENDING':
        return 'Pendente';
      case 'FAILED':
        return 'Falhou';
      case 'SKIPPED':
        return 'Nao aplicavel';
      default:
        return status;
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
class _UploadExamModal extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String fileType;

  const _UploadExamModal({
    required this.patientId,
    required this.patientName,
    required this.fileType,
  });

  @override
  State<_UploadExamModal> createState() => _UploadExamModalState();
}

class _UploadExamModalState extends State<_UploadExamModal> {
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
        const SnackBar(content: Text('Informe o titulo do exame')),
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
          const SnackBar(content: Text('Exame enviado com sucesso!')),
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
                  'Enviar Exame',
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
              'Titulo do Exame',
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
                hintText: 'Ex: Hemograma Completo',
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
                hintText: 'Detalhes sobre o exame...',
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

// ========== MODAL DE REVISAO MEDICA ==========
class _ReviewExamModal extends StatefulWidget {
  final Map<String, dynamic> exam;
  final String patientName;

  const _ReviewExamModal({
    required this.exam,
    required this.patientName,
  });

  @override
  State<_ReviewExamModal> createState() => _ReviewExamModalState();
}

class _ReviewExamModalState extends State<_ReviewExamModal> {
  final ApiService _apiService = ApiService();
  final TextEditingController _analysisController = TextEditingController();
  String _selectedStatus = 'normal';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-preencher com sugestao da IA
    final aiJson = widget.exam['aiJson'];
    if (aiJson != null && aiJson is Map) {
      _selectedStatus = aiJson['suggested_status'] ?? 'normal';
      _analysisController.text = aiJson['patient_summary'] ?? widget.exam['aiSummary'] ?? '';
    } else {
      _analysisController.text = widget.exam['aiSummary'] ?? '';
    }
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  Future<void> _approveExam() async {
    if (_analysisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a analise para o paciente')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final examId = widget.exam['id'];
      await _apiService.put('/exams/admin/$examId/approve', data: {
        'status': _selectedStatus,
        'analysis': _analysisController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exame aprovado e enviado ao paciente!'),
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
                    ? Container(
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
                            Text(
                              fileName.isNotEmpty ? fileName : 'Documento PDF',
                              style: const TextStyle(
                                color: Color(0xFF697282),
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final title = widget.exam['title'] ?? 'Exame';
    final aiJson = widget.exam['aiJson'];
    final technicalNotes = aiJson is Map ? aiJson['technical_notes'] : null;
    final confidence = aiJson is Map ? (aiJson['confidence'] ?? 0.0) : 0.0;
    final fileUrl = widget.exam['fileUrl'] ?? '';
    final fileName = widget.exam['fileName'] ?? '';
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final fixedFileUrl = _fixImageUrl(fileUrl);

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
                const Text(
                  'Revisar Exame',
                  style: TextStyle(
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

            // Botão para ver exame
            if (fixedFileUrl.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showFullScreenViewer(context, fixedFileUrl, title, fileName, isPdf),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F4A34).withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8C2B4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.visibility,
                        color: const Color(0xFF4F4A34),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ver exame',
                        style: TextStyle(
                          color: Color(0xFF4F4A34),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notas tecnicas da IA (apenas medico ve)
            if (technicalNotes != null && technicalNotes.toString().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        const Text(
                          'Notas tecnicas (apenas voce ve)',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (confidence > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(confidence),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(confidence * 100).toInt()}% conf.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      technicalNotes.toString(),
                      style: const TextStyle(
                        color: Color(0xFF78350F),
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Seletor de Status
            const Text(
              'Status do exame',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip('normal', 'Normal', const Color(0xFF00A63E)),
                _buildStatusChip('mild_alteration', 'Alteracao leve', const Color(0xFFD08700)),
                _buildStatusChip('needs_review', 'Precisa revisao', const Color(0xFFFF6B00)),
                _buildStatusChip('critical', 'Critico', const Color(0xFFE7000B)),
              ],
            ),
            const SizedBox(height: 20),

            // Texto para o paciente
            const Text(
              'Analise para o paciente',
              style: TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _analysisController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Texto que o paciente vai visualizar...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Botao de aprovar
            GestureDetector(
              onTap: _isSubmitting ? null : _approveExam,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: _isSubmitting ? const Color(0xFF697282) : const Color(0xFF00C950),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Aprovar e Enviar ao Paciente',
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
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, Color color) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: isSelected ? 0 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFF00A63E);
    if (confidence >= 0.6) return const Color(0xFFD08700);
    return const Color(0xFFE7000B);
  }
}
