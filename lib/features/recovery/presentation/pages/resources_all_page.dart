import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/recovery_controller.dart';
import '../widgets/resources_section.dart';
import '../../domain/entities/resource.dart';

/// Página com todos os recursos educacionais
///
/// Features:
/// - Busca por texto
/// - Filtro por categoria
/// - Filtro por tipo
/// - Paginação infinita
class ResourcesAllPage extends StatefulWidget {
  const ResourcesAllPage({super.key});

  @override
  State<ResourcesAllPage> createState() => _ResourcesAllPageState();
}

class _ResourcesAllPageState extends State<ResourcesAllPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Carrega recursos ao abrir a página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecoveryController>().loadAllResources(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<RecoveryController>().setSearchQuery(query);
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<RecoveryController>().setSearchQuery('');
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FiltersSheet(
        selectedCategory: context.read<RecoveryController>().selectedCategory,
        selectedType: context.read<RecoveryController>().selectedType,
        onCategoryChanged: (category) {
          context.read<RecoveryController>().setResourceCategory(category);
          Navigator.pop(context);
        },
        onTypeChanged: (type) {
          context.read<RecoveryController>().setResourceType(type);
          Navigator.pop(context);
        },
        onClear: () {
          context.read<RecoveryController>().clearResourceFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onResourceTap(Resource resource) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResourceDetailPage(resource: resource),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recursos Educacionais'),
        centerTitle: true,
        actions: [
          Consumer<RecoveryController>(
            builder: (context, controller, child) {
              final hasFilters = controller.selectedCategory != null ||
                  controller.selectedType != null;
              return IconButton(
                onPressed: _showFilters,
                icon: Badge(
                  isLabelVisible: hasFilters,
                  child: const Icon(Icons.filter_list),
                ),
                tooltip: 'Filtros',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Buscar recursos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Consumer<RecoveryController>(
                  builder: (context, controller, child) {
                    if (controller.searchQuery.isNotEmpty) {
                      return IconButton(
                        onPressed: _onClearSearch,
                        icon: const Icon(Icons.close),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
              ),
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
            ),
          ),
          // Filtros ativos
          Consumer<RecoveryController>(
            builder: (context, controller, child) {
              final chips = <Widget>[];

              if (controller.selectedCategory != null) {
                chips.add(_FilterChip(
                  label: _getCategoryLabel(controller.selectedCategory!),
                  onRemove: () => controller.setResourceCategory(null),
                ));
              }

              if (controller.selectedType != null) {
                chips.add(_FilterChip(
                  label: _getTypeLabel(controller.selectedType!),
                  onRemove: () => controller.setResourceType(null),
                ));
              }

              if (chips.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Filtros:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...chips.map((chip) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: chip,
                        )),
                  ],
                ),
              );
            },
          ),
          // Contador de resultados
          Consumer<RecoveryController>(
            builder: (context, controller, child) {
              if (controller.isLoadingResources && controller.allResources.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${controller.totalResourcesCount} recursos encontrados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Lista de recursos
          Expanded(
            child: Consumer<RecoveryController>(
              builder: (context, controller, child) {
                return RefreshIndicator(
                  onRefresh: () => controller.loadAllResources(refresh: true),
                  child: ResourcesList(
                    resources: controller.allResources,
                    isLoading: controller.isLoadingResources,
                    hasMore: controller.hasMoreResources,
                    onLoadMore: controller.loadMoreResources,
                    onResourceTap: _onResourceTap,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.recovery:
        return 'Recuperação';
      case ResourceCategory.nutrition:
        return 'Nutrição';
      case ResourceCategory.exercise:
        return 'Exercícios';
      case ResourceCategory.mentalHealth:
        return 'Saúde Mental';
      case ResourceCategory.skinCare:
        return 'Cuidados com a Pele';
      case ResourceCategory.general:
        return 'Geral';
    }
  }

  String _getTypeLabel(ResourceType type) {
    switch (type) {
      case ResourceType.article:
        return 'Artigo';
      case ResourceType.video:
        return 'Vídeo';
      case ResourceType.infographic:
        return 'Infográfico';
      case ResourceType.faq:
        return 'FAQ';
      case ResourceType.tip:
        return 'Dica';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersSheet extends StatelessWidget {
  final ResourceCategory? selectedCategory;
  final ResourceType? selectedType;
  final void Function(ResourceCategory?) onCategoryChanged;
  final void Function(ResourceType?) onTypeChanged;
  final VoidCallback onClear;

  const _FiltersSheet({
    this.selectedCategory,
    this.selectedType,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtros',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Conteúdo
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Categorias
                  Text(
                    'Categoria',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ResourceCategory.values.map((category) {
                      final isSelected = selectedCategory == category;
                      return ChoiceChip(
                        label: Text(_getCategoryLabel(category)),
                        selected: isSelected,
                        onSelected: (selected) {
                          onCategoryChanged(selected ? category : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Tipos
                  Text(
                    'Tipo de Conteúdo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ResourceType.values.map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(_getTypeLabel(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          onTypeChanged(selected ? type : null);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryLabel(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.recovery:
        return 'Recuperação';
      case ResourceCategory.nutrition:
        return 'Nutrição';
      case ResourceCategory.exercise:
        return 'Exercícios';
      case ResourceCategory.mentalHealth:
        return 'Saúde Mental';
      case ResourceCategory.skinCare:
        return 'Cuidados';
      case ResourceCategory.general:
        return 'Geral';
    }
  }

  String _getTypeLabel(ResourceType type) {
    switch (type) {
      case ResourceType.article:
        return 'Artigo';
      case ResourceType.video:
        return 'Vídeo';
      case ResourceType.infographic:
        return 'Infográfico';
      case ResourceType.faq:
        return 'FAQ';
      case ResourceType.tip:
        return 'Dica';
    }
  }
}

/// Página de detalhes de um recurso
class ResourceDetailPage extends StatelessWidget {
  final Resource resource;

  const ResourceDetailPage({
    super.key,
    required this.resource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Cor baseada no tipo
    Color color;
    IconData icon;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(resource.typeLabel),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Compartilhar recurso
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          resource.categoryLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
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
              ],
            ),
            const SizedBox(height: 24),
            // Título
            Text(
              resource.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Descrição
            if (resource.description != null) ...[
              Text(
                resource.description!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Conteúdo
            if (resource.content != null) ...[
              Text(
                resource.content!,
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              // Placeholder para conteúdo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      resource.type == ResourceType.video
                          ? Icons.play_circle_outline
                          : Icons.article_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      resource.type == ResourceType.video
                          ? 'Conteúdo de vídeo será carregado aqui'
                          : 'Conteúdo do artigo será carregado aqui',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Tags
            if (resource.tags.isNotEmpty) ...[
              Text(
                'Tags',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: resource.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '#$tag',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
