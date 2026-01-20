import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/progress_provider.dart';
import '../../../../core/services/progress_service.dart';

/// Widget que exibe a timeline de recuperação na Home.
///
/// Mostra as fases D+1, D+7, D+30, D+90, D+180 com indicação visual
/// do status de cada fase (concluída, atual, bloqueada).
class HomeTimelineWidget extends StatelessWidget {
  const HomeTimelineWidget({super.key});

  // Cores
  static const _textPrimary = Color(0xFF212621);
  static const _cardBorder = Color(0xFFC8C2B4);

  // Cores de status
  static const _completedColor = Color(0xFF00C950);
  static const _currentColor = Color(0xFF008235);
  static const _lockedColor = Color(0xFF9CA3AF);
  static const _lockedBgColor = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sua Jornada',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Badge com dia atual
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _currentColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _currentColor.withValues(alpha:0.3)),
                    ),
                    child: Text(
                      'D+${provider.daysSinceStart}',
                      style: const TextStyle(
                        color: _currentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Timeline horizontal
              _buildTimeline(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeline(ProgressProvider provider) {
    final phases = provider.phasesWithStatus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < phases.length; i++) ...[
              _buildPhaseItem(phases[i], i == phases.length - 1),
              if (i < phases.length - 1) _buildConnector(phases[i].isUnlocked),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseItem(PhaseWithStatus phaseStatus, bool isLast) {
    final phase = phaseStatus.phase;
    final status = phaseStatus.status;

    // Determinar cores e ícone
    Color circleColor, textColor, bgColor;
    IconData icon;
    String? badgeText;
    Color? badgeBgColor, badgeTextColor;

    switch (status) {
      case PhaseStatus.completed:
        circleColor = _completedColor;
        textColor = _completedColor;
        bgColor = _completedColor.withValues(alpha:0.1);
        icon = Icons.check;
        break;
      case PhaseStatus.current:
        circleColor = _currentColor;
        textColor = _currentColor;
        bgColor = _currentColor.withValues(alpha:0.15);
        icon = Icons.star;
        badgeText = 'ATUAL';
        badgeBgColor = _currentColor;
        badgeTextColor = Colors.white;
        break;
      case PhaseStatus.locked:
        circleColor = _lockedColor;
        textColor = _lockedColor;
        bgColor = _lockedBgColor;
        icon = Icons.lock;
        if (phaseStatus.daysUntilUnlock > 0) {
          badgeText = 'em ${phaseStatus.daysUntilUnlock} dias';
          badgeBgColor = _lockedBgColor;
          badgeTextColor = _lockedColor;
        }
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Círculo com ícone
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: circleColor,
              width: status == PhaseStatus.current ? 2.5 : 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: circleColor,
            size: status == PhaseStatus.current ? 24 : 20,
          ),
        ),
        const SizedBox(height: 8),
        // Label D+X
        Text(
          phase.label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        // Título
        Text(
          phase.title,
          style: TextStyle(
            color: textColor.withValues(alpha:0.8),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Badge (se houver)
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          const SizedBox(height: 18), // Espaço equivalente ao badge
      ],
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 48), // Alinhar com os círculos
      decoration: BoxDecoration(
        color: isCompleted ? _completedColor : _lockedColor.withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// Widget compacto para exibir apenas a fase atual e próxima.
class HomeTimelineCompactWidget extends StatelessWidget {
  const HomeTimelineCompactWidget({super.key});

  static const _primaryDark = Color(0xFF4F4A34);
  static const _currentColor = Color(0xFF008235);
  static const _lockedColor = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) {
          return const SizedBox.shrink();
        }

        final currentPhase = provider.currentPhase;
        final nextPhase = provider.nextPhase;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _currentColor.withValues(alpha:0.1),
                  _currentColor.withValues(alpha:0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _currentColor.withValues(alpha:0.2)),
            ),
            child: Row(
              children: [
                // Ícone da fase atual
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.timeline,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Dia ${provider.daysSinceStart} ',
                            style: const TextStyle(
                              color: _primaryDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (currentPhase != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _currentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentPhase.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (nextPhase != null)
                        Text(
                          'Proxima fase (${nextPhase.label}) em ${provider.daysUntilPhaseUnlock(nextPhase.day)} dias',
                          style: TextStyle(
                            color: _lockedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      else
                        const Text(
                          'Todas as fases desbloqueadas!',
                          style: TextStyle(
                            color: _currentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Seta
                Icon(
                  Icons.arrow_forward_ios,
                  color: _currentColor.withValues(alpha:0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
