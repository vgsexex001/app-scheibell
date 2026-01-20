import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class RoleGuard extends StatefulWidget {
  final Widget child;
  final List<UserRole> allowedRoles;
  final Widget? fallback;
  final String? redirectRoute;

  const RoleGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.fallback,
    this.redirectRoute,
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _hasRedirected = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    // Verificação única após build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccess();
    });
  }

  void _checkAccess() {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Durante loading inicial ou logout, aguarda
    if (authProvider.isLoading || authProvider.isLoggingOut) {
      // Aguarda o status mudar
      Future.delayed(const Duration(milliseconds: 100), _checkAccess);
      return;
    }

    setState(() => _isChecking = false);

    // Se não autenticado, redireciona
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      if (!_hasRedirected && widget.redirectRoute != null) {
        _hasRedirected = true;
        debugPrint('[ROLE_GUARD] Não autenticado - redirecionando para ${widget.redirectRoute}');
        Navigator.of(context).pushReplacementNamed(widget.redirectRoute!);
      }
      return;
    }

    // Se role não permitido, redireciona
    if (!widget.allowedRoles.contains(authProvider.user!.role)) {
      if (!_hasRedirected && widget.redirectRoute != null) {
        _hasRedirected = true;
        debugPrint('[ROLE_GUARD] Role ${authProvider.user!.role} não permitido - redirecionando');
        Navigator.of(context).pushReplacementNamed(widget.redirectRoute!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostra loading enquanto verifica
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF9F7),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA49E86)),
          ),
        ),
      );
    }

    final authProvider = context.watch<AuthProvider>();

    // Durante logout, mostra loading
    if (authProvider.isLoggingOut) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF9F7),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA49E86)),
          ),
        ),
      );
    }

    // Se autenticado e role permitido, mostra child
    if (authProvider.isAuthenticated &&
        authProvider.user != null &&
        widget.allowedRoles.contains(authProvider.user!.role)) {
      return widget.child;
    }

    // Fallback enquanto redireciona
    return widget.fallback ?? const _AccessDeniedScreen();
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Color(0xFFA49E86),
              ),
              const SizedBox(height: 24),
              const Text(
                'Acesso Negado',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Você não tem permissão para acessar esta página.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B6B6B),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/gate');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA49E86),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Voltar ao Início',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for patient-only routes
class PatientGuard extends StatelessWidget {
  final Widget child;

  const PatientGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const [UserRole.patient],
      redirectRoute: '/gate',
      child: child,
    );
  }
}

// Helper widget for clinic staff routes
class ClinicGuard extends StatelessWidget {
  final Widget child;

  const ClinicGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const [UserRole.clinicAdmin, UserRole.clinicStaff],
      redirectRoute: '/gate',
      child: child,
    );
  }
}

// Helper widget for clinic admin only routes
class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const [UserRole.clinicAdmin],
      redirectRoute: '/gate',
      child: child,
    );
  }
}

// Helper widget for third party routes
class ThirdPartyGuard extends StatelessWidget {
  final Widget child;

  const ThirdPartyGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const [UserRole.thirdParty],
      redirectRoute: '/gate',
      child: child,
    );
  }
}
