import 'package:flutter/material.dart';

class ClinicDocumentsScreen extends StatefulWidget {
  const ClinicDocumentsScreen({super.key});

  @override
  State<ClinicDocumentsScreen> createState() => _ClinicDocumentsScreenState();
}

class _ClinicDocumentsScreenState extends State<ClinicDocumentsScreen> {
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
          const Row(
            children: [
              Icon(Icons.person_search_outlined, color: Color(0xFF212621), size: 20),
              SizedBox(width: 8),
              Text(
                'Selecione um Paciente',
                style: TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
              Icons.folder_outlined,
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
            'para visualizar e gerenciar\nos documentos importantes',
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

// ==================== PATIENT DOCUMENTS DETAIL SCREEN ====================

class _PatientDocumentsDetailScreen extends StatefulWidget {
  final _PatientItem patient;

  const _PatientDocumentsDetailScreen({required this.patient});

  @override
  State<_PatientDocumentsDetailScreen> createState() => _PatientDocumentsDetailScreenState();
}

class _PatientDocumentsDetailScreenState extends State<_PatientDocumentsDetailScreen> {
  // Mock data - será substituído por chamadas de API
  final List<_DocumentItem> _documents = [
    _DocumentItem(
      '1',
      'Termo de Consentimento',
      'Consentimentos',
      'PDF',
      '245 KB',
      '1 Dez 2024',
      const Color(0xFFFFE2E2),
      Icons.description_outlined,
    ),
    _DocumentItem(
      '2',
      'Exame Pré-operatório',
      'Exames',
      'PDF',
      '1.2 MB',
      '28 Nov 2024',
      const Color(0xFFE0F2FE),
      Icons.science_outlined,
    ),
    _DocumentItem(
      '3',
      'Receita Médica',
      'Prescrições',
      'PDF',
      '89 KB',
      '5 Dez 2024',
      const Color(0xFFD1FAE5),
      Icons.medication_outlined,
    ),
    _DocumentItem(
      '4',
      'Orientações Pós-operatório',
      'Orientações',
      'PDF',
      '156 KB',
      '5 Dez 2024',
      const Color(0xFFFEF3C7),
      Icons.info_outlined,
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
            _buildInfoBanner(),
            _buildAddButton(),
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

  Widget _buildPatientInfo() {
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
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: Colors.white.withAlpha(77),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.patient.name),
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
                  widget.patient.patientId,
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 20,
            height: 20,
            child: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBDDAFF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF193BB8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Color(0xFF193BB8),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  height: 1.33,
                ),
                children: [
                  TextSpan(
                    text: 'Documentos importantes ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'organizados por categoria.',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showUploadModal,
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
              Icon(Icons.upload_file_outlined, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Enviar Documento',
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
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.folder_outlined, color: Color(0xFF697282), size: 48),
            SizedBox(height: 16),
            Text(
              'Nenhum documento cadastrado',
              style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
            ),
            SizedBox(height: 8),
            Text(
              'Toque em "Enviar Documento"',
              style: TextStyle(color: Color(0xFF697282), fontSize: 14, fontFamily: 'Inter'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = _documents[index];
        return _DocumentCard(
          document: doc,
          onView: () => _viewDocument(doc),
          onDownload: () => _downloadDocument(doc),
          onDelete: () => _deleteDocument(doc.id),
        );
      },
    );
  }

  void _viewDocument(_DocumentItem doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Visualizando: ${doc.title}')),
    );
    // TODO: Implementar visualização do documento
  }

  void _downloadDocument(_DocumentItem doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Baixando: ${doc.title}')),
    );
    // TODO: Implementar download do documento
  }

  void _deleteDocument(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir documento?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _documents.removeWhere((d) => d.id == id));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Documento excluído')),
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

  void _showUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UploadDocumentModal(
        onUpload: (title, category) {
          setState(() {
            _documents.add(_DocumentItem(
              DateTime.now().millisecondsSinceEpoch.toString(),
              title,
              category,
              'PDF',
              '0 KB',
              _formatDate(DateTime.now()),
              _getCategoryColor(category),
              _getCategoryIcon(category),
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento enviado')),
          );
          // TODO: Chamar API upload
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Consentimentos':
        return const Color(0xFFFFE2E2);
      case 'Exames':
        return const Color(0xFFE0F2FE);
      case 'Prescrições':
        return const Color(0xFFD1FAE5);
      case 'Orientações':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF5F3EF);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Consentimentos':
        return Icons.description_outlined;
      case 'Exames':
        return Icons.science_outlined;
      case 'Prescrições':
        return Icons.medication_outlined;
      case 'Orientações':
        return Icons.info_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}

// ==================== DOCUMENT MODEL ====================

class _DocumentItem {
  final String id;
  final String title;
  final String category;
  final String type;
  final String size;
  final String date;
  final Color iconBgColor;
  final IconData icon;

  _DocumentItem(
    this.id,
    this.title,
    this.category,
    this.type,
    this.size,
    this.date,
    this.iconBgColor,
    this.icon,
  );
}

// ==================== DOCUMENT CARD ====================

class _DocumentCard extends StatelessWidget {
  final _DocumentItem document;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.onView,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Column(
        children: [
          // Document info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: document.iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  document.icon,
                  color: const Color(0xFF697282),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        color: Color(0xFF212621),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: const Color(0xFFBDDAFF)),
                          ),
                          child: Text(
                            document.category,
                            style: const TextStyle(
                              color: Color(0xFF1347E5),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          document.type,
                          style: const TextStyle(
                            color: Color(0xFF697282),
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: Color(0xFF697282), fontSize: 12),
                        ),
                        Text(
                          document.size,
                          style: const TextStyle(
                            color: Color(0xFF697282),
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Color(0xFF697282),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document.date,
                          style: const TextStyle(
                            color: Color(0xFF697282),
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onView,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7D1C5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8DC5FF)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF155CFB)),
                        SizedBox(width: 4),
                        Text(
                          'Visualizar',
                          style: TextStyle(
                            color: Color(0xFF155CFB),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
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
                  onTap: onDownload,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7D1C5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF7BF1A8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_outlined, size: 16, color: Color(0xFF00A63E)),
                        SizedBox(width: 4),
                        Text(
                          'Baixar',
                          style: TextStyle(
                            color: Color(0xFF00A63E),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 38,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7D1C5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8C2B4)),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Color(0xFFE7000B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== UPLOAD MODAL ====================

class _UploadDocumentModal extends StatefulWidget {
  final void Function(String title, String category) onUpload;

  const _UploadDocumentModal({required this.onUpload});

  @override
  State<_UploadDocumentModal> createState() => _UploadDocumentModalState();
}

class _UploadDocumentModalState extends State<_UploadDocumentModal> {
  final _titleController = TextEditingController();
  String _selectedCategory = 'Consentimentos';

  final List<String> _categories = [
    'Consentimentos',
    'Exames',
    'Prescrições',
    'Orientações',
    'Outros',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _handleUpload() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do documento')),
      );
      return;
    }

    widget.onUpload(title, _selectedCategory);
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
            const SizedBox(height: 24),

            // Nome do documento
            const Text(
              'Nome do Documento',
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
                hintText: 'Ex: Termo de Consentimento',
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

            // Categoria
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF697282)),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      style: const TextStyle(
                        color: Color(0xFF212621),
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Área de upload
            GestureDetector(
              onTap: () {
                // TODO: Implementar seleção de arquivo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selecionar arquivo...')),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD0D5DB),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7D1C5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFF4F4A34),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Clique para selecionar arquivo',
                      style: TextStyle(
                        color: Color(0xFF4F4A34),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PDF, DOC, JPG, PNG (máx. 10MB)',
                      style: TextStyle(
                        color: Color(0xFF697282),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botão Enviar
            GestureDetector(
              onTap: _handleUpload,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F4A34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
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
