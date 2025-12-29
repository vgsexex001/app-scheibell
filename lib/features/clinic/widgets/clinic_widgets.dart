import 'package:flutter/material.dart';
import '../../../shared/widgets/patient_card.dart';

class TodayScheduleWidget extends StatelessWidget {
  const TodayScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual data from provider
    final appointments = [
      {
        'time': '09:00',
        'name': 'Maria Silva',
        'procedure': 'Consulta de Retorno',
        'status': 'confirmado',
      },
      {
        'time': '10:30',
        'name': 'João Santos',
        'procedure': 'Retirada de Splint',
        'status': 'aguardando',
      },
      {
        'time': '14:00',
        'name': 'Ana Oliveira',
        'procedure': 'Fisioterapia',
        'status': 'confirmado',
      },
    ];

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
          ...appointments.asMap().entries.map((entry) {
            final index = entry.key;
            final appointment = entry.value;
            return Column(
              children: [
                _buildAppointmentItem(
                  time: appointment['time']!,
                  name: appointment['name']!,
                  procedure: appointment['procedure']!,
                  status: appointment['status']!,
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

class RecentPatientsWidget extends StatelessWidget {
  const RecentPatientsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual data from provider
    final patients = [
      {
        'name': 'Carla Mendes',
        'procedure': 'Rinoplastia',
        'daysAgo': '2 dias atrás',
      },
      {
        'name': 'Roberto Lima',
        'procedure': 'Lipoaspiração',
        'daysAgo': '5 dias atrás',
      },
      {
        'name': 'Fernanda Costa',
        'procedure': 'Blefaroplastia',
        'daysAgo': '1 semana atrás',
      },
    ];

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
          ...patients.map((patient) => PatientListTile(
                name: patient['name']!,
                procedure: patient['procedure']!,
                date: patient['daysAgo']!,
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

class PatientsInRecoveryWidget extends StatelessWidget {
  const PatientsInRecoveryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final patients = [
      {
        'name': 'Maria Silva',
        'procedure': 'Rinoplastia',
        'day': 'Dia 7',
        'progress': 0.7,
      },
      {
        'name': 'João Santos',
        'procedure': 'Blefaroplastia',
        'day': 'Dia 3',
        'progress': 0.3,
      },
    ];

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
          ...patients.map((patient) => _buildRecoveryItem(
                name: patient['name'] as String,
                procedure: patient['procedure'] as String,
                day: patient['day'] as String,
                progress: patient['progress'] as double,
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
