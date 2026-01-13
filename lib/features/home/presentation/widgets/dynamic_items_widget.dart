import 'package:flutter/material.dart';
import '../../../patient/providers/home_provider.dart';

/// Widget para exibir itens dinâmicos da Home (pendentes, atrasados, etc)
class DynamicItemsWidget extends StatelessWidget {
  final List<DynamicHomeItem> items;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Future<bool> Function(DynamicHomeItem)? onAction;
  final void Function(DynamicHomeItem)? onVideoTap;

  static const _primaryDark = Color(0xFF4F4A34);
  static const _cardBorder = Color(0xFFC8C2B4);
  static const _upcomingColor = Color(0xFF4CAF50);

  const DynamicItemsWidget({
    super.key,
    required this.items,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onAction,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return _buildLoading();
    }

    if (errorMessage != null && items.isEmpty) {
      return _buildError();
    }

    if (items.isEmpty) {
      return _buildEmpty();
    }

    return _buildContent(context);
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _primaryDark),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            errorMessage ?? 'Erro ao carregar',
            style: const TextStyle(color: Colors.red),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.check_circle, color: _upcomingColor, size: 48),
            SizedBox(height: 8),
            Text(
              'Tudo em dia!',
              style: TextStyle(
                color: _primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Nenhuma tarefa pendente no momento',
              style: TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pendencias do dia',
          style: TextStyle(
            color: Color(0xFF212621),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _DynamicItemCard(
            item: item,
            onAction: onAction,
            onVideoTap: onVideoTap,
          ),
        )),
      ],
    );
  }
}

class _DynamicItemCard extends StatefulWidget {
  final DynamicHomeItem item;
  final Future<bool> Function(DynamicHomeItem)? onAction;
  final void Function(DynamicHomeItem)? onVideoTap;

  const _DynamicItemCard({
    required this.item,
    this.onAction,
    this.onVideoTap,
  });

  @override
  State<_DynamicItemCard> createState() => _DynamicItemCardState();
}

class _DynamicItemCardState extends State<_DynamicItemCard> {
  bool _isLoading = false;

  static const _primaryDark = Color(0xFF4F4A34);
  static const _cardBorder = Color(0xFFC8C2B4);
  static const _overdueColor = Color(0xFFE53935);
  static const _pendingColor = Color(0xFFF5A623);
  static const _upcomingColor = Color(0xFF4CAF50);

  Color get _statusColor {
    switch (widget.item.status) {
      case 'OVERDUE':
        return _overdueColor;
      case 'PENDING':
        return _pendingColor;
      case 'UPCOMING':
        return _upcomingColor;
      default:
        return _primaryDark;
    }
  }

  IconData get _typeIcon {
    switch (widget.item.type) {
      case 'MEDICATION':
        return Icons.medication;
      case 'VIDEO':
        return Icons.play_circle_outline;
      case 'TASK':
        return Icons.task_alt;
      default:
        return Icons.circle;
    }
  }

  String get _statusLabel {
    switch (widget.item.status) {
      case 'OVERDUE':
        return 'Atrasado';
      case 'PENDING':
        return 'Pendente';
      case 'UPCOMING':
        return 'Em breve';
      default:
        return '';
    }
  }

  Future<void> _handleAction() async {
    if (widget.item.isVideo) {
      widget.onVideoTap?.call(widget.item);
      return;
    }

    if (widget.onAction == null) return;

    setState(() => _isLoading = true);
    try {
      await widget.onAction!(widget.item);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.item.action != null ? _handleAction : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone do tipo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _typeIcon,
                    color: _statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.title,
                              style: const TextStyle(
                                color: _primaryDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.item.status == 'OVERDUE')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _overdueColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _statusLabel,
                                style: TextStyle(
                                  color: _overdueColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (widget.item.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.subtitle!,
                          style: const TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Botão de ação
                if (widget.item.action != null) ...[
                  const SizedBox(width: 8),
                  _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _primaryDark,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.item.action!.label,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
