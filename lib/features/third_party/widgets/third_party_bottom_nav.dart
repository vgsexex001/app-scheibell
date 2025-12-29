import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class ThirdPartyBottomNav extends StatelessWidget {
  final int currentIndex;

  const ThirdPartyBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
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
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Início',
                route: AppRoutes.thirdPartyHome,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Chat',
                route: AppRoutes.thirdPartyChat,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.task_alt_outlined,
                activeIcon: Icons.task_alt,
                label: 'Tarefas',
                route: AppRoutes.thirdPartyTasks,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Perfil',
                route: AppRoutes.thirdPartyProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    String? route,
  }) {
    final isSelected = currentIndex == index;
    const primaryColor = Color(0xFF4F4A34);

    return GestureDetector(
      onTap: () {
        if (isSelected) return;

        if (route != null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            route,
            (r) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarefas em breve!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : const Color(0xFF6B6B6B),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : const Color(0xFF6B6B6B),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
