import 'package:flutter/material.dart';
import '../../../../core/utils/date_formatter.dart';

/// Header do calendário com navegação de mês
class CalendarHeader extends StatelessWidget {
  final DateTime visibleMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTodayPressed;

  const CalendarHeader({
    super.key,
    required this.visibleMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTodayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isCurrentMonth = visibleMonth.year == now.year &&
        visibleMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mês anterior',
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTodayPressed,
              child: Text(
                '${DateFormatter.monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (!isCurrentMonth)
            TextButton(
              onPressed: onTodayPressed,
              child: const Text('Hoje'),
            ),
          IconButton(
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo mês',
          ),
        ],
      ),
    );
  }
}
