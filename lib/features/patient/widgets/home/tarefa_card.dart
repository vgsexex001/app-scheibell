import 'package:flutter/material.dart';

/// Card para exibir tarefa/medicação/cuidado
class TarefaCard extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final String? horario;
  final String? badge;
  final bool concluido;
  final Color borderColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  const TarefaCard({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.horario,
    this.badge,
    this.concluido = false,
    this.borderColor = const Color(0xFFCBC5B6),
    this.trailing,
    this.onTap,
    this.onToggle,
  });

  static const _primaryDark = Color(0xFF4F4A34);
  static const _textSecondary = Color(0xFF757575);
  static const _taskCardBg = Color(0xFFF2F5FC);
  static const _taskBorder = Color(0xFFCBC5B6);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: titulo,
      hint: concluido ? 'Concluído' : 'Pendente',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _taskCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(width: 4, color: borderColor),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: concluido ? _primaryDark : const Color(0xFFDEE6EA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: 2,
                      color: concluido ? _primaryDark : _taskBorder,
                    ),
                  ),
                  child: concluido
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: _taskCardBg,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            titulo,
                            style: TextStyle(
                              fontSize: 16,
                              color: concluido
                                  ? _textSecondary
                                  : const Color(0xFF1A1A1A),
                              decoration:
                                  concluido ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _taskBorder,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (horario != null)
                      Text(
                        horario!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    if (subtitulo != null)
                      Text(
                        subtitulo!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Trailing widget
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Header de seção com ícone, título e badge
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String titulo;
  final String badge;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.titulo,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFC9C3B4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }
}
