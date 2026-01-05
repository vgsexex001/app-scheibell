import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'patient_detail_screen.dart';
import '../providers/patients_provider.dart';
import '../models/models.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  final int _selectedNavIndex = 1; // Pacientes tab
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Carregar pacientes ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientsProvider>().loadPatients(refresh: true);
    });

    // Listener para paginação infinita
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PatientsProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<PatientsProvider>().loadPatients(
      search: query.isNotEmpty ? query : null,
      status: _selectedFilter != 'ALL' ? _selectedFilter : null,
      refresh: true,
    );
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    context.read<PatientsProvider>().loadPatients(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      status: filter != 'ALL' ? filter : null,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilters(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 16),
              Expanded(child: _buildPatientsList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pacientes',
          style: TextStyle(
            color: Color(0xFF212621),
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Gerencie seus pacientes',
          style: TextStyle(
            color: Color(0xFF495565),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: const InputDecoration(
          hintText: 'Buscar paciente...',
          hintStyle: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            isSelected: _selectedFilter == 'ALL',
            onTap: () => _onFilterChanged('ALL'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Em Recuperação',
            isSelected: _selectedFilter == 'RECOVERY',
            onTap: () => _onFilterChanged('RECOVERY'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Ativos',
            isSelected: _selectedFilter == 'ACTIVE',
            onTap: () => _onFilterChanged('ACTIVE'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Concluídos',
            isSelected: _selectedFilter == 'COMPLETED',
            onTap: () => _onFilterChanged('COMPLETED'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<PatientsProvider>(
      builder: (context, provider, _) {
        final total = provider.totalPatients;
        final recovery = provider.patients.where((p) => p.status == 'RECOVERY').length;
        final active = provider.patients.where((p) => p.status == 'ACTIVE').length;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                value: total.toString(),
                label: 'Total',
                color: const Color(0xFF155CFB),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                value: recovery.toString(),
                label: 'Recuperação',
                color: const Color(0xFFD08700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                value: active.toString(),
                label: 'Ativos',
                color: const Color(0xFF00A63E),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatientsList() {
    return Consumer<PatientsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingList && provider.patients.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA49E86)),
            ),
          );
        }

        if (provider.error != null && provider.patients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.refresh(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (provider.patients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.people_outline, size: 48, color: Color(0xFF9CA3AF)),
                SizedBox(height: 16),
                Text(
                  'Nenhum paciente encontrado',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          color: const Color(0xFFA49E86),
          child: ListView.separated(
            controller: _scrollController,
            itemCount: provider.patients.length + (provider.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= provider.patients.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA49E86)),
                    ),
                  ),
                );
              }

              final patient = provider.patients[index];
              return _PatientCard(
                patient: patient,
                onTap: () => _navigateToPatientDetail(patient),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToPatientDetail(PatientListItem patient) {
    debugPrint('[NAV] opening PatientDetails patientId=${patient.id} source=patients_list');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<PatientsProvider>(),
          child: PatientDetailScreen(
            patientId: patient.id,
            patientName: patient.name,
            phone: patient.phone ?? '',
            surgeryType: patient.surgeryType,
            surgeryDate: patient.surgeryDate != null
                ? DateTime.tryParse(patient.surgeryDate!)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Painel',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Pacientes',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Chat',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'Conteúdos',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Calendário',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _navigateToIndex(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFA49E86).withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? const Color(0xFFA49E86)
                  : const Color(0xFF6B6B6B),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFFA49E86)
                    : const Color(0xFF6B6B6B),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToIndex(int index) {
    if (index == _selectedNavIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/clinic-dashboard');
        break;
      case 1:
        // Already on patients list
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/clinic-chat');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/clinic-content-management');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/clinic-calendar');
        break;
    }
  }
}

// ==================== WIDGETS ====================

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F4A34) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF495565),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF495565),
              fontSize: 12,
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

  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  Color get _statusBgColor {
    switch (patient.status) {
      case 'RECOVERY':
        return const Color(0xFFFEF9C2);
      case 'ACTIVE':
        return const Color(0xFFDCFCE7);
      case 'COMPLETED':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get _statusBorderColor {
    switch (patient.status) {
      case 'RECOVERY':
        return const Color(0xFFFEEF85);
      case 'ACTIVE':
        return const Color(0xFFB8F7CF);
      case 'COMPLETED':
        return const Color(0xFFE5E7EB);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color get _statusTextColor {
    switch (patient.status) {
      case 'RECOVERY':
        return const Color(0xFFA65F00);
      case 'ACTIVE':
        return const Color(0xFF008235);
      case 'COMPLETED':
        return const Color(0xFF354152);
      default:
        return const Color(0xFF354152);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC8C2B4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nome + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          color: Color(0xFF212621),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.surgeryType ?? 'Procedimento não informado',
                        style: const TextStyle(
                          color: Color(0xFF495565),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusBorderColor),
                  ),
                  child: Text(
                    patient.statusLabel,
                    style: TextStyle(
                      color: _statusTextColor,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Footer: D+ e próxima consulta
            Row(
              children: [
                if (patient.dayPostOp != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      patient.dayPostOpLabel,
                      style: const TextStyle(
                        color: Color(0xFF495565),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (patient.nextAppointment != null) ...[
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF495565)),
                  const SizedBox(width: 4),
                  Text(
                    'Próxima: ${patient.nextAppointment!.displayDate} às ${patient.nextAppointment!.time}',
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.event_busy_outlined, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  const Text(
                    'Sem consulta agendada',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
