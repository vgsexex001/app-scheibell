import 'package:flutter/material.dart';

/// Card para ação rápida na Home
class AcaoRapidaCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final bool emBreve;

  const AcaoRapidaCard({
    super.key,
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.gradientColors,
    this.onTap,
    this.emBreve = false,
  });

  static const _textPrimary = Color(0xFF212621);
  static const _primaryDark = Color(0xFF4F4A34);
  static const _cardBackground = Color(0xFFF5F3EF);
  static const _emBreveGray = Color(0xFFBDBDBD);
  static const _emBreveBgGray = Color(0xFFE0E0E0);
  static const _emBreveTextGray = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !emBreve && onTap != null,
      label: emBreve ? '$titulo - Em breve' : titulo,
      hint: subtitulo,
      child: GestureDetector(
        onTap: emBreve ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: emBreve ? _emBreveBgGray : _cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: emBreve
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                      color: emBreve ? _emBreveGray : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  // Badge "Em breve"
                  if (emBreve)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _emBreveGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Em breve',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Título
              Text(
                titulo,
                style: TextStyle(
                  color: emBreve ? _emBreveTextGray : _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              // Subtítulo
              Text(
                subtitulo,
                style: TextStyle(
                  color: emBreve ? _emBreveTextGray : _primaryDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
