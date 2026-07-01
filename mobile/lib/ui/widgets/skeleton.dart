import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// تأثير لمعان (Shimmer) خفيف يمرّ فوق هياكل التحميل — بدون أي حزم خارجية.
class SxShimmer extends StatefulWidget {
  const SxShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<SxShimmer> createState() => _SxShimmerState();
}

class _SxShimmerState extends State<SxShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) {
        final t = _ctrl.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                sx.shimmerBase,
                sx.shimmerHighlight,
                sx.shimmerBase,
              ],
              stops: const [0.25, 0.5, 0.75],
              transform: _SlideGradientTransform(t * 2 - 1),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

/// صندوق هيكلي بلون قاعدة اللمعان.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 10,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.sx.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// هيكل بطاقة إعلان (صورة + سطور نص) بنفس أبعاد [ListingCard].
class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Container(
      decoration: BoxDecoration(
        color: sx.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sx.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: SkeletonBox(radius: 0),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 80, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شبكة هياكل تحميل تُستخدم كـ sliver.
class SliverListingGridSkeleton extends StatelessWidget {
  const SliverListingGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => const SxShimmer(child: ListingCardSkeleton()),
          childCount: count,
        ),
      ),
    );
  }
}
