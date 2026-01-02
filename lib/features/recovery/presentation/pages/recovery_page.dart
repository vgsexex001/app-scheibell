import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/recovery_controller.dart';
import '../widgets/recovery_header.dart';
import '../widgets/timeline_tab.dart';
import '../widgets/resources_section.dart';
import '../widgets/exams_docs_tab.dart';
import '../../domain/entities/resource.dart';
import 'resources_all_page.dart';

/// Página principal de Recuperação
///
/// Estrutura:
/// - Header com métricas (dias, adesão, tarefas)
/// - Tabs: Timeline, Exames, Docs, Recursos
/// - Pull-to-refresh em todas as tabs
class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_TabItem> _tabs = const [
    _TabItem(icon: Icons.timeline, label: 'Timeline'),
    _TabItem(icon: Icons.science, label: 'Exames'),
    _TabItem(icon: Icons.folder, label: 'Docs'),
    _TabItem(icon: Icons.menu_book, label: 'Recursos'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Carrega dados ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecoveryController>().initialize();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<RecoveryController>().setSelectedTab(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<RecoveryController>().refresh();
  }

  void _navigateToAllResources() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<RecoveryController>(),
          child: const ResourcesAllPage(),
        ),
      ),
    );
  }

  void _onResourceTap(Resource resource) {
    // TODO: Navegar para página de detalhes do recurso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo: ${resource.title}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onViewExams() {
    // TODO: Navegar para página de exames
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo exames...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<RecoveryController>(
        builder: (context, controller, child) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // AppBar
                SliverAppBar(
                  title: const Text('Recuperação'),
                  centerTitle: true,
                  floating: true,
                  snap: true,
                  forceElevated: innerBoxIsScrolled,
                ),
                // Header com métricas
                SliverToBoxAdapter(
                  child: RecoveryHeader(
                    summary: controller.summary,
                    isLoading: controller.isLoadingSummary,
                  ),
                ),
                // TabBar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: _tabs
                          .map((tab) => Tab(
                                icon: Icon(tab.icon),
                                text: tab.label,
                              ))
                          .toList(),
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.outline,
                      indicatorColor: theme.colorScheme.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                    ),
                    theme.colorScheme.surface,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Timeline
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: _TimelineTabContent(controller: controller),
                ),
                // Tab 2: Exames
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ExamsTab(
                    stats: controller.examStats,
                    isLoading: controller.isLoadingExams,
                    onViewExams: _onViewExams,
                  ),
                ),
                // Tab 3: Documentos
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: DocumentsTab(
                    documents: controller.documents,
                    isLoading: controller.isLoadingDocs,
                  ),
                ),
                // Tab 4: Recursos
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: _ResourcesTabContent(
                    controller: controller,
                    onViewAll: _navigateToAllResources,
                    onResourceTap: _onResourceTap,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Conteúdo da tab Timeline com seção de recursos
class _TimelineTabContent extends StatelessWidget {
  final RecoveryController controller;

  const _TimelineTabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TimelineTab(
      events: controller.timelineEvents,
      isLoading: controller.isLoadingTimeline,
      onRefresh: controller.refresh,
    );
  }
}

/// Conteúdo da tab de Recursos
class _ResourcesTabContent extends StatelessWidget {
  final RecoveryController controller;
  final VoidCallback? onViewAll;
  final void Function(Resource resource)? onResourceTap;

  const _ResourcesTabContent({
    required this.controller,
    this.onViewAll,
    this.onResourceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.isLoadingResources && controller.featuredResources.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.featuredResources.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum recurso disponível',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Os recursos educacionais aparecerão aqui',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Recursos em destaque
        ResourcesSection(
          resources: controller.featuredResources,
          isLoading: controller.isLoadingResources,
          onViewAll: onViewAll,
          onResourceTap: onResourceTap,
        ),
        const SizedBox(height: 24),
        // Dica
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dica do dia',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mantenha a cabeça elevada durante o sono usando 2-3 travesseiros para reduzir o inchaço.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({required this.icon, required this.label});
}

/// Delegate para o TabBar persistente
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
