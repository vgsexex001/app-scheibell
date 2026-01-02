import 'package:flutter/material.dart';
import '../../domain/entities/care_item.dart';

/// Widget de lista de cuidados (checklist)
class CareListWidget extends StatelessWidget {
  final List<CareItem> careItems;
  final int completedCount;
  final int totalCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Function(String careId)? onToggle;

  const CareListWidget({
    super.key,
    required this.careItems,
    required this.completedCount,
    required this.totalCount,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onToggle,
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
        else if (careItems.isEmpty)
          _buildEmpty(context)
        else
          _buildCareList(context),
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
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.favorite_outline,
            color: Color(0xFFFFA000),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Título
        const Expanded(
          child: Text(
            'Cuidados',
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
            color: completedCount == totalCount && totalCount > 0
                ? const Color(0xFFFFA000)
                : const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$completedCount/$totalCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: completedCount == totalCount && totalCount > 0
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
                      width: 160,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
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
            errorMessage ?? 'Erro ao carregar cuidados',
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
            Icons.favorite_outline,
            color: Colors.grey[400],
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum cuidado para hoje',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF697282),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCareList(BuildContext context) {
    return Column(
      children: careItems.map((care) {
        return _CareCard(
          care: care,
          onToggle: onToggle,
        );
      }).toList(),
    );
  }
}

/// Card individual de cuidado
class _CareCard extends StatelessWidget {
  final CareItem care;
  final Function(String careId)? onToggle;

  const _CareCard({
    required this.care,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: care.completed
              ? const Color(0xFFFFA000).withValues(alpha: 0.3)
              : _getBorderColor(),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: '${care.title}, ${care.completed ? 'concluído' : 'não concluído'}',
        child: InkWell(
          onTap: () => onToggle?.call(care.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: care.completed
                        ? const Color(0xFFFFA000)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: care.completed
                          ? const Color(0xFFFFA000)
                          : const Color(0xFFCBCBCB),
                      width: 2,
                    ),
                  ),
                  child: care.completed
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        care.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF212621),
                          decoration:
                              care.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (care.description != null &&
                          care.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          care.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Indicador de categoria
                if (care.isWarning || care.isEmergency) ...[
                  const SizedBox(width: 8),
                  Icon(
                    care.isEmergency
                        ? Icons.warning_rounded
                        : Icons.info_outline,
                    size: 20,
                    color: care.isEmergency
                        ? const Color(0xFFE53935)
                        : const Color(0xFFFFA000),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (care.isEmergency) return const Color(0xFFFFCDD2);
    if (care.isWarning) return const Color(0xFFFFE0B2);
    return const Color(0xFFE5E5E5);
  }
}
