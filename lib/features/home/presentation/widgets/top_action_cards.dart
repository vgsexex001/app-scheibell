import 'package:flutter/material.dart';

/// Widget com os cards de ação do topo (Diário Pós-Op e Fotos)
class TopActionCards extends StatelessWidget {
  final VoidCallback? onDiarioTap;
  final VoidCallback? onFotosTap;
  final bool diarioEnabled;
  final bool fotosEnabled;

  const TopActionCards({
    super.key,
    this.onDiarioTap,
    this.onFotosTap,
    this.diarioEnabled = false,
    this.fotosEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Card Diário Pós-Op
        Expanded(
          child: _ActionCard(
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFF5C6BC0),
            iconBgColor: const Color(0xFFE8EAF6),
            title: 'Diário Pós-Op',
            subtitle: diarioEnabled ? 'Registrar' : 'Em breve',
            enabled: diarioEnabled,
            onTap: diarioEnabled ? onDiarioTap : null,
          ),
        ),
        const SizedBox(width: 12),
        // Card Fotos
        Expanded(
          child: _ActionCard(
            icon: Icons.camera_alt_rounded,
            iconColor: const Color(0xFF26A69A),
            iconBgColor: const Color(0xFFE0F2F1),
            title: 'Fotos',
            subtitle: fotosEnabled ? 'Enviar foto' : 'Em breve',
            enabled: fotosEnabled,
            onTap: fotosEnabled ? onFotosTap : null,
          ),
        ),
      ],
    );
  }
}

/// Card de ação individual
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: enabled,
      label: '$title, $subtitle',
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFE5E5E5)
                  : const Color(0xFFE5E5E5).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Ícone
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: enabled
                                ? iconBgColor
                                : iconBgColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: enabled
                                ? iconColor
                                : iconColor.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        // Badge "Em breve" se desabilitado
                        if (!enabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3EF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Em breve',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Título
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? const Color(0xFF212621)
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Subtítulo
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled
                            ? const Color(0xFF697282)
                            : const Color(0xFFBDBDBD),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
