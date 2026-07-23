import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// خلفية زجاجية لشريط التطبيق العلوي — تُمرَّر كـ `flexibleSpace` فيظهر
/// المحتوى مموّهاً خلف الشريط عند التمرير (تأثير خفيف بلون شبه شفاف + حدّ سفلي).
class GlassBar extends StatelessWidget {
  const GlassBar({super.key, this.sigma = 16});

  final double sigma;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: sx.surface.withOpacity(0.60),
            border: Border(
              bottom: BorderSide(color: sx.outline.withOpacity(0.5)),
            ),
          ),
        ),
      ),
    );
  }
}

/// ارتفاع الشريط السفلي العائم (بدون الهوامش والمنطقة الآمنة).
const double kBottomNavBarHeight = 64;

/// حشوة سفلية تُضاف لمحتوى شاشات التبويبات كي لا يختفي آخره خلف الشريط
/// العائم الزجاجي — لأن الجسم يمتدّ تحته (extendBody) ليظهر تأثير الـ blur.
/// تشمل ارتفاع الشريط + هامشه السفلي العائم + المنطقة الآمنة.
double glassNavInset(BuildContext context) =>
    kBottomNavBarHeight + 24 + MediaQuery.of(context).viewPadding.bottom;

/// حشوة علوية لمحتوى شاشة ذات شريط علوي زجاجي (مع extendBodyBehindAppBar)
/// كي لا يختبئ أول عنصر خلف الشريط: ارتفاع الشريط + شريط الحالة.
double glassTopInset(BuildContext context) =>
    kToolbarHeight + MediaQuery.of(context).viewPadding.top;

/// شريط تطبيق علوي زجاجي موحّد (شفاف + تمويه المحتوى خلفه).
/// استخدمه مع `Scaffold(extendBodyBehindAppBar: true, …)` وأضِف
/// [glassTopInset] كحشوة علوية لمحتوى الشاشة.
AppBar glassAppBar({
  required Widget title,
  List<Widget>? actions,
}) {
  return AppBar(
    title: title,
    actions: actions,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    flexibleSpace: const GlassBar(),
  );
}

/// نوع الإشعار — يحدد الأيقونة واللون.
enum SnackType { success, error, info }

/// إشعار موحّد عصري: أيقونة داخل كبسولة ملوّنة + نص، بدل الإيموجي.
void showAppSnack(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
}) {
  final sx = context.sx;
  final (IconData icon, Color color) = switch (type) {
    SnackType.success => (Icons.check_circle_rounded, sx.success),
    SnackType.error => (Icons.error_rounded, sx.danger),
    SnackType.info => (Icons.info_rounded, AppTheme.brand),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

/// حالة فارغة أنيقة: أيقونة داخل دائرة ناعمة + عنوان + وصف + زر اختياري.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: sx.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: sx.accent),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: sx.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: sx.textSecondary, height: 1.5),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: sx.accent,
                  foregroundColor: sx.onAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(strokeWidth: 3));
}

/// دعوة لتسجيل الدخول تُعرض في الأقسام المحمية.
class LoginRequired extends StatelessWidget {
  const LoginRequired({super.key, required this.message, required this.onLogin});

  final String message;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: sx.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded, size: 44, color: sx.accent),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: sx.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'أنشئ حساباً خلال ثوانٍ وابدأ البيع والشراء',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: sx.textSecondary),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.login_rounded, size: 20),
                label: const Text('تسجيل الدخول / إنشاء حساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// عنوان قسم مع زر «عرض الكل» اختياري.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: sx.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: sx.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sx.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// شارة صغيرة ملوّنة (حالة، تفاوض…).
class SxBadge extends StatelessWidget {
  const SxBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onColor,
  });

  final String label;
  final Color color;
  final Color? onColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = onColor ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// يصغّر الطفل قليلاً أثناء الضغط دون التقاط الإيماءة — لمسة حديثة تعمل
/// جنباً إلى جنب مع `InkWell`/`GestureDetector` الداخلي لأنها تعتمد
/// `Listener` تمريرياً (لا يبتلع النقرات فتبقى الحبكة والانتقال يعملان).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// حركة دخول ناعمة (تلاشٍ + انزلاق للأعلى) بتدرّج بسيط حسب ترتيب العنصر —
/// تمنح الشبكات إحساساً حديثاً عند أول ظهور.
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 360),
  });

  final Widget child;
  final int index;
  final Duration duration;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curved =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    // تدرّج محدود حتى لا تتأخر العناصر البعيدة في القائمة.
    final delayMs = widget.index.clamp(0, 8) * 45;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_curved),
        child: widget.child,
      ),
    );
  }
}

/// حرف أول من الاسم داخل دائرة بلون مشتق من الاسم — رمز مستخدم.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.radius = 22});

  final String name;
  final double radius;

  static const _palette = [
    Color(0xFF0D9488),
    Color(0xFF6366F1),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
    Color(0xFF0284C7),
    Color(0xFF16A34A),
    Color(0xFFDC2626),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '؟' : trimmed.substring(0, 1);
    final color = _palette[trimmed.hashCode.abs() % _palette.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.18),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
