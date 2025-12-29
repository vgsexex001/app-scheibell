import 'package:flutter/material.dart';
import 'patient_detail_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  int _selectedNavIndex = 1; // Pacientes tab

  // Mock - será substituído por API
  final List<_Appointment> _appointments = [
    _Appointment(
      id: '1',
      patientId: 'p1',
      patientName: 'Maria Silva',
      appointmentType: 'Retorno 7 dias',
      status: 'PENDING',
      date: DateTime(2024, 12, 8),
      time: '09:00',
      phone: '(11) 99999-1111',
      surgeryType: 'Abdominoplastia',
      surgeryDate: DateTime(2024, 12, 1),
    ),
    _Appointment(
      id: '2',
      patientId: 'p2',
      patientName: 'João Santos',
      appointmentType: 'Primeira consulta',
      status: 'CONFIRMED',
      date: DateTime(2024, 12, 8),
      time: '10:30',
      phone: '(11) 99999-2222',
      surgeryType: null,
      surgeryDate: null,
    ),
    _Appointment(
      id: '3',
      patientId: 'p3',
      patientName: 'Ana Costa',
      appointmentType: 'Avaliação 30 dias',
      status: 'CONFIRMED',
      date: DateTime(2024, 12, 8),
      time: '14:00',
      phone: '(11) 99999-3333',
      surgeryType: 'Rinoplastia',
      surgeryDate: DateTime(2024, 11, 8),
    ),
    _Appointment(
      id: '4',
      patientId: 'p4',
      patientName: 'Carlos Lima',
      appointmentType: 'Retorno',
      status: 'PENDING',
      date: DateTime(2024, 12, 8),
      time: '15:30',
      phone: '(11) 99999-4444',
      surgeryType: 'Lipoaspiração',
      surgeryDate: DateTime(2024, 11, 20),
    ),
    _Appointment(
      id: '5',
      patientId: 'p5',
      patientName: 'Paula Mendes',
      appointmentType: 'Pós-operatório',
      status: 'CONFIRMED',
      date: DateTime(2024, 12, 9),
      time: '09:00',
      phone: '(11) 99999-5555',
      surgeryType: 'Mamoplastia',
      surgeryDate: DateTime(2024, 11, 25),
    ),
    _Appointment(
      id: '6',
      patientId: 'p6',
      patientName: 'Ricardo Alves',
      appointmentType: 'Consulta',
      status: 'COMPLETED',
      date: DateTime(2024, 12, 9),
      time: '11:00',
      phone: '(11) 99999-6666',
      surgeryType: 'Blefaroplastia',
      surgeryDate: DateTime(2024, 10, 15),
    ),
  ];

  List<_Appointment> get _filteredAppointments {
    var filtered = _appointments;

    // Filtrar por status
    if (_selectedFilter != 'ALL') {
      filtered = filtered.where((a) => a.status == _selectedFilter).toList();
    }

    // Filtrar por busca
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((a) =>
        a.patientName.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  }

  int get _totalToday => _appointments.where((a) =>
    a.date.day == DateTime.now().day &&
    a.date.month == DateTime.now().month
  ).length;

  int get _pendingCount => _appointments.where((a) => a.status == 'PENDING').length;
  int get _confirmedCount => _appointments.where((a) => a.status == 'CONFIRMED').length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              Expanded(child: _buildAppointmentsList()),
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
          'Consultas Agendadas',
          style: TextStyle(
            color: Color(0xFF212621),
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Gerencie seus agendamentos',
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
        onChanged: (_) => setState(() {}),
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
            label: 'Todas',
            isSelected: _selectedFilter == 'ALL',
            onTap: () => setState(() => _selectedFilter = 'ALL'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pendentes',
            isSelected: _selectedFilter == 'PENDING',
            onTap: () => setState(() => _selectedFilter = 'PENDING'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Confirmadas',
            isSelected: _selectedFilter == 'CONFIRMED',
            onTap: () => setState(() => _selectedFilter = 'CONFIRMED'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Concluídas',
            isSelected: _selectedFilter == 'COMPLETED',
            onTap: () => setState(() => _selectedFilter = 'COMPLETED'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: _totalToday.toString(),
            label: 'Total Hoje',
            color: const Color(0xFF155CFB),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: _pendingCount.toString(),
            label: 'Pendentes',
            color: const Color(0xFFD08700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: _confirmedCount.toString(),
            label: 'Confirmadas',
            color: const Color(0xFF00A63E),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsList() {
    final appointments = _filteredAppointments;

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_today_outlined, size: 48, color: Color(0xFF9CA3AF)),
            SizedBox(height: 16),
            Text(
              'Nenhuma consulta encontrada',
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

    return ListView.separated(
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onTap: () => _navigateToPatientDetail(appointment),
        );
      },
    );
  }

  void _navigateToPatientDetail(_Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(
          patientId: appointment.patientId,
          patientName: appointment.patientName,
          phone: appointment.phone,
          surgeryType: appointment.surgeryType,
          surgeryDate: appointment.surgeryDate,
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

// ==================== MODELS ====================

class _Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String appointmentType;
  final String status; // PENDING, CONFIRMED, COMPLETED
  final DateTime date;
  final String time;
  final String phone;
  final String? surgeryType;
  final DateTime? surgeryDate;

  _Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.appointmentType,
    required this.status,
    required this.date,
    required this.time,
    required this.phone,
    this.surgeryType,
    this.surgeryDate,
  });
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

class _AppointmentCard extends StatelessWidget {
  final _Appointment appointment;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
  });

  Color get _statusBgColor {
    switch (appointment.status) {
      case 'PENDING':
        return const Color(0xFFFEF9C2);
      case 'CONFIRMED':
        return const Color(0xFFDCFCE7);
      case 'COMPLETED':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get _statusBorderColor {
    switch (appointment.status) {
      case 'PENDING':
        return const Color(0xFFFEEF85);
      case 'CONFIRMED':
        return const Color(0xFFB8F7CF);
      case 'COMPLETED':
        return const Color(0xFFE5E7EB);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color get _statusTextColor {
    switch (appointment.status) {
      case 'PENDING':
        return const Color(0xFFA65F00);
      case 'CONFIRMED':
        return const Color(0xFF008235);
      case 'COMPLETED':
        return const Color(0xFF354152);
      default:
        return const Color(0xFF354152);
    }
  }

  String get _statusLabel {
    switch (appointment.status) {
      case 'PENDING':
        return 'Pendente';
      case 'CONFIRMED':
        return 'Confirmado';
      case 'COMPLETED':
        return 'Concluído';
      default:
        return '';
    }
  }

  String get _formattedDate {
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${appointment.date.day} ${months[appointment.date.month - 1]}';
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
                        appointment.patientName,
                        style: const TextStyle(
                          color: Color(0xFF212621),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.appointmentType,
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
                    _statusLabel,
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
            // Footer: Data e Hora
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF495565)),
                const SizedBox(width: 4),
                Text(
                  _formattedDate,
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: Color(0xFF495565)),
                const SizedBox(width: 4),
                Text(
                  appointment.time,
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
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
