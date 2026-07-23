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
    duration: const Duration(milliseconds: 1500),
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
        // مدى الحركة مضبوط بحيث يدخل اللمعان من حافة ويخرج من الأخرى دون
        // «وقت ميّت» — فتبدو الحركة متواصلة وناعمة بلا توقّف بين الدورات.
        final p = _ctrl.value * 1.3 - 0.65;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              // ميل قطري (يبدأ من اليمين علوياً) — كي يعبر الشعاع الشبكة
              // كلها قطرياً: بطاقات الأعلى تلمع قبل الأسفل.
              begin: const Alignment(1.0, -0.6),
              end: const Alignment(-1.0, 0.6),
              // نطاق لمعان ناعم بخمس محطات: قاعدة → لمعان → قاعدة.
              colors: [
                sx.shimmerBase,
                sx.shimmerBase,
                sx.shimmerHighlight,
                sx.shimmerBase,
                sx.shimmerBase,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: _SlideGradientTransform(p),
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
///
/// الشبكة كلها ملفوفة بلمعان **واحد** كي يعبر الشعاع كامل الشبكة قطرياً
/// (بدل لمعان مستقل لكل بطاقة).
class SliverListingGridSkeleton extends StatelessWidget {
  const SliverListingGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SxShimmer(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: count,
          itemBuilder: (_, __) => const ListingCardSkeleton(),
        ),
      ),
    );
  }
}
