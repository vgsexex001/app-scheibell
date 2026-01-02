import 'package:flutter/material.dart';

/// Widget para exibir estado vazio na tela Home
/// Mostra ilustração e CTAs para adicionar conteúdo
class HomeEmpty extends StatelessWidget {
  final VoidCallback? onAddMedicacao;
  final VoidCallback? onAddConsulta;

  const HomeEmpty({
    super.key,
    this.onAddMedicacao,
    this.onAddConsulta,
  });

  static const _primaryDark = Color(0xFF4F4A34);
  static const _gradientStart = Color(0xFFA49E86);
  static const _gradientEnd = Color(0xFFD7D1C5);

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
          // Ilustração
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _gradientStart.withValues(alpha: 0.3),
                  _gradientEnd.withValues(alpha: 0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 56,
              color: _primaryDark,
            ),
          ),
          const SizedBox(height: 32),

          // Título
          const Text(
            'Bem-vindo ao seu painel',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryDark,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Descrição
          Text(
            'Seu painel está vazio. Comece adicionando suas medicações e consultas para acompanhar sua recuperação.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryDark.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // CTAs
          if (onAddMedicacao != null || onAddConsulta != null)
            Column(
              children: [
                if (onAddMedicacao != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAddMedicacao,
                      icon: const Icon(Icons.medication_rounded),
                      label: const Text('Adicionar Medicação'),
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
                if (onAddMedicacao != null && onAddConsulta != null)
                  const SizedBox(height: 12),
                if (onAddConsulta != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAddConsulta,
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: const Text('Agendar Consulta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryDark,
                        side: const BorderSide(color: _primaryDark, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 24),

          // Dica
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _gradientEnd.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: _primaryDark.withValues(alpha: 0.7),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dica: Mantenha suas informações atualizadas para um melhor acompanhamento.',
                    style: TextStyle(
                      color: _primaryDark.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
