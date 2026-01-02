import 'package:flutter/material.dart';

/// Card para exibir o Score de Saúde
class ScoreCard extends StatelessWidget {
  final double score;
  final String mensagem;

  const ScoreCard({
    super.key,
    required this.score,
    required this.mensagem,
  });

  static const _textPrimary = Color(0xFF212621);
  static const _primaryDark = Color(0xFF4F4A34);
  static const _scoreBackground = Color(0xFFBDE3CA);
  static const _successColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Score de Saúde: ${score.toStringAsFixed(1)} de 10',
      hint: mensagem,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _scoreBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Score de Saúde',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Baseado na sua evolução',
                        style: TextStyle(
                          color: _primaryDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForScore(score),
                    color: _successColor,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Score
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    color: _primaryDark,
                    fontSize: 45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  '/10',
                  style: TextStyle(
                    color: _primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mensagem
            Text(
              mensagem,
              style: const TextStyle(
                color: _primaryDark,
                fontSize: 12,
              ),
            ),

            // Barra de progresso visual
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 10,
                backgroundColor: Colors.white.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForScore(score),
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForScore(double score) {
    if (score >= 8) return Icons.trending_up;
    if (score >= 5) return Icons.trending_flat;
    return Icons.trending_down;
  }

  Color _getColorForScore(double score) {
    if (score >= 8) return const Color(0xFF4CAF50);
    if (score >= 5) return const Color(0xFFF5A623);
    return const Color(0xFFDE3737);
  }
}
