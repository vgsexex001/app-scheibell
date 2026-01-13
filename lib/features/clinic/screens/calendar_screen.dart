import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar_appointment.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final int _selectedNavIndex = 4; // Calendário tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().loadMonthAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Consumer<CalendarProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.appointments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildStatsRow(provider),
                    const SizedBox(height: 16),
                    _buildCalendar(provider),
                    const SizedBox(height: 16),
                    _buildLegends(),
                    const SizedBox(height: 24),
                    _buildDayAppointments(provider),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendário',
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
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exportar CSV')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F4A34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.download, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Exportar',
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showNewAppointmentModal,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F4A34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(CalendarProvider provider) {
    return Row(
      children: [
        _StatCard(
          value: provider.totalCount.toString(),
          label: 'Total',
          color: const Color(0xFF212621),
          isFirst: true,
        ),
        const SizedBox(width: 8),
        _StatCard(
          value: provider.confirmedCount.toString(),
          label: 'Confirmados',
          color: const Color(0xFF00A63E),
        ),
        const SizedBox(width: 8),
        _StatCard(
          value: provider.pendingCount.toString(),
          label: 'Pendentes',
          color: const Color(0xFFD08700),
        ),
        const SizedBox(width: 8),
        _StatCard(
          value: provider.completedCount.toString(),
          label: 'Concluídos',
          color: const Color(0xFF495565),
        ),
      ],
    );
  }

  Widget _buildCalendar(CalendarProvider provider) {
    final currentMonth = provider.currentMonth;
    final selectedDate = provider.selectedDate;
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C2B4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  final newMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
                  provider.setCurrentMonth(newMonth);
                },
                child: const Icon(Icons.chevron_left, color: Color(0xFF495565)),
              ),
              Text(
                _getMonthName(currentMonth),
                style: const TextStyle(
                  color: Color(0xFF212621),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  final newMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
                  provider.setCurrentMonth(newMonth);
                },
                child: const Icon(Icons.chevron_right, color: Color(0xFF495565)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekdayLabel(label: 'D'),
              _WeekdayLabel(label: 'S'),
              _WeekdayLabel(label: 'T'),
              _WeekdayLabel(label: 'Q'),
              _WeekdayLabel(label: 'Q'),
              _WeekdayLabel(label: 'S'),
              _WeekdayLabel(label: 'S'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + lastDay.day,
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox();
              }
              final day = index - startWeekday + 1;
              final date = DateTime(currentMonth.year, currentMonth.month, day);
              final isSelected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final statuses = provider.getStatusesForDay(date);

              return GestureDetector(
                onTap: () => provider.setSelectedDate(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4F4A34)
                        : isToday
                            ? const Color(0xFFF5F3EF)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF4F4A34))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF212621),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (statuses.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: statuses.take(3).map((status) {
                            return Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2, right: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withAlpha(179)
                                    : _getStatusColor(status),
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegends() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legenda de Status',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendItem(color: Color(0xFF00A63E), label: 'Confirmado'),
              SizedBox(width: 16),
              _LegendItem(color: Color(0xFFD08700), label: 'Pendente'),
              SizedBox(width: 16),
              _LegendItem(color: Color(0xFF9CA3AF), label: 'Concluído'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tipos de Consulta',
            style: TextStyle(
              color: Color(0xFF212621),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _ConsultationTypeLegend(
                icon: Icons.person_add_outlined,
                color: Color(0xFF7C3AED),
                label: 'Primeira Consulta',
              ),
              _ConsultationTypeLegend(
                icon: Icons.event_repeat_outlined,
                color: Color(0xFF155CFB),
                label: 'Retorno 7d',
              ),
              _ConsultationTypeLegend(
                icon: Icons.replay_outlined,
                color: Color(0xFF00A63E),
                label: 'Retorno 30d',
              ),
              _ConsultationTypeLegend(
                icon: Icons.healing_outlined,
                color: Color(0xFFE7000B),
                label: 'Pós-Operatório',
              ),
              _ConsultationTypeLegend(
                icon: Icons.search_outlined,
                color: Color(0xFFD08700),
                label: 'Avaliação',
              ),
              _ConsultationTypeLegend(
                icon: Icons.videocam_outlined,
                color: Color(0xFF059669),
                label: 'Telemedicina',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayAppointments(CalendarProvider provider) {
    final selectedDate = provider.selectedDate;
    final appointments = provider.appointmentsForSelectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dia ${selectedDate.day} de ${_getMonthNameShort(selectedDate.month)}',
                  style: const TextStyle(
                    color: Color(0xFF212621),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${appointments.length} agendamento${appointments.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  isSelected: provider.statusFilter == 'ALL',
                  onTap: () => provider.setStatusFilter('ALL'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Confirmados',
                  isSelected: provider.statusFilter == 'CONFIRMED',
                  onTap: () => provider.setStatusFilter('CONFIRMED'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pendentes',
                  isSelected: provider.statusFilter == 'PENDING',
                  onTap: () => provider.setStatusFilter('PENDING'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Concluídos',
                  isSelected: provider.statusFilter == 'COMPLETED',
                  onTap: () => provider.setStatusFilter('COMPLETED'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (appointments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              children: [
                Icon(Icons.calendar_today_outlined, size: 48, color: Color(0xFF9CA3AF)),
                SizedBox(height: 12),
                Text(
                  'Nenhum agendamento',
                  style: TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Não há consultas marcadas para este dia',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          )
        else
          ...appointments.map((appointment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AppointmentCard(
              appointment: appointment,
              onTap: () => _showAppointmentDetailModal(appointment),
              onEdit: () => _showAppointmentDetailModal(appointment),
              onCancel: () => _cancelAppointment(appointment),
            ),
          )),
      ],
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
              _buildNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Painel', index: 0),
              _buildNavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Pacientes', index: 1),
              _buildNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chat', index: 2),
              _buildNavItem(icon: Icons.article_outlined, activeIcon: Icons.article, label: 'Conteúdos', index: 3),
              _buildNavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Calendário', index: 4),
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
          color: isSelected ? const Color(0xFFA49E86).withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFFA49E86) : const Color(0xFF6B6B6B),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFFA49E86) : const Color(0xFF6B6B6B),
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
        Navigator.pushReplacementNamed(context, '/clinic-patients');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/clinic-chat');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/clinic-content-management');
        break;
      case 4:
        // Already on calendar
        break;
    }
  }

  void _showAppointmentDetailModal(CalendarAppointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AppointmentDetailModal(
        appointment: appointment,
        onSave: (status, notes, consultationType) async {
          final provider = context.read<CalendarProvider>();
          final success = await provider.updateAppointment(
            appointment.id,
            status: status,
            notes: notes,
            consultationType: consultationType,
          );
          if (mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Agendamento atualizado' : 'Erro ao atualizar'),
              ),
            );
          }
        },
      ),
    );
  }

  void _showNewAppointmentModal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Criar novo agendamento')),
    );
  }

  void _cancelAppointment(CalendarAppointment appointment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar agendamento?'),
        content: Text('Deseja cancelar a consulta de ${appointment.patientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<CalendarProvider>();
              final success = await provider.cancelAppointment(appointment.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Agendamento cancelado' : 'Erro ao cancelar'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE7000B)),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(DateTime date) {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getMonthNameShort(int month) {
    final months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    return months[month - 1];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return const Color(0xFF00A63E);
      case 'PENDING':
        return const Color(0xFFD08700);
      case 'COMPLETED':
        return const Color(0xFF9CA3AF);
      case 'CANCELLED':
        return const Color(0xFFE7000B);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}

// ==================== WIDGETS ====================

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
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
  final bool isFirst;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isFirst ? const Color(0xFFF5F3EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF495565),
                fontSize: 10,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F4A34) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF495565),
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF495565),
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _ConsultationTypeLegend extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _ConsultationTypeLegend({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF495565),
              fontSize: 12,
              fontFamily: 'Inter',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final CalendarAppointment appointment;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    required this.onEdit,
    required this.onCancel,
  });

  Color get _statusBgColor {
    switch (appointment.status) {
      case 'CONFIRMED':
        return const Color(0xFFDCFCE7);
      case 'PENDING':
        return const Color(0xFFFEF9C2);
      case 'COMPLETED':
        return const Color(0xFFF3F4F6);
      case 'CANCELLED':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get _statusTextColor {
    switch (appointment.status) {
      case 'CONFIRMED':
        return const Color(0xFF008235);
      case 'PENDING':
        return const Color(0xFFA65F00);
      case 'COMPLETED':
        return const Color(0xFF354152);
      case 'CANCELLED':
        return const Color(0xFFE7000B);
      default:
        return const Color(0xFF354152);
    }
  }

  String get _statusLabel {
    switch (appointment.status) {
      case 'CONFIRMED':
        return 'Confirmado';
      case 'PENDING':
        return 'Pendente';
      case 'COMPLETED':
        return 'Concluído';
      case 'CANCELLED':
        return 'Cancelado';
      default:
        return '';
    }
  }

  String get _consultationTypeLabel {
    switch (appointment.consultationType) {
      case 'FIRST_CONSULTATION':
        return 'Primeira Consulta';
      case 'RETURN_7D':
      case 'RETURN_VISIT':
        return 'Retorno 7 dias';
      case 'RETURN_30D':
        return 'Retorno 30 dias';
      case 'POST_OP':
        return 'Pós-Operatório';
      case 'EVALUATION':
        return 'Avaliação';
      case 'TELEMEDICINE':
        return 'Telemedicina';
      case 'CONSULTATION':
        return 'Consulta';
      default:
        return appointment.consultationType;
    }
  }

  Color get _consultationTypeColor {
    switch (appointment.consultationType) {
      case 'FIRST_CONSULTATION':
        return const Color(0xFF7C3AED);
      case 'RETURN_7D':
      case 'RETURN_VISIT':
        return const Color(0xFF155CFB);
      case 'RETURN_30D':
        return const Color(0xFF00A63E);
      case 'POST_OP':
        return const Color(0xFFE7000B);
      case 'EVALUATION':
        return const Color(0xFFD08700);
      case 'TELEMEDICINE':
        return const Color(0xFF059669);
      case 'CONSULTATION':
        return const Color(0xFF495565);
      default:
        return const Color(0xFF495565);
    }
  }

  IconData get _consultationTypeIcon {
    switch (appointment.consultationType) {
      case 'FIRST_CONSULTATION':
        return Icons.person_add_outlined;
      case 'RETURN_7D':
      case 'RETURN_VISIT':
        return Icons.event_repeat_outlined;
      case 'RETURN_30D':
        return Icons.replay_outlined;
      case 'POST_OP':
        return Icons.healing_outlined;
      case 'EVALUATION':
        return Icons.search_outlined;
      case 'TELEMEDICINE':
        return Icons.videocam_outlined;
      case 'CONSULTATION':
        return Icons.medical_services_outlined;
      default:
        return Icons.event_outlined;
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time, color: Color(0xFF495565), size: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.time,
                  style: const TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appointment.patientName,
                          style: const TextStyle(
                            color: Color(0xFF212621),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusBgColor,
                          borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 4),
                  Text(
                    appointment.procedureType,
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _consultationTypeColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _consultationTypeColor.withAlpha(77)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_consultationTypeIcon, size: 14, color: _consultationTypeColor),
                        const SizedBox(width: 4),
                        Text(
                          _consultationTypeLabel,
                          style: TextStyle(
                            color: _consultationTypeColor,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onEdit,
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 14, color: Color(0xFF495565)),
                            SizedBox(width: 4),
                            Text(
                              'Editar',
                              style: TextStyle(
                                color: Color(0xFF495565),
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onCancel,
                        child: const Row(
                          children: [
                            Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFE7000B)),
                            SizedBox(width: 4),
                            Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Color(0xFFE7000B),
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MODAL DE DETALHES ====================

class _AppointmentDetailModal extends StatefulWidget {
  final CalendarAppointment appointment;
  final Function(String status, String notes, String consultationType) onSave;

  const _AppointmentDetailModal({
    required this.appointment,
    required this.onSave,
  });

  @override
  State<_AppointmentDetailModal> createState() => _AppointmentDetailModalState();
}

class _AppointmentDetailModalState extends State<_AppointmentDetailModal> {
  late TextEditingController _notesController;
  late String _selectedStatus;
  late String _selectedConsultationType;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'CONFIRMED', 'label': 'Confirmado', 'color': const Color(0xFF00A63E)},
    {'value': 'PENDING', 'label': 'Pendente', 'color': const Color(0xFFD08700)},
    {'value': 'COMPLETED', 'label': 'Concluído', 'color': const Color(0xFF495565)},
    {'value': 'CANCELLED', 'label': 'Cancelado', 'color': const Color(0xFFE7000B)},
  ];

  final List<Map<String, dynamic>> _consultationTypes = [
    {'value': 'FIRST_CONSULTATION', 'label': 'Primeira Consulta', 'icon': Icons.person_add_outlined, 'color': const Color(0xFF7C3AED)},
    {'value': 'RETURN_VISIT', 'label': 'Retorno', 'icon': Icons.event_repeat_outlined, 'color': const Color(0xFF155CFB)},
    {'value': 'EVALUATION', 'label': 'Avaliação', 'icon': Icons.search_outlined, 'color': const Color(0xFFD08700)},
    {'value': 'CONSULTATION', 'label': 'Consulta', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFF495565)},
    {'value': 'PHYSIOTHERAPY', 'label': 'Fisioterapia', 'icon': Icons.healing_outlined, 'color': const Color(0xFFE7000B)},
    {'value': 'EXAM', 'label': 'Exame', 'icon': Icons.biotech_outlined, 'color': const Color(0xFF059669)},
  ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.appointment.notes);
    _selectedStatus = widget.appointment.status;
    _selectedConsultationType = widget.appointment.consultationType;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4F4A34),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detalhes do Agendamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paciente', style: TextStyle(color: Color(0xFF495565), fontSize: 12, fontFamily: 'Inter')),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: Color(0xFF495565)),
                      const SizedBox(width: 8),
                      Text(
                        widget.appointment.patientName,
                        style: const TextStyle(color: Color(0xFF212621), fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Data', style: TextStyle(color: Color(0xFF495565), fontSize: 12, fontFamily: 'Inter')),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(widget.appointment.date),
                              style: const TextStyle(color: Color(0xFF212621), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Horário', style: TextStyle(color: Color(0xFF495565), fontSize: 12, fontFamily: 'Inter')),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Color(0xFF495565)),
                                const SizedBox(width: 4),
                                Text(
                                  widget.appointment.time,
                                  style: const TextStyle(color: Color(0xFF212621), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('Procedimento', style: TextStyle(color: Color(0xFF495565), fontSize: 12, fontFamily: 'Inter')),
                  const SizedBox(height: 4),
                  Text(
                    widget.appointment.procedureType,
                    style: const TextStyle(color: Color(0xFF212621), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  const Text('Tipo de Consulta', style: TextStyle(color: Color(0xFF495565), fontSize: 12, fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _consultationTypes.map((type) {
                      final isSelected = _selectedConsultationType == type['value'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedConsultationType = type['value']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? (type['color'] as Color).withAlpha(26) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? type['color'] as Color : const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(type['icon'] as IconData, size: 14, color: isSelected ? type['color'] as Color : const Color(0xFF495565)),
                              const SizedBox(width: 4),
                              Text(
                                type['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? type['color'] as Color : const Color(0xFF495565),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('Status do Agendamento', style: TextStyle(color: Color(0xFF495565), fontSize: 12, fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _statusOptions.map((status) {
                      final isSelected = _selectedStatus == status['value'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStatus = status['value']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? status['color'] as Color : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? status['color'] as Color : const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            status['label'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF495565),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('Observações', style: TextStyle(color: Color(0xFF495565), fontSize: 12, fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Adicione observações...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4F4A34)),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () {
                      widget.onSave(
                        _selectedStatus,
                        _notesController.text,
                        _selectedConsultationType,
                      );
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
                          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
