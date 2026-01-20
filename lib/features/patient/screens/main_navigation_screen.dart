import 'package:flutter/material.dart';
import 'tela_home.dart';
import 'tela_chatbot.dart';
import 'tela_recuperacao.dart';
import 'tela_agendar.dart';
import 'tela_perfil.dart';

/// Tela principal com navegacao por tabs usando IndexedStack
/// Mantem o estado de todas as telas ao navegar entre elas
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Cores
  static const _backgroundColor = Color(0xFFF5F7FA);
  static const _primaryDark = Color(0xFF4F4A34);
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);
  static const _navInactive = Color(0xFF697282);

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          // Tab 0: Home - usa TelaHome diretamente
          TelaHome(),
          // Tab 1: Chatbot
          TelaChatbot(),
          // Tab 2: Recuperacao
          TelaRecuperacao(),
          // Tab 3: Agenda (tela de selecao de tipo de agendamento)
          TelaAgendar(),
          // Tab 4: Perfil
          TelaPerfil(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Inicio'),
              _buildNavItem(1, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
              _buildNavItem(2, Icons.favorite_outline, Icons.favorite, 'Recuperacao'),
              _buildNavItem(3, Icons.calendar_today_outlined, Icons.calendar_today, 'Agenda'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? _gradientStart.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? _primaryDark : _navInactive,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _primaryDark : _navInactive,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
