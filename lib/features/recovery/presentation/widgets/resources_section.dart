import 'package:flutter/material.dart';
import '../../domain/entities/resource.dart';

/// Seção de recursos educacionais na home
class ResourcesSection extends StatelessWidget {
  final List<Resource> resources;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final void Function(Resource resource)? onResourceTap;

  const ResourcesSection({
    super.key,
    required this.resources,
    this.isLoading = false,
    this.onViewAll,
    this.onResourceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recursos Educacionais',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('Ver todos'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Lista horizontal
        SizedBox(
          height: 180,
          child: isLoading
              ? _buildSkeleton(theme)
              : resources.isEmpty
                  ? _buildEmpty(theme)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: resources.length,
                      itemBuilder: (context, index) {
                        final resource = resources[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < resources.length - 1 ? 12 : 0,
                          ),
                          child: ResourceCard(
                            resource: resource,
                            onTap: () => onResourceTap?.call(resource),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 200,
          margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhum recurso disponível',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card individual de recurso
class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback? onTap;
  final double width;

  const ResourceCard({
    super.key,
    required this.resource,
    this.onTap,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ícone e cor baseados no tipo
    IconData icon;
    Color color;

    switch (resource.type) {
      case ResourceType.article:
        icon = Icons.article;
        color = Colors.blue;
        break;
      case ResourceType.video:
        icon = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case ResourceType.infographic:
        icon = Icons.image;
        color = Colors.purple;
        break;
      case ResourceType.faq:
        icon = Icons.help_outline;
        color = Colors.orange;
        break;
      case ResourceType.tip:
        icon = Icons.lightbulb;
        color = Colors.amber;
        break;
    }

    return Semantics(
      label: '${resource.typeLabel}: ${resource.title}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone e tipo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      resource.typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  if (resource.isFeatured) ...[
                    const Spacer(),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber.shade600,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Título
              Expanded(
                child: Text(
                  resource.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              // Duração/tempo de leitura
              if (resource.durationLabel.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      resource.type == ResourceType.video
                          ? Icons.schedule
                          : Icons.menu_book,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      resource.durationLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista vertical de recursos (para a página de todos os recursos)
class ResourcesList extends StatelessWidget {
  final List<Resource> resources;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final void Function(Resource resource)? onResourceTap;

  const ResourcesList({
    super.key,
    required this.resources,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onResourceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && resources.isEmpty) {
      return _buildSkeleton(theme);
    }

    if (resources.isEmpty) {
      return _buildEmpty(theme);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            hasMore &&
            onLoadMore != null) {
          onLoadMore!();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: resources.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == resources.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final resource = resources[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ResourceListItem(
              resource: resource,
              onTap: () => onResourceTap?.call(resource),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum recurso encontrado',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros de busca',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item de lista de recursos (versão vertical)
class ResourceListItem extends StatelessWidget {
  final Resource resource;
  final VoidCallback? onTap;

  const ResourceListItem({
    super.key,
    required this.resource,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;

    switch (resource.type) {
      case ResourceType.article:
        icon = Icons.article;
        color = Colors.blue;
        break;
      case ResourceType.video:
        icon = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case ResourceType.infographic:
        icon = Icons.image;
        color = Colors.purple;
        break;
      case ResourceType.faq:
        icon = Icons.help_outline;
        color = Colors.orange;
        break;
      case ResourceType.tip:
        icon = Icons.lightbulb;
        color = Colors.amber;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo e categoria
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            resource.typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          resource.categoryLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Título
                    Text(
                      resource.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Duração e visualizações
                    Row(
                      children: [
                        if (resource.durationLabel.isNotEmpty) ...[
                          Icon(
                            resource.type == ResourceType.video
                                ? Icons.schedule
                                : Icons.menu_book,
                            size: 12,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            resource.durationLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${resource.viewCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Seta
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
