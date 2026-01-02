import 'package:flutter/material.dart';

/// Widget para exibir estado de erro na tela Home
/// Mostra mensagem de erro e botão para tentar novamente
class HomeError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const HomeError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  static const _primaryDark = Color(0xFF4F4A34);
  static const _errorColor = Color(0xFFDE3737);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        left: 32,
        right: 32,
        bottom: 32,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone de erro
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: _errorColor,
            ),
          ),
          const SizedBox(height: 24),

          // Título
          const Text(
            'Ops! Algo deu errado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryDark,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Mensagem de erro
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryDark.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Botão tentar novamente
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botão verificar conexão
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Verifique sua conexão com a internet',
                  ),
                  backgroundColor: _primaryDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(
              'Verificar conexão',
              style: TextStyle(
                color: _primaryDark.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
