import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/branding_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/services/secure_storage_service.dart';

class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  // Mutex flags para garantir execução única
  bool _isInitialized = false;
  bool _hasNavigated = false;
  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    debugPrint('[GATE] initState');

    // Verificar auth após primeiro frame (UMA VEZ)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  @override
  void dispose() {
    debugPrint('[GATE] dispose');
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    // Mutex: só executa uma vez
    if (_isInitialized) {
      debugPrint('[GATE] _initializeAuth ignorado - já inicializado');
      return;
    }
    _isInitialized = true;
    debugPrint('[GATE] _initializeAuth iniciando');

    final authProvider = context.read<AuthProvider>();

    // Verifica status de autenticação
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    // Navega baseado no resultado
    _handleAuthResult(authProvider);
  }

  void _handleAuthResult(AuthProvider authProvider) {
    // Mutex: só navega uma vez
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    debugPrint('[GATE] _handleAuthResult - isAuthenticated: ${authProvider.isAuthenticated}');

    if (authProvider.isAuthenticated && authProvider.user != null) {
      _loadBrandingAndRedirect(authProvider.user!);
    } else {
      // Não autenticado - vai para tela de Welcome/Login
      _navigateToLogin();
    }
  }

  Future<void> _loadBrandingAndRedirect(UserModel user) async {
    // Carrega branding da clínica se necessário
    if (user.clinicId != null) {
      final brandingProvider = context.read<BrandingProvider>();
      await brandingProvider.loadClinicBranding(user.clinicId!);
    }

    if (!mounted) return;

    // Inicializa ProgressProvider para pacientes
    if (user.role == UserRole.patient) {
      final progressProvider = context.read<ProgressProvider>();
      progressProvider.initialize(user.surgeryDate, user.createdAt);
      debugPrint('[GATE] ProgressProvider inicializado - dias: ${progressProvider.daysSinceStart}, semana: ${progressProvider.currentWeek}');
    }

    if (!mounted) return;

    // Se é paciente, verifica se precisa mostrar onboarding
    if (user.role == UserRole.patient) {
      final isOnboardingCompleted = await _secureStorage.isOnboardingCompleted();
      debugPrint('[GATE] Onboarding completado: $isOnboardingCompleted');

      if (!isOnboardingCompleted) {
        // Paciente logado mas ainda não viu onboarding
        _navigateToOnboarding();
        return;
      }
    }

    _redirectBasedOnRole(user.role);
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

    debugPrint('[GATE] Navegando para: $route');
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _navigateToLogin() {
    debugPrint('[GATE] Navegando para login (Welcome)');
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _navigateToOnboarding() {
    debugPrint('[GATE] Navegando para onboarding (paciente logado)');
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[GATE] build');

    // Build SIMPLES - sem Consumer, sem callbacks no build
    // A lógica de navegação está em initState/callback
    return const Scaffold(
      backgroundColor: Color(0xFFFAF9F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LogoWidget(),
            SizedBox(height: 32),
            Text(
              'App Scheibell',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA49E86)),
            ),
            SizedBox(height: 16),
            Text(
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

class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
