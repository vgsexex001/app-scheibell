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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Durante logout, mostra loading e não redireciona
        if (authProvider.isLoggingOut) {
          debugPrint('[ROLE_GUARD] Logout em progresso - mostrando loading');
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA49E86)),
            ),
          );
        }

        // Se não autenticado e ainda não redirecionou
        if (!authProvider.isAuthenticated || authProvider.user == null) {
          if (!_hasRedirected && widget.redirectRoute != null) {
            _hasRedirected = true;
            debugPrint('[ROLE_GUARD] Não autenticado - redirecionando para ${widget.redirectRoute}');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(widget.redirectRoute!);
              }
            });
          }
          return widget.fallback ?? const _AccessDeniedScreen();
        }

        // NÃO resetar _hasRedirected aqui!
        // A flag será resetada apenas quando widget for recriado
        // Isso evita redirects duplicados durante rebuilds do Consumer

        // Check if user has allowed role
        if (!widget.allowedRoles.contains(authProvider.user!.role)) {
          if (widget.redirectRoute != null) {
            debugPrint('[ROLE_GUARD] Role não permitido - redirecionando');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(widget.redirectRoute!);
              }
            });
          }
          return widget.fallback ?? const _AccessDeniedScreen();
        }

        return widget.child;
      },
    );
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
