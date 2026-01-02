import 'package:flutter/material.dart';

/// Widget de skeleton loading para a tela Home
/// Exibe placeholders animados enquanto os dados carregam
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSkeleton(),
              const SizedBox(height: 24),
              _buildSectionSkeleton('Próximas Consultas', 2),
              const SizedBox(height: 24),
              _buildAcoesRapidasSkeleton(),
              const SizedBox(height: 24),
              _buildSectionSkeleton('Remédios', 3),
              const SizedBox(height: 24),
              _buildSectionSkeleton('Cuidados', 2),
              const SizedBox(height: 24),
              _buildScoreSkeleton(),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: _animation.value),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar skeleton
              _buildShimmerBox(width: 56, height: 56, borderRadius: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 150, height: 24, borderRadius: 4),
                  const SizedBox(height: 8),
                  _buildShimmerBox(width: 100, height: 16, borderRadius: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress bar skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBox(width: 100, height: 12, borderRadius: 4),
              _buildShimmerBox(width: 80, height: 12, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 8),
          _buildShimmerBox(
            width: double.infinity,
            height: 8,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSkeleton(String title, int cardCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: 180, height: 22, borderRadius: 4),
          const SizedBox(height: 16),
          ...List.generate(
            cardCount,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _buildShimmerBox(width: 56, height: 56, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 120, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                _buildShimmerBox(width: 80, height: 14, borderRadius: 4),
                const SizedBox(height: 4),
                _buildShimmerBox(width: 100, height: 12, borderRadius: 4),
              ],
            ),
          ),
          _buildShimmerBox(width: 60, height: 24, borderRadius: 12),
        ],
      ),
    );
  }

  Widget _buildAcoesRapidasSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: 140, height: 22, borderRadius: 4),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildAcaoCardSkeleton()),
              const SizedBox(width: 16),
              Expanded(child: _buildAcaoCardSkeleton()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildAcaoCardSkeleton()),
              const SizedBox(width: 16),
              Expanded(child: _buildAcaoCardSkeleton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcaoCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: 48, height: 48, borderRadius: 12),
          const SizedBox(height: 12),
          _buildShimmerBox(width: 80, height: 14, borderRadius: 4),
          const SizedBox(height: 4),
          _buildShimmerBox(width: 100, height: 12, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildScoreSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 120, height: 16, borderRadius: 4),
                    const SizedBox(height: 4),
                    _buildShimmerBox(width: 150, height: 14, borderRadius: 4),
                  ],
                ),
                _buildShimmerBox(width: 64, height: 64, borderRadius: 32),
              ],
            ),
            const SizedBox(height: 16),
            _buildShimmerBox(width: 80, height: 45, borderRadius: 4),
            const SizedBox(height: 8),
            _buildShimmerBox(width: 200, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
