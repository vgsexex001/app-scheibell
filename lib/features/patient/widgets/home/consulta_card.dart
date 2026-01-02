import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card para exibir uma consulta agendada
class ConsultaCard extends StatelessWidget {
  final String titulo;
  final String data;
  final String medico;
  final String status;
  final bool isConfirmado;
  final VoidCallback? onTap;

  const ConsultaCard({
    super.key,
    required this.titulo,
    required this.data,
    required this.medico,
    required this.status,
    required this.isConfirmado,
    this.onTap,
  });

  static const _textPrimary = Color(0xFF212621);
  static const _primaryDark = Color(0xFF4F4A34);
  static const _gradientStart = Color(0xFFA49E86);
  static const _cardBorder = Color(0xFFC8C2B4);
  static const _successColor = Color(0xFF4CAF50);
  static const _errorColor = Color(0xFFEB1111);

  /// Formata data da consulta a partir de string ISO e horário
  static String formatarDataConsulta(String dateStr, String time) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('d MMM', 'pt_BR');
      return '${formatter.format(date)} às $time';
    } catch (e) {
      return '$dateStr às $time';
    }
  }

  /// Traduz tipo de consulta do backend
  static String traduzirTipo(String type) {
    const tipos = {
      'RETURN_VISIT': 'Retorno',
      'EVALUATION': 'Avaliação',
      'PHYSIOTHERAPY': 'Fisioterapia',
      'EXAM': 'Exame',
      'OTHER': 'Outro',
    };
    return tipos[type] ?? type;
  }

  /// Traduz status da consulta
  static String traduzirStatus(String status) {
    const statusMap = {
      'PENDING': 'Pendente',
      'CONFIRMED': 'Confirmado',
      'CANCELLED': 'Cancelado',
      'COMPLETED': 'Realizado',
    };
    return statusMap[status] ?? status;
  }

  /// Verifica se status indica confirmação
  static bool isStatusConfirmado(String status) {
    return status == 'CONFIRMED' || status == 'COMPLETED';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Consulta $titulo em $data com $medico, status $status',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _cardBorder, width: 1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19212621),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_gradientStart, _primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: _primaryDark,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data,
                          style: const TextStyle(
                            color: _primaryDark,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      medico,
                      style: const TextStyle(
                        color: _primaryDark,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Badge de status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isConfirmado ? _successColor : _errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
