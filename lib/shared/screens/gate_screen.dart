import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/branding_provider.dart';
import '../../core/models/user_model.dart';

class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  Future<void> _checkAuthAndRedirect() async {
    final authProvider = context.read<AuthProvider>();

    // Check authentication status
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Load clinic branding if user has a clinic
      if (authProvider.user!.clinicId != null) {
        final brandingProvider = context.read<BrandingProvider>();
        await brandingProvider.loadClinicBranding(authProvider.user!.clinicId!);
      }

      if (!mounted) return;

      // Redirect based on user role
      _redirectBasedOnRole(authProvider.user!.role);
    } else {
      // Not authenticated, go to login
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _redirectBasedOnRole(UserRole role) {
    String route;

    switch (role) {
      case UserRole.patient:
        route = '/home';
        break;
      case UserRole.clinicAdmin:
      case UserRole.clinicStaff:
        route = '/clinic-dashboard';
        break;
      case UserRole.thirdParty:
        route = '/third-party-home';
        break;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFA49E86),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'App Scheibell',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA49E86)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Carregando...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6B6B),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
