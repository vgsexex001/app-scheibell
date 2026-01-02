import 'package:flutter/material.dart';
import '../../domain/entities/timeline_event.dart';
import '../../../../core/utils/date_formatter.dart';

/// Tab de Timeline da recuperação
class TimelineTab extends StatelessWidget {
  final List<TimelineEvent> events;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const TimelineTab({
    super.key,
    required this.events,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _TimelineSkeleton();
    }

    if (events.isEmpty) {
      return _EmptyState(onRefresh: onRefresh);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        return _TimelineItem(
          event: event,
          isLast: isLast,
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineItem({
    required this.event,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Cores baseadas no status
    Color dotColor;
    Color lineColor;
    double opacity;

    switch (event.status) {
      case TimelineEventStatus.completed:
        dotColor = Colors.green;
        lineColor = Colors.green.withValues(alpha: 0.3);
        opacity = 1.0;
        break;
      case TimelineEventStatus.current:
        dotColor = theme.colorScheme.primary;
        lineColor = theme.colorScheme.primary.withValues(alpha: 0.3);
        opacity = 1.0;
        break;
      case TimelineEventStatus.upcoming:
        dotColor = theme.colorScheme.outline;
        lineColor = theme.colorScheme.outline.withValues(alpha: 0.2);
        opacity = 0.7;
        break;
    }

    // Ícone baseado no tipo
    IconData icon;
    switch (event.type) {
      case TimelineEventType.surgery:
        icon = Icons.medical_services;
        break;
      case TimelineEventType.appointment:
        icon = Icons.event;
        break;
      case TimelineEventType.milestone:
        icon = Icons.flag;
        break;
      case TimelineEventType.task:
        icon = Icons.task_alt;
        break;
      case TimelineEventType.medication:
        icon = Icons.medication;
        break;
      case TimelineEventType.exam:
        icon = Icons.science;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna da linha do tempo
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Dot/ícone
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: event.isCurrent
                        ? dotColor
                        : dotColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: event.isCurrent ? Colors.white : dotColor,
                  ),
                ),
                // Linha conectora
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          // Conteúdo
          Expanded(
            child: Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: event.isCurrent
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: event.isCurrent
                      ? Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Data e badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.fullDate(event.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (event.dayLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.dayLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: dotColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Título
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (event.isImportant)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                          ),
                      ],
                    ),
                    // Descrição
                    if (event.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    // Badge de status
                    if (event.isCurrent) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ATUAL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dot placeholder
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
              ),
              // Content placeholder
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const _EmptyState({this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento na timeline',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Os eventos da sua recuperação aparecerão aqui',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
