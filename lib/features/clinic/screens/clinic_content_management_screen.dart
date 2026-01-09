import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinic_content_provider.dart';

class ClinicContentManagementScreen extends StatefulWidget {
  const ClinicContentManagementScreen({super.key});

  @override
  State<ClinicContentManagementScreen> createState() =>
      _ClinicContentManagementScreenState();
}

class _ClinicContentManagementScreenState
    extends State<ClinicContentManagementScreen> {
  final int _selectedNavIndex = 3; // Conteúdos tab

  @override
  void initState() {
    super.initState();
    // Carregar estatísticas ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicContentProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7D1C5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Módulos de Conteúdo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContentGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF212621),
            Color(0xFF4F4A34),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Gestão de Conteúdos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gerencie os conteúdos disponíveis para seus pacientes',
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid() {
    final provider = context.watch<ClinicContentProvider>();
    final stats = provider.stats;

    final modules = [
      {
        'icon': Icons.thermostat_outlined,
        'title': 'Sintomas',
        'description': 'Monitoramento de sintomas pós-operatórios',
        'count': stats?.getCount('SYMPTOMS') ?? 0,
        'color': const Color(0xFFE53935),
        'route': '/clinic-symptoms',
        'type': 'SYMPTOMS',
      },
      {
        'icon': Icons.restaurant_outlined,
        'title': 'Dieta',
        'description': 'Orientações nutricionais e alimentares',
        'count': stats?.getCount('DIET') ?? 0,
        'color': const Color(0xFF4CAF50),
        'route': '/clinic-diet',
        'type': 'DIET',
      },
      {
        'icon': Icons.directions_run_outlined,
        'title': 'Atividades',
        'description': 'Restrições e permissões de atividades',
        'count': stats?.getCount('ACTIVITIES') ?? 0,
        'color': const Color(0xFF2196F3),
        'route': '/clinic-activities',
        'type': 'ACTIVITIES',
      },
      {
        'icon': Icons.medical_services_outlined,
        'title': 'Cuidados',
        'description': 'Cuidados com curativos e higiene',
        'count': stats?.getCount('CARE') ?? 0,
        'color': const Color(0xFF9C27B0),
        'route': '/clinic-care',
        'type': 'CARE',
      },
      {
        'icon': Icons.fitness_center_outlined,
        'title': 'Treino',
        'description': 'Exercícios de reabilitação',
        'count': stats?.getCount('TRAINING') ?? 0,
        'color': const Color(0xFFFF9800),
        'route': '/clinic-training',
        'type': 'TRAINING',
      },
      {
        'icon': Icons.science_outlined,
        'title': 'Exames',
        'description': 'Exames necessários no pós-operatório',
        'count': stats?.getCount('EXAMS') ?? 0,
        'color': const Color(0xFF00BCD4),
        'route': '/clinic-exams',
        'type': 'EXAMS',
      },
      {
        'icon': Icons.folder_outlined,
        'title': 'Documentos',
        'description': 'Termos e documentos importantes',
        'count': stats?.getCount('DOCUMENTS') ?? 0,
        'color': const Color(0xFF795548),
        'route': '/clinic-documents',
        'type': 'DOCUMENTS',
      },
      {
        'icon': Icons.medication_outlined,
        'title': 'Medicações',
        'description': 'Protocolos de medicação',
        'count': stats?.getCount('MEDICATIONS') ?? 0,
        'color': const Color(0xFFE91E63),
        'route': '/clinic-medications',
        'type': 'MEDICATIONS',
      },
      {
        'icon': Icons.book_outlined,
        'title': 'Diário',
        'description': 'Em breve',
        'count': stats?.getCount('DIARY') ?? 0,
        'color': const Color(0xFF9CA3AF),
        'route': null,
        'comingSoon': true,
        'type': 'DIARY',
      },
    ];

    // Mostrar indicador de loading enquanto carrega stats
    if (provider.isLoadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: Color(0xFFA49E86),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: modules.map((module) => _buildModuleCard(
        icon: module['icon'] as IconData,
        title: module['title'] as String,
        description: module['description'] as String,
        count: module['count'] as int,
        color: module['color'] as Color,
        route: module['route'] as String?,
        comingSoon: module['comingSoon'] as bool? ?? false,
      )).toList(),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String description,
    required int count,
    required Color color,
    String? route,
    bool comingSoon = false,
  }) {
    final cardWidth = (MediaQuery.of(context).size.width - 52) / 2;

    return GestureDetector(
      onTap: () {
        if (comingSoon) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionalidade em breve!'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Container(
        width: cardWidth,
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: comingSoon ? const Color(0xFFF5F4F2) : Colors.white,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: comingSoon ? const Color(0xFFE5E7EB) : const Color(0xFFF5F4F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (comingSoon) ...[
                        const Icon(Icons.access_time_outlined, size: 12, color: Color(0xFF6B6B6B)),
                        const SizedBox(width: 4),
                        const Text(
                          'Em breve',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B6B6B),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ] else
                        Text(
                          '$count itens',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B6B6B),
                            fontFamily: 'Inter',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: comingSoon ? const Color(0xFF6B6B6B) : const Color(0xFF1A1A1A),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                  fontFamily: 'Inter',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
        Navigator.pushReplacementNamed(context, '/clinic-patients');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/clinic-chat');
        break;
      case 3:
        // Already on content management
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/clinic-calendar');
        break;
    }
  }
}
