import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class RoleGuard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated || authProvider.user == null) {
          if (redirectRoute != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(redirectRoute!);
            });
          }
          return fallback ?? const _AccessDeniedScreen();
        }

        // Check if user has allowed role
        if (!allowedRoles.contains(authProvider.user!.role)) {
          if (redirectRoute != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(redirectRoute!);
            });
          }
          return fallback ?? const _AccessDeniedScreen();
        }

        return child;
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
