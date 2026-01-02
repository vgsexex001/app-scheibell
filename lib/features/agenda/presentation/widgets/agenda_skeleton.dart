import 'package:flutter/material.dart';

/// Widget de skeleton para carregamento da agenda
class AgendaSkeleton extends StatefulWidget {
  const AgendaSkeleton({super.key});

  @override
  State<AgendaSkeleton> createState() => _AgendaSkeletonState();
}

class _AgendaSkeletonState extends State<AgendaSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            // Calendar skeleton
            _buildCalendarSkeleton(),
            const SizedBox(height: 16),
            // List skeleton
            _buildListSkeleton(),
          ],
        );
      },
    );
  }

  Widget _buildCalendarSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBox(width: 32, height: 32, circular: true),
              _buildShimmerBox(width: 150, height: 24),
              _buildShimmerBox(width: 32, height: 32, circular: true),
            ],
          ),
          const SizedBox(height: 16),
          // Week days header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              7,
              (_) => _buildShimmerBox(width: 30, height: 16),
            ),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: 35,
            itemBuilder: (context, index) {
              return _buildShimmerBox(width: 40, height: 40);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: 120, height: 20),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEventCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          _buildShimmerBox(width: 4, height: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 180, height: 16),
                const SizedBox(height: 8),
                _buildShimmerBox(width: 120, height: 14),
                const SizedBox(height: 4),
                _buildShimmerBox(width: 150, height: 14),
              ],
            ),
          ),
          _buildShimmerBox(width: 24, height: 24, circular: true),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    bool circular = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: _animation.value),
        borderRadius: circular ? null : BorderRadius.circular(4),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}
