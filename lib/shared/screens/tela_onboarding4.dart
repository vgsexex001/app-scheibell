import 'package:flutter/material.dart';
import '../../core/services/secure_storage_service.dart';

class TelaOnboarding4 extends StatelessWidget {
  const TelaOnboarding4({super.key});

  // Constantes de cores para reutilização
  static const _backgroundColor = Color(0xFFA9A48E);
  static const _primaryDark = Color(0xFF4F4A34);
  static const _cardBackground = Color(0xFFF5F7FA);

  Future<void> _completeOnboarding(BuildContext context) async {
    final secureStorage = SecureStorageService();
    await secureStorage.setOnboardingCompleted();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _backgroundColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/onboarding_screen04.png'),
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.3),
            colorFilter: ColorFilter.mode(
              Colors.grey.withValues(alpha: 0.15),
              BlendMode.saturation,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            child: Column(
              children: [
                _buildSkipButton(context),
                SizedBox(height: isSmallScreen ? 4 : 6),
                _buildTitle(size),
                SizedBox(height: isSmallScreen ? 2 : 4),
                _buildSubtitle(size),
                const Spacer(),
                _buildOptionCard(
                  icon: Icons.calendar_today,
                  text: 'Sincronizar calendário',
                  size: size,
                  onPressed: () {},
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                _buildOptionCard(
                  icon: Icons.chat,
                  text: 'Conectar o WhatsApp',
                  size: size,
                  onPressed: () {},
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                _buildOptionCard(
                  icon: Icons.notifications,
                  text: 'Ativar as notificações',
                  size: size,
                  onPressed: () {},
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildNavigationButtons(context, size),
                SizedBox(height: isSmallScreen ? 20 : 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton(
          onPressed: () => _completeOnboarding(context),
          child: const Text(
            'Pular',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(color: Colors.black45, blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(Size size) {
    return Text(
      'Notificações nos momentos certos',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: (size.width * 0.07).clamp(24.0, 32.0),
        fontWeight: FontWeight.w600,
        height: 1.2,
        shadows: const [
          Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    );
  }

  Widget _buildSubtitle(Size size) {
    return Text(
      'Nunca perca uma medicação ou consulta importante',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFF3A3627),
        fontSize: (size.width * 0.038).clamp(13.0, 16.0),
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, Size size) {
    final buttonHeight = (size.height * 0.065).clamp(48.0, 56.0);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: OutlinedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding3'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.grey, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Anterior',
                style: TextStyle(
                  fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () => _completeOnboarding(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Começar',
                style: TextStyle(
                  fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String text,
    required Size size,
    required VoidCallback onPressed,
  }) {
    final isSmallScreen = size.height < 700;
    final cardPadding = isSmallScreen ? 8.0 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: cardPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: (size.width * 0.055).clamp(20.0, 24.0),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: (size.width * 0.035).clamp(13.0, 15.0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: (size.height * 0.04).clamp(30.0, 36.0),
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryDark,
                backgroundColor: _cardBackground,
                side: const BorderSide(color: _primaryDark, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.035),
              ),
              child: Text(
                'Conectar',
                style: TextStyle(
                  fontSize: (size.width * 0.03).clamp(11.0, 13.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
