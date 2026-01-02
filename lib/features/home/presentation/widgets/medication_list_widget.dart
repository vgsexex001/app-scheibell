import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';

/// Widget de lista de medicações com accordion expandível
class MedicationListWidget extends StatelessWidget {
  final List<Medication> medications;
  final int dosesTaken;
  final int dosesTotal;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Function(String medicationId, String doseId)? onToggleDose;

  const MedicationListWidget({
    super.key,
    required this.medications,
    required this.dosesTaken,
    required this.dosesTotal,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onToggleDose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da seção
        _buildSectionHeader(context),
        const SizedBox(height: 12),

        // Conteúdo
        if (isLoading)
          _buildLoadingSkeleton()
        else if (errorMessage != null)
          _buildError(context)
        else if (medications.isEmpty)
          _buildEmpty(context)
        else
          _buildMedicationList(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        // Ícone
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5EB),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.medication_outlined,
            color: Color(0xFF4A7C4E),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Título
        const Expanded(
          child: Text(
            'Remédios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212621),
            ),
          ),
        ),
        // Badge contador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: dosesTaken == dosesTotal && dosesTotal > 0
                ? const Color(0xFF4A7C4E)
                : const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$dosesTaken/$dosesTotal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dosesTaken == dosesTotal && dosesTotal > 0
                  ? Colors.white
                  : const Color(0xFF4F4A34),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFE53935),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Erro ao carregar remédios',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF212621),
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            color: Colors.grey[400],
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum remédio cadastrado para hoje',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF697282),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Conforme prescrição médica',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(BuildContext context) {
    return Column(
      children: medications.map((medication) {
        return _MedicationCard(
          medication: medication,
          onToggleDose: onToggleDose,
        );
      }).toList(),
    );
  }
}

/// Card individual de medicação com accordion
class _MedicationCard extends StatefulWidget {
  final Medication medication;
  final Function(String medicationId, String doseId)? onToggleDose;

  const _MedicationCard({
    required this.medication,
    this.onToggleDose,
  });

  @override
  State<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<_MedicationCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medication;
    final allTaken = med.allDosesTaken;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allTaken
              ? const Color(0xFF4A7C4E).withValues(alpha: 0.3)
              : const Color(0xFFE5E5E5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header do card (sempre visível)
          Semantics(
            button: true,
            label: '${med.name}, ${med.dosesTakenToday} de ${med.totalDosesToday} doses tomadas. Toque para expandir.',
            child: InkWell(
              onTap: _toggleExpand,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Checkbox visual
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: allTaken
                            ? const Color(0xFF4A7C4E)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: allTaken
                              ? const Color(0xFF4A7C4E)
                              : const Color(0xFFCBCBCB),
                          width: 2,
                        ),
                      ),
                      child: allTaken
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Info da medicação
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF212621),
                              decoration: allTaken
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _buildSubtitle(med),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF697282),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de doses
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: allTaken
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${med.dosesTakenToday}/${med.totalDosesToday}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: allTaken
                              ? const Color(0xFF4A7C4E)
                              : const Color(0xFF697282),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Ícone de expansão
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conteúdo expandido
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info adicional
                      if (med.dosage != null || med.frequency != null)
                        _buildInfoRow(
                          Icons.info_outline,
                          '${med.dosage ?? ''} ${med.frequency != null ? '- ${med.frequency}' : ''}'
                              .trim(),
                        ),
                      if (med.instructions != null &&
                          med.instructions!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildInfoRow(
                            Icons.notes,
                            med.instructions!,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Lista de doses/horários
                      const Text(
                        'Horários de hoje:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F4A34),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...med.doses.map((dose) => _buildDoseItem(dose)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(Medication med) {
    final parts = <String>[];
    if (med.dosage != null) parts.add(med.dosage!);
    if (med.frequency != null) parts.add(med.frequency!);
    if (parts.isEmpty && med.instructions != null) {
      return med.instructions!.length > 50
          ? '${med.instructions!.substring(0, 50)}...'
          : med.instructions!;
    }
    return parts.join(' - ');
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF697282),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4F4A34),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoseItem(MedicationDose dose) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: 'Dose das ${dose.time}, ${dose.taken ? 'tomada' : 'não tomada'}',
        child: InkWell(
          onTap: () {
            widget.onToggleDose?.call(widget.medication.id, dose.id);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: dose.taken
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    dose.taken ? const Color(0xFFA5D6A7) : const Color(0xFFE0E0E0),
              ),
            ),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: dose.taken
                        ? const Color(0xFF4A7C4E)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: dose.taken
                          ? const Color(0xFF4A7C4E)
                          : const Color(0xFFBDBDBD),
                      width: 2,
                    ),
                  ),
                  child: dose.taken
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Horário
                Text(
                  dose.time,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: dose.taken
                        ? const Color(0xFF4A7C4E)
                        : const Color(0xFF212621),
                  ),
                ),
                const Spacer(),
                // Status
                if (dose.taken)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF4A7C4E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tomado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Toque para marcar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
