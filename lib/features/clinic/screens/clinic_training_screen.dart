import 'package:flutter/material.dart';
import '../../../core/services/training_service.dart';

class ClinicTrainingScreen extends StatefulWidget {
  const ClinicTrainingScreen({super.key});

  @override
  State<ClinicTrainingScreen> createState() => _ClinicTrainingScreenState();
}

class _ClinicTrainingScreenState extends State<ClinicTrainingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TrainingService _trainingService = TrainingService();
  List<TrainingProtocol> _protocols = [];
  List<PatientTrainingStatus> _patients = [];
  bool _isLoadingProtocols = true;
  bool _isLoadingPatients = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadData();
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

  Future<void> _loadData() async {
    await Future.wait([
      _loadProtocols(),
      _loadPatients(),
    ]);
  }

  Future<void> _loadProtocols() async {
    setState(() => _isLoadingProtocols = true);
    try {
      final protocols = await _trainingService.getProtocols();
      if (mounted) {
        setState(() {
          _protocols = protocols;
          _isLoadingProtocols = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar protocolos: $e');
      if (mounted) {
        setState(() => _isLoadingProtocols = false);
      }
    }
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoadingPatients = true);
    try {
      final patients = await _trainingService.getPatientsTrainingStatus();
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar pacientes: $e');
      if (mounted) {
        setState(() => _isLoadingPatients = false);
      }
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
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProtocolosTab(),
                  _buildPacientesTab(),
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
            'Treinos',
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
        tabs: const [
          Tab(text: 'Protocolo'),
          Tab(text: 'Pacientes'),
        ],
      ),
    );
  }

  // ==================== TAB PROTOCOLO ====================

  Widget _buildProtocolosTab() {
    if (_isLoadingProtocols) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA49E86)),
      );
    }

    if (_protocols.isEmpty) {
      return _buildEmptyProtocols();
    }

    // Usar o primeiro protocolo (geralmente só há um)
    final protocol = _protocols.first;

    return RefreshIndicator(
      onRefresh: _loadProtocols,
      color: const Color(0xFF4F4A34),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card do Protocolo
          _buildProtocolCard(protocol),
          const SizedBox(height: 16),
          // Lista de Semanas
          ...protocol.weeks.map((week) => _buildWeekCard(week, protocol.id)),
        ],
      ),
    );
  }

  Widget _buildEmptyProtocols() {
    return Center(
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
            child: const Icon(Icons.fitness_center_outlined, color: Color(0xFF697282), size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum protocolo encontrado',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O protocolo de treino será\ncarregado automaticamente',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF697282),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard(TrainingProtocol protocol) {
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
                Text(
                  protocol.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${protocol.totalWeeks} semanas de reabilitação',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          if (protocol.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00A63E).withAlpha(77),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Padrão',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(TrainingWeek week, String protocolId) {
    return GestureDetector(
      onTap: () => _navigateToWeekDetail(week),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8C2B4)),
        ),
        child: Row(
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
                  Text(
                    week.title,
                    style: const TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (week.heartRateLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7000B).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: Color(0xFFE7000B), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          week.heartRateLabel!,
                          style: const TextStyle(
                            color: Color(0xFFE7000B),
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${week.sessionsCount > 0 ? week.sessionsCount : week.sessions.length} exercícios',
                  style: const TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF697282), size: 20),
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

  void _navigateToWeekDetail(TrainingWeek week) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _WeekDetailScreen(
          week: week,
          onRefresh: _loadProtocols,
        ),
      ),
    );
  }

  // ==================== TAB PACIENTES ====================

  Widget _buildPacientesTab() {
    if (_isLoadingPatients) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA49E86)),
      );
    }

    final filteredPatients = _searchQuery.isEmpty
        ? _patients
        : _patients
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery) ||
                (p.email?.toLowerCase().contains(_searchQuery) ?? false))
            .toList();

    return RefreshIndicator(
      onRefresh: _loadPatients,
      color: const Color(0xFF4F4A34),
      child: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8C2B4)),
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
          ),
          // Lista de pacientes
          Expanded(
            child: filteredPatients.isEmpty
                ? _buildEmptyPatients()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      return _buildPatientCard(filteredPatients[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPatients() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people_outline, color: Color(0xFF697282), size: 48),
          SizedBox(height: 16),
          Text(
            'Nenhum paciente encontrado',
            style: TextStyle(color: Color(0xFF697282), fontSize: 16, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientTrainingStatus patient) {
    final progressPercent = patient.totalWeeks > 0
        ? (patient.completedWeeks / patient.totalWeeks * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => _navigateToPatientTraining(patient),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8C2B4)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4F4A34),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  patient.name.isNotEmpty ? patient.name.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                      fontSize: 15,
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
                          color: const Color(0xFF4F4A34).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Semana ${patient.currentWeek}',
                          style: const TextStyle(
                            color: Color(0xFF4F4A34),
                            fontSize: 11,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'D+${patient.daysSinceSurgery}',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$progressPercent%',
                  style: TextStyle(
                    color: progressPercent >= 75
                        ? const Color(0xFF00A63E)
                        : progressPercent >= 50
                            ? const Color(0xFFD08700)
                            : const Color(0xFF697282),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: patient.totalWeeks > 0 ? patient.completedWeeks / patient.totalWeeks : 0,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercent >= 75
                          ? const Color(0xFF00A63E)
                          : progressPercent >= 50
                              ? const Color(0xFFD08700)
                              : const Color(0xFFA49E86),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF697282), size: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToPatientTraining(PatientTrainingStatus patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PatientTrainingDetailScreen(patient: patient),
      ),
    );
  }
}

// ==================== TELA DE DETALHES DA SEMANA ====================

class _WeekDetailScreen extends StatefulWidget {
  final TrainingWeek week;
  final VoidCallback onRefresh;

  const _WeekDetailScreen({required this.week, required this.onRefresh});

  @override
  State<_WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<_WeekDetailScreen> {
  final TrainingService _trainingService = TrainingService();
  late TrainingWeek _week;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _week = widget.week;
    _loadWeekDetails();
  }

  Future<void> _loadWeekDetails() async {
    setState(() => _isLoading = true);
    try {
      final week = await _trainingService.getWeekDetails(_week.id);
      if (mounted) {
        setState(() {
          _week = week;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar semana: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA49E86)))
                  : RefreshIndicator(
                      onRefresh: _loadWeekDetails,
                      color: const Color(0xFF4F4A34),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildWeekInfoCard(),
                          const SizedBox(height: 16),
                          _buildCanDoSection(),
                          const SizedBox(height: 16),
                          _buildAvoidSection(),
                          const SizedBox(height: 16),
                          _buildSessionsSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSessionModal,
        backgroundColor: const Color(0xFF4F4A34),
        child: const Icon(Icons.add, color: Colors.white),
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
            onTap: () {
              widget.onRefresh();
              Navigator.pop(context);
            },
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
          Expanded(
            child: Text(
              _week.title,
              style: const TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 24,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekInfoCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _week.dayRange,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_week.heartRateLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7000B).withAlpha(77),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _week.heartRateLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Objetivo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _week.objective,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanDoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A63E).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF00A63E), size: 20),
              SizedBox(width: 8),
              Text(
                'Pode Fazer',
                style: TextStyle(
                  color: Color(0xFF00A63E),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _week.canDo.map((item) => _buildChip(item, const Color(0xFF00A63E))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvoidSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD08700).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber, color: Color(0xFFD08700), size: 20),
              SizedBox(width: 8),
              Text(
                'Evitar',
                style: TextStyle(
                  color: Color(0xFFD08700),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _week.avoid.map((item) => _buildChip(item, const Color(0xFFD08700))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSessionsSection() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.fitness_center, color: Color(0xFF4F4A34), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Exercícios',
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${_week.sessions.length} exercícios',
                style: const TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_week.sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum exercício cadastrado',
                  style: TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            )
          else
            ..._week.sessions.map((session) => _buildSessionCard(session)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TrainingSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4F4A34).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${session.sessionNumber}',
                style: const TextStyle(
                  color: Color(0xFF4F4A34),
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
                  session.name,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (session.description != null && session.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      session.description!,
                      style: const TextStyle(
                        color: Color(0xFF697282),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (session.duration != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${session.duration} min',
                style: const TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF697282), size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditSessionModal(session);
              } else if (value == 'delete') {
                _deleteSession(session);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Color(0xFF4F4A34)),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Color(0xFFE7000B)),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Color(0xFFE7000B))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddSessionModal() {
    _showSessionModal(null);
  }

  void _showEditSessionModal(TrainingSession session) {
    _showSessionModal(session);
  }

  void _showSessionModal(TrainingSession? session) {
    final isEditing = session != null;
    final nameController = TextEditingController(text: session?.name ?? '');
    final descriptionController = TextEditingController(text: session?.description ?? '');
    final durationController = TextEditingController(text: session?.duration?.toString() ?? '');
    String? intensity = session?.intensity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                    isEditing ? 'Editar Exercício' : 'Novo Exercício',
                    style: const TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Color(0xFF697282)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Nome do exercício',
                style: TextStyle(
                  color: Color(0xFF4F4A34),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Ex: Caminhada leve',
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
                controller: descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Instruções do exercício...',
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duração (min)',
                          style: TextStyle(
                            color: Color(0xFF4F4A34),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '15',
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Intensidade',
                          style: TextStyle(
                            color: Color(0xFF4F4A34),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setDropdownState) {
                            return DropdownButtonFormField<String>(
                              value: intensity,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF5F3EF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              hint: const Text('Selecione', style: TextStyle(color: Color(0xFF9CA3AF))),
                              items: const [
                                DropdownMenuItem(value: 'Muito leve', child: Text('Muito leve')),
                                DropdownMenuItem(value: 'Leve', child: Text('Leve')),
                                DropdownMenuItem(value: 'Leve-Moderada', child: Text('Leve-Moderada')),
                                DropdownMenuItem(value: 'Moderada', child: Text('Moderada')),
                                DropdownMenuItem(value: 'Moderada-Alta', child: Text('Moderada-Alta')),
                                DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                              ],
                              onChanged: (value) {
                                setDropdownState(() => intensity = value);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe o nome do exercício')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  try {
                    if (isEditing) {
                      await _trainingService.updateSession(
                        session.id,
                        name: name,
                        description: descriptionController.text.trim(),
                        duration: int.tryParse(durationController.text),
                        intensity: intensity,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exercício atualizado!')),
                      );
                    } else {
                      await _trainingService.createSession(
                        weekId: _week.id,
                        name: name,
                        description: descriptionController.text.trim(),
                        duration: int.tryParse(durationController.text),
                        intensity: intensity,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exercício adicionado!')),
                      );
                    }
                    _loadWeekDetails();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                },
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
      ),
    );
  }

  Future<void> _deleteSession(TrainingSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir exercício?'),
        content: Text('Deseja excluir "${session.name}"?\nEsta ação não pode ser desfeita.'),
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
        await _trainingService.deleteSession(session.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercício excluído!')),
        );
        _loadWeekDetails();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }
}

// ==================== TELA DE TREINO DO PACIENTE (ADMIN) ====================

class _PatientTrainingDetailScreen extends StatefulWidget {
  final PatientTrainingStatus patient;

  const _PatientTrainingDetailScreen({required this.patient});

  @override
  State<_PatientTrainingDetailScreen> createState() => _PatientTrainingDetailScreenState();
}

class _PatientTrainingDetailScreenState extends State<_PatientTrainingDetailScreen>
    with SingleTickerProviderStateMixin {
  final TrainingService _trainingService = TrainingService();
  PatientTrainingData? _patientData;
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedWeekIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadPatientTraining();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientTraining() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[DEBUG] Carregando treino do paciente: ${widget.patient.id}');
      final data = await _trainingService.getPatientTrainingData(widget.patient.id);
      debugPrint('[DEBUG] Dados recebidos:');
      debugPrint('[DEBUG] - currentWeek: ${data.currentWeek}');
      debugPrint('[DEBUG] - totalWeeks: ${data.totalWeeks}');
      debugPrint('[DEBUG] - weeks.length: ${data.weeks.length}');
      if (data.weeks.isNotEmpty) {
        debugPrint('[DEBUG] - Primeira semana: ${data.weeks.first.title}');
        debugPrint('[DEBUG] - Primeira semana canDo: ${data.weeks.first.canDo}');
        debugPrint('[DEBUG] - Primeira semana avoid: ${data.weeks.first.avoid}');
        debugPrint('[DEBUG] - Primeira semana sessions: ${data.weeks.first.sessions.length}');
      }
      if (mounted) {
        setState(() {
          _patientData = data;
          _isLoading = false;
          // Ir para a semana atual automaticamente
          _selectedWeekIndex = (data.currentWeek - 1).clamp(0, 7);
          _tabController.animateTo(_selectedWeekIndex);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] Erro ao carregar treino do paciente: $e');
      debugPrint('[ERROR] Stack: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            if (!_isLoading && _patientData != null) _buildWeekTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA49E86)))
                  : _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: !_isLoading && _patientData != null
          ? FloatingActionButton(
              onPressed: _showAddExerciseModal,
              backgroundColor: const Color(0xFF4F4A34),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
          Expanded(
            child: Text(
              'Treino de ${widget.patient.name.split(' ').first}',
              style: const TextStyle(
                color: Color(0xFF4F4A34),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    final data = _patientData;
    final surgeryDateStr = data?.surgeryDate != null
        ? '${data!.surgeryDate!.day.toString().padLeft(2, '0')}/${data.surgeryDate!.month.toString().padLeft(2, '0')}/${data.surgeryDate!.year}'
        : 'N/A';

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
      child: Column(
        children: [
          Row(
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
                      'Cirurgia: $surgeryDateStr',
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
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.calendar_today,
                label: 'D+${data?.daysSinceSurgery ?? widget.patient.daysSinceSurgery}',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.flag,
                label: 'Semana ${data?.currentWeek ?? widget.patient.currentWeek} de 8',
                highlight: true,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.trending_up,
                label: '${data?.progressPercent ?? 0}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF00A63E).withAlpha(77) : Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 8,
        itemBuilder: (context, index) {
          final weekNum = index + 1;
          final isSelected = _selectedWeekIndex == index;
          final isCurrent = _patientData?.currentWeek == weekNum;
          final isCompleted = _patientData != null &&
              _patientData!.weeks.isNotEmpty &&
              index < _patientData!.weeks.length &&
              _patientData!.weeks[index].status == 'COMPLETED';

          return GestureDetector(
            onTap: () {
              setState(() => _selectedWeekIndex = index);
              _tabController.animateTo(index);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4F4A34)
                    : isCompleted
                        ? const Color(0xFF00A63E).withAlpha(26)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isCurrent && !isSelected
                    ? Border.all(color: const Color(0xFF00A63E), width: 2)
                    : Border.all(color: const Color(0xFFC8C2B4)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCompleted && !isSelected) ...[
                      const Icon(Icons.check, color: Color(0xFF00A63E), size: 14),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      'Sem $weekNum',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isCompleted
                                ? const Color(0xFF00A63E)
                                : const Color(0xFF4F4A34),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: isCurrent || isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_patientData == null || _patientData!.weeks.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum dado de treino disponível',
          style: TextStyle(color: Color(0xFF697282)),
        ),
      );
    }

    if (_selectedWeekIndex >= _patientData!.weeks.length) {
      return const Center(
        child: Text(
          'Semana não disponível',
          style: TextStyle(color: Color(0xFF697282)),
        ),
      );
    }

    final week = _patientData!.weeks[_selectedWeekIndex];

    return RefreshIndicator(
      onRefresh: _loadPatientTraining,
      color: const Color(0xFF4F4A34),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWeekInfoCard(week),
          const SizedBox(height: 16),
          _buildCanDoSection(week),
          const SizedBox(height: 16),
          _buildAvoidSection(week),
          const SizedBox(height: 16),
          _buildSessionsSection(week),
          const SizedBox(height: 16),
          _buildAdjustmentsSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWeekInfoCard(PatientWeekData week) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  week.title,
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showAdjustWeekModal(week),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F4A34).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit, color: Color(0xFF4F4A34), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Ajustar',
                        style: TextStyle(
                          color: Color(0xFF4F4A34),
                          fontSize: 12,
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  week.dayRange,
                  style: const TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (week.heartRateLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7000B).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFE7000B), size: 12),
                      const SizedBox(width: 4),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: week.status == 'CURRENT'
                      ? const Color(0xFF00A63E).withAlpha(26)
                      : week.status == 'COMPLETED'
                          ? const Color(0xFF00A63E).withAlpha(51)
                          : const Color(0xFFF5F3EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  week.status == 'CURRENT'
                      ? 'ATUAL'
                      : week.status == 'COMPLETED'
                          ? 'Concluída'
                          : 'Futura',
                  style: TextStyle(
                    color: week.status == 'FUTURE'
                        ? const Color(0xFF697282)
                        : const Color(0xFF00A63E),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Objetivo',
            style: TextStyle(
              color: Color(0xFF697282),
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            week.objective,
            style: const TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanDoSection(PatientWeekData week) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A63E).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF00A63E), size: 20),
              SizedBox(width: 8),
              Text(
                'Pode Fazer',
                style: TextStyle(
                  color: Color(0xFF00A63E),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (week.canDo.isEmpty)
            const Text(
              'Nenhuma atividade definida',
              style: TextStyle(color: Color(0xFF697282), fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: week.canDo.map((item) => _buildChip(item, const Color(0xFF00A63E))).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAvoidSection(PatientWeekData week) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD08700).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber, color: Color(0xFFD08700), size: 20),
              SizedBox(width: 8),
              Text(
                'Evitar',
                style: TextStyle(
                  color: Color(0xFFD08700),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (week.avoid.isEmpty)
            const Text(
              'Nenhuma restrição definida',
              style: TextStyle(color: Color(0xFF697282), fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: week.avoid.map((item) => _buildChip(item, const Color(0xFFD08700))).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSessionsSection(PatientWeekData week) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.fitness_center, color: Color(0xFF4F4A34), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Exercícios',
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${week.completedSessions}/${week.totalSessions} concluídos',
                style: const TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: week.sessionProgress / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A63E)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          if (week.sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum exercício nesta semana',
                  style: TextStyle(color: Color(0xFF697282), fontSize: 14),
                ),
              ),
            )
          else
            ...week.sessions.map((session) => _buildPatientSessionCard(session, week)),
        ],
      ),
    );
  }

  Widget _buildPatientSessionCard(PatientSessionData session, PatientWeekData week) {
    // Verificar se há ajuste para esta sessão
    final adjustment = _patientData?.adjustments.firstWhere(
      (a) => a.baseContentId == session.id && a.isActive,
      orElse: () => PatientTrainingAdjustment(
        id: '',
        patientId: '',
        adjustmentType: '',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );
    final hasAdjustment = adjustment != null && adjustment.id.isNotEmpty;
    final isRemoved = hasAdjustment && adjustment.adjustmentType == 'REMOVE';
    final isModified = hasAdjustment && adjustment.adjustmentType == 'MODIFY';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRemoved
            ? const Color(0xFFE7000B).withAlpha(13)
            : session.completed
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(12),
        border: isRemoved
            ? Border.all(color: const Color(0xFFE7000B).withAlpha(51))
            : isModified
                ? Border.all(color: const Color(0xFFD08700).withAlpha(77))
                : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isRemoved
                  ? const Color(0xFFE7000B).withAlpha(26)
                  : session.completed
                      ? const Color(0xFF00A63E).withAlpha(26)
                      : const Color(0xFF4F4A34).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isRemoved
                  ? const Icon(Icons.block, color: Color(0xFFE7000B), size: 18)
                  : session.completed
                      ? const Icon(Icons.check, color: Color(0xFF00A63E), size: 18)
                      : Text(
                          '${session.sessionNumber}',
                          style: const TextStyle(
                            color: Color(0xFF4F4A34),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.name,
                        style: TextStyle(
                          color: isRemoved
                              ? const Color(0xFF697282)
                              : const Color(0xFF212621),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          decoration: isRemoved ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (isModified)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD08700).withAlpha(26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Modificado',
                          style: TextStyle(
                            color: Color(0xFFD08700),
                            fontSize: 9,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isRemoved)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7000B).withAlpha(26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Removido',
                          style: TextStyle(
                            color: Color(0xFFE7000B),
                            fontSize: 9,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (session.description != null && session.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      session.description!,
                      style: const TextStyle(
                        color: Color(0xFF697282),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (hasAdjustment && adjustment.reason != null && adjustment.reason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Motivo: ${adjustment.reason}',
                      style: TextStyle(
                        color: isRemoved ? const Color(0xFFE7000B) : const Color(0xFFD08700),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (session.duration != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${session.duration} min',
                style: const TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF697282), size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditExerciseModal(session, week.id);
              } else if (value == 'remove') {
                _showRemoveExerciseModal(session);
              } else if (value == 'restore') {
                _restoreExercise(session);
              }
            },
            itemBuilder: (context) => [
              if (!isRemoved) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Color(0xFF4F4A34)),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 16, color: Color(0xFFE7000B)),
                      SizedBox(width: 8),
                      Text('Remover', style: TextStyle(color: Color(0xFFE7000B))),
                    ],
                  ),
                ),
              ] else
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.restore, size: 16, color: Color(0xFF00A63E)),
                      SizedBox(width: 8),
                      Text('Restaurar', style: TextStyle(color: Color(0xFF00A63E))),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsSection() {
    if (_patientData == null || _selectedWeekIndex >= _patientData!.weeks.length) {
      return const SizedBox.shrink();
    }

    final week = _patientData!.weeks[_selectedWeekIndex];
    final weekStartDay = (week.weekNumber - 1) * 7 + 1;
    final weekEndDay = week.weekNumber * 7;

    // Filtrar ajustes apenas para a semana selecionada
    final customAdjustments = _patientData?.adjustments.where((a) {
      if (a.adjustmentType != 'ADD' || !a.isActive) return false;

      // Verificar se o ajuste pertence a esta semana
      final fromDay = a.validFromDay ?? 0;
      final untilDay = a.validUntilDay ?? 999;

      // O ajuste deve estar exatamente nesta semana
      return fromDay >= weekStartDay && untilDay <= weekEndDay;
    }).toList() ?? [];

    if (customAdjustments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.add_circle, color: Color(0xFF7C3AED), size: 20),
              SizedBox(width: 8),
              Text(
                'Exercícios Adicionados',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...customAdjustments.map((adj) => _buildCustomExerciseCard(adj)),
        ],
      ),
    );
  }

  Widget _buildCustomExerciseCard(PatientTrainingAdjustment adjustment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.fitness_center, color: Color(0xFF7C3AED), size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adjustment.title ?? 'Exercício personalizado',
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (adjustment.description != null && adjustment.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      adjustment.description!,
                      style: const TextStyle(
                        color: Color(0xFF697282),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (adjustment.reason != null && adjustment.reason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Motivo: ${adjustment.reason}',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE7000B), size: 20),
            onPressed: () => _deleteAdjustment(adjustment),
          ),
        ],
      ),
    );
  }

  // ==================== MODAIS ====================

  void _showAdjustWeekModal(PatientWeekData week) {
    final objectiveController = TextEditingController(text: week.objective);
    final maxHeartRateController = TextEditingController(
      text: week.maxHeartRate?.toString() ?? '',
    );
    final notesController = TextEditingController();
    final newCanDoController = TextEditingController();
    final newAvoidController = TextEditingController();

    // Listas editáveis
    List<String> canDoList = List.from(week.canDo);
    List<String> avoidList = List.from(week.avoid);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header fixo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajustar ${week.title}',
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Para ${widget.patient.name}',
                          style: const TextStyle(
                            color: Color(0xFF697282),
                            fontSize: 13,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Color(0xFF697282)),
                    ),
                  ],
                ),
              ),

              // Conteúdo scrollável
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Objetivo
                      const Text(
                        'Objetivo personalizado',
                        style: TextStyle(
                          color: Color(0xFF4F4A34),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: objectiveController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Objetivo específico para este paciente...',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFFF5F3EF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // FC Máxima
                      const Text(
                        'FC Máxima ajustada (bpm)',
                        style: TextStyle(
                          color: Color(0xFF4F4A34),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: maxHeartRateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ex: 90',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFFF5F3EF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // PODE FAZER
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: Color(0xFF00A63E), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Pode Fazer',
                            style: TextStyle(
                              color: Color(0xFF00A63E),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: canDoList.asMap().entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A63E).withAlpha(26),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00A63E).withAlpha(77)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: Color(0xFF00A63E),
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      canDoList.removeAt(entry.key);
                                    });
                                  },
                                  child: const Icon(Icons.close, size: 16, color: Color(0xFF00A63E)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newCanDoController,
                              decoration: InputDecoration(
                                hintText: 'Adicionar atividade...',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: const Color(0xFFF0FDF4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: const Color(0xFF00A63E).withAlpha(51)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: const Color(0xFF00A63E).withAlpha(51)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (newCanDoController.text.trim().isNotEmpty) {
                                setModalState(() {
                                  canDoList.add(newCanDoController.text.trim());
                                  newCanDoController.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A63E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // EVITAR
                      Row(
                        children: const [
                          Icon(Icons.warning_amber, color: Color(0xFFD08700), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Evitar',
                            style: TextStyle(
                              color: Color(0xFFD08700),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: avoidList.asMap().entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD08700).withAlpha(26),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD08700).withAlpha(77)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: Color(0xFFD08700),
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      avoidList.removeAt(entry.key);
                                    });
                                  },
                                  child: const Icon(Icons.close, size: 16, color: Color(0xFFD08700)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newAvoidController,
                              decoration: InputDecoration(
                                hintText: 'Adicionar restrição...',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: const Color(0xFFFEF3C7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: const Color(0xFFD08700).withAlpha(51)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: const Color(0xFFD08700).withAlpha(51)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (newAvoidController.text.trim().isNotEmpty) {
                                setModalState(() {
                                  avoidList.add(newAvoidController.text.trim());
                                  newAvoidController.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD08700),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Observações
                      const Text(
                        'Observações/Motivo do ajuste',
                        style: TextStyle(
                          color: Color(0xFF4F4A34),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Motivo médico para o ajuste...',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFFF5F3EF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 100), // Espaço para o botão fixo
                    ],
                  ),
                ),
              ),

              // Botão fixo no final
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      // Criar ajuste personalizado para este paciente com todas as informações
                      // Isso não modifica o protocolo padrão, apenas cria uma personalização
                      final adjustmentData = {
                        'objective': objectiveController.text.trim(),
                        'maxHeartRate': int.tryParse(maxHeartRateController.text),
                        'canDo': canDoList,
                        'avoid': avoidList,
                        'reason': notesController.text.trim(),
                      };

                      await _trainingService.createPatientAdjustment(
                        widget.patient.id,
                        adjustmentType: 'MODIFY',
                        weekId: week.id,
                        name: 'Ajuste Semana ${week.weekNumber}',
                        description: '${adjustmentData['objective']}\n\nPode Fazer: ${canDoList.join(", ")}\n\nEvitar: ${avoidList.join(", ")}',
                        reason: notesController.text.trim(),
                        validFromDay: (week.weekNumber - 1) * 7 + 1,
                        validUntilDay: week.weekNumber * 7,
                        canDo: canDoList,
                        avoid: avoidList,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Ajustes salvos com sucesso!')),
                        );
                        _loadPatientTraining();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Erro ao salvar: $e')),
                        );
                      }
                    }
                  },
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
        ),
      ),
    );
  }

  void _showAddExerciseModal() {
    if (_patientData == null || _selectedWeekIndex >= _patientData!.weeks.length) return;

    final week = _patientData!.weeks[_selectedWeekIndex];
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController();
    final reasonController = TextEditingController();
    String? intensity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Adicionar Exercício',
                      style: TextStyle(
                        color: Color(0xFF212621),
                        fontSize: 20,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Color(0xFF697282)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Para ${widget.patient.name} - ${week.title}',
                  style: const TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nome do exercício *',
                  style: TextStyle(
                    color: Color(0xFF4F4A34),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Fortalecimento lombar',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF5F3EF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Descrição/Instruções',
                  style: TextStyle(
                    color: Color(0xFF4F4A34),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Instruções detalhadas do exercício...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF5F3EF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Duração (min)',
                            style: TextStyle(
                              color: Color(0xFF4F4A34),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '10',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                              filled: true,
                              fillColor: const Color(0xFFF5F3EF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Intensidade',
                            style: TextStyle(
                              color: Color(0xFF4F4A34),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatefulBuilder(
                            builder: (context, setDropdownState) {
                              return DropdownButtonFormField<String>(
                                value: intensity,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF5F3EF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                hint: const Text('Selecione'),
                                items: const [
                                  DropdownMenuItem(value: 'Muito leve', child: Text('Muito leve')),
                                  DropdownMenuItem(value: 'Leve', child: Text('Leve')),
                                  DropdownMenuItem(value: 'Leve-Moderada', child: Text('Leve-Moderada')),
                                  DropdownMenuItem(value: 'Moderada', child: Text('Moderada')),
                                  DropdownMenuItem(value: 'Moderada-Alta', child: Text('Moderada-Alta')),
                                  DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                                ],
                                onChanged: (value) {
                                  setDropdownState(() => intensity = value);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Motivo do ajuste',
                  style: TextStyle(
                    color: Color(0xFF4F4A34),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ex: Reforço específico devido à queixa de dor',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF5F3EF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Informe o nome do exercício')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);

                    try {
                      await _trainingService.createPatientAdjustment(
                        widget.patient.id,
                        adjustmentType: 'ADD',
                        weekId: week.id,
                        name: name,
                        description: descriptionController.text.trim(),
                        duration: int.tryParse(durationController.text),
                        intensity: intensity,
                        reason: reasonController.text.trim(),
                        validFromDay: (week.weekNumber - 1) * 7 + 1,
                        validUntilDay: week.weekNumber * 7,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exercício adicionado!')),
                        );
                        _loadPatientTraining();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F4A34),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Adicionar Exercício',
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
        ),
      ),
    );
  }

  void _showEditExerciseModal(PatientSessionData session, String weekId) {
    final durationController = TextEditingController(text: session.duration?.toString() ?? '');
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  const Text(
                    'Editar Exercício',
                    style: TextStyle(
                      color: Color(0xFF212621),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Color(0xFF697282)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                session.name,
                style: const TextStyle(
                  color: Color(0xFF4F4A34),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFFD08700), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alterações serão aplicadas apenas para este paciente',
                        style: TextStyle(
                          color: Color(0xFFD08700),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Duração ajustada (min)',
                style: TextStyle(
                  color: Color(0xFF4F4A34),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nova duração em minutos',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF5F3EF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Observação personalizada',
                style: TextStyle(
                  color: Color(0xFF4F4A34),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ex: Reduzir intensidade devido ao cansaço',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF5F3EF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _trainingService.createPatientAdjustment(
                      widget.patient.id,
                      adjustmentType: 'MODIFY',
                      baseSessionId: session.id,
                      duration: int.tryParse(durationController.text),
                      reason: notesController.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exercício modificado!')),
                      );
                      _loadPatientTraining();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: $e')),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F4A34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Salvar Alterações',
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
      ),
    );
  }

  void _showRemoveExerciseModal(PatientSessionData session) {
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  const Text(
                    'Remover Exercício',
                    style: TextStyle(
                      color: Color(0xFFE7000B),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Color(0xFF697282)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Color(0xFFE7000B), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.name,
                            style: const TextStyle(
                              color: Color(0xFF212621),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (session.duration != null)
                            Text(
                              '${session.duration} minutos',
                              style: const TextStyle(
                                color: Color(0xFF697282),
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Este exercício será removido apenas para este paciente. Você poderá restaurá-lo depois.',
                style: TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Motivo da remoção *',
                style: TextStyle(
                  color: Color(0xFF4F4A34),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ex: Paciente com restrição lombar',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF5F3EF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe o motivo da remoção')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  try {
                    await _trainingService.createPatientAdjustment(
                      widget.patient.id,
                      adjustmentType: 'REMOVE',
                      baseSessionId: session.id,
                      reason: reason,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exercício removido!')),
                      );
                      _loadPatientTraining();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: $e')),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7000B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Remover Exercício',
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
      ),
    );
  }

  Future<void> _restoreExercise(PatientSessionData session) async {
    final adjustment = _patientData?.adjustments.firstWhere(
      (a) => a.baseContentId == session.id && a.adjustmentType == 'REMOVE' && a.isActive,
      orElse: () => PatientTrainingAdjustment(
        id: '',
        patientId: '',
        adjustmentType: '',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );

    if (adjustment == null || adjustment.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajuste não encontrado')),
      );
      return;
    }

    try {
      await _trainingService.deletePatientAdjustment(adjustment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercício restaurado!')),
        );
        _loadPatientTraining();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _deleteAdjustment(PatientTrainingAdjustment adjustment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir exercício personalizado?'),
        content: Text('Deseja excluir "${adjustment.title}"?\nEsta ação não pode ser desfeita.'),
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
        await _trainingService.deletePatientAdjustment(adjustment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercício excluído!')),
          );
          _loadPatientTraining();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }
}
