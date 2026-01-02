import 'package:flutter/material.dart';

/// Widget de estado vazio para agenda
class AgendaEmptyState extends StatelessWidget {
  final String? message;
  final VoidCallback? onAddEvent;

  const AgendaEmptyState({
    super.key,
    this.message,
    this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Nenhum evento agendado',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione eventos para organizar sua agenda',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAddEvent != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAddEvent,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Evento'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
