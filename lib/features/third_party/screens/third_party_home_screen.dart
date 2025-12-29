import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/branding_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../widgets/third_party_bottom_nav.dart';

class ThirdPartyHomeScreen extends StatefulWidget {
  const ThirdPartyHomeScreen({super.key});

  @override
  State<ThirdPartyHomeScreen> createState() => _ThirdPartyHomeScreenState();
}

class _ThirdPartyHomeScreenState extends State<ThirdPartyHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final brandingProvider = context.watch<BrandingProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: brandingProvider.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderWithAvatar(
              greeting: _getGreeting(),
              userName: user?.name ?? 'Parceiro',
              avatarUrl: user?.avatarUrl,
              onAvatarTap: () {},
              onNotificationTap: () {},
              notificationCount: 0,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildWelcomeCard(brandingProvider),
                    const SizedBox(height: 24),
                    _buildIndicatorsRow(brandingProvider),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Tarefas Pendentes'),
                    const SizedBox(height: 12),
                    _buildPendingTasks(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Agenda de Visitas'),
                    const SizedBox(height: 12),
                    _buildVisitsSchedule(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ThirdPartyBottomNav(currentIndex: 0),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _buildWelcomeCard(BrandingProvider brandingProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brandingProvider.primaryColor,
            brandingProvider.primaryColor.withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portal do Parceiro',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Acesse informações e gerencie suas tarefas relacionadas aos pacientes da clínica.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(204),
              fontFamily: 'Inter',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsRow(BrandingProvider brandingProvider) {
    return Row(
      children: [
        Expanded(
          child: CompactIndicatorCard(
            title: 'Tarefas Hoje',
            value: '5',
            icon: Icons.task_alt_outlined,
            iconColor: brandingProvider.primaryColor,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CompactIndicatorCard(
            title: 'Visitas',
            value: '2',
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF4CAF50),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildPendingTasks() {
    // Mock data
    final tasks = [
      {
        'title': 'Entregar material para Maria Silva',
        'type': 'Entrega',
        'priority': 'alta',
      },
      {
        'title': 'Coletar documentos de João Santos',
        'type': 'Coleta',
        'priority': 'média',
      },
      {
        'title': 'Agendar visita com Ana Oliveira',
        'type': 'Agendamento',
        'priority': 'baixa',
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
          ...tasks.map((task) => _buildTaskItem(
                title: task['title']!,
                type: task['type']!,
                priority: task['priority']!,
              )),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String type,
    required String priority,
  }) {
    Color priorityColor;
    switch (priority) {
      case 'alta':
        priorityColor = const Color(0xFFE53935);
        break;
      case 'média':
        priorityColor = const Color(0xFFFF9800);
        break;
      default:
        priorityColor = const Color(0xFF4CAF50);
    }

    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withAlpha(31),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F4F2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B6B6B),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: false,
              onChanged: (value) {},
              activeColor: const Color(0xFFA49E86),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitsSchedule() {
    // Mock data
    final visits = [
      {
        'patient': 'Maria Silva',
        'address': 'Rua das Flores, 123',
        'time': '14:00',
      },
      {
        'patient': 'João Santos',
        'address': 'Av. Brasil, 456',
        'time': '16:30',
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
          ...visits.map((visit) => _buildVisitItem(
                patient: visit['patient']!,
                address: visit['address']!,
                time: visit['time']!,
              )),
        ],
      ),
    );
  }

  Widget _buildVisitItem({
    required String patient,
    required String address,
    required String time,
  }) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withAlpha(31),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFA49E86).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFA49E86),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: Color(0xFF6B6B6B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B6B6B),
                            fontFamily: 'Inter',
                          ),
                          overflow: TextOverflow.ellipsis,
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
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Hoje',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                      fontFamily: 'Inter',
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

}
