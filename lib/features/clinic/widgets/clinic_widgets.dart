import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/patient_card.dart';
import '../providers/clinic_dashboard_provider.dart';
import '../models/models.dart';

class TodayScheduleWidget extends StatefulWidget {
  const TodayScheduleWidget({super.key});

  @override
  State<TodayScheduleWidget> createState() => _TodayScheduleWidgetState();
}

class _TodayScheduleWidgetState extends State<TodayScheduleWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicDashboardProvider>().loadTodayAppointments();
    });
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 'confirmado';
      case 'PENDING':
        return 'aguardando';
      case 'CANCELLED':
        return 'cancelado';
      default:
        return status.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicDashboardProvider>();
    final appointments = provider.todayAppointments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (provider.isLoadingToday)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum agendamento para hoje',
                style: TextStyle(color: Color(0xFF6B6B6B)),
              ),
            )
          else
            ...appointments.asMap().entries.map((entry) {
              final index = entry.key;
              final appointment = entry.value;
              return Column(
                children: [
                  _buildAppointmentItem(
                    time: appointment.time,
                    name: appointment.patientName,
                    procedure: appointment.procedureType,
                    status: _getStatusLabel(appointment.status),
                    onTap: () {},
                  ),
                  if (index < appointments.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.grey.withAlpha(31),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Ver agenda completa',
                style: TextStyle(
                  color: Color(0xFFA49E86),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem({
    required String time,
    required String name,
    required String procedure,
    required String status,
    VoidCallback? onTap,
  }) {
    Color statusColor;
    switch (status) {
      case 'confirmado':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'aguardando':
        statusColor = const Color(0xFFFF9800);
        break;
      case 'cancelado':
        statusColor = const Color(0xFFE53935);
        break;
      default:
        statusColor = const Color(0xFF6B6B6B);
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F4F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    procedure,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentPatientsWidget extends StatefulWidget {
  const RecentPatientsWidget({super.key});

  @override
  State<RecentPatientsWidget> createState() => _RecentPatientsWidgetState();
}

class _RecentPatientsWidgetState extends State<RecentPatientsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicDashboardProvider>().loadRecentPatients();
    });
  }

  String _formatDaysAgo(int days) {
    if (days == 0) return 'Hoje';
    if (days == 1) return '1 dia atrás';
    if (days < 7) return '$days dias atrás';
    if (days < 14) return '1 semana atrás';
    return '${days ~/ 7} semanas atrás';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicDashboardProvider>();
    final patients = provider.recentPatients;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (provider.isLoadingRecent)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (patients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum paciente recente',
                style: TextStyle(color: Color(0xFF6B6B6B)),
              ),
            )
          else
            ...patients.map((patient) => PatientListTile(
                  name: patient.name,
                  procedure: patient.procedureType,
                  date: _formatDaysAgo(patient.daysAgo),
                  onTap: () {},
                )),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Ver todos os pacientes',
                style: TextStyle(
                  color: Color(0xFFA49E86),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionButton(
          icon: Icons.person_add_outlined,
          label: 'Novo Paciente',
          color: const Color(0xFFA49E86),
          onTap: () {},
        ),
        _buildActionButton(
          icon: Icons.calendar_today_outlined,
          label: 'Agendar',
          color: const Color(0xFF4CAF50),
          onTap: () {},
        ),
        _buildActionButton(
          icon: Icons.article_outlined,
          label: 'Relatórios',
          color: const Color(0xFF2196F3),
          onTap: () {},
        ),
        _buildActionButton(
          icon: Icons.message_outlined,
          label: 'Mensagens',
          color: const Color(0xFF9C27B0),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientsInRecoveryWidget extends StatefulWidget {
  const PatientsInRecoveryWidget({super.key});

  @override
  State<PatientsInRecoveryWidget> createState() => _PatientsInRecoveryWidgetState();
}

class _PatientsInRecoveryWidgetState extends State<PatientsInRecoveryWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicDashboardProvider>().loadRecoveryPatients(limit: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicDashboardProvider>();
    final patients = provider.recoveryPatients;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (provider.isLoadingRecovery)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (patients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum paciente em recuperação',
                style: TextStyle(color: Color(0xFF6B6B6B)),
              ),
            )
          else
            ...patients.map((patient) => _buildRecoveryItem(
                  name: patient.patientName,
                  procedure: patient.procedureType,
                  day: 'Dia ${patient.dayPostOp}',
                  progress: patient.progressPercent / 100.0,
                )),
        ],
      ),
    );
  }

  Widget _buildRecoveryItem({
    required String name,
    required String procedure,
    required String day,
    required double progress,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8E6E0),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA49E86),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  procedure,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6B6B),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE8E6E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA49E86)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
