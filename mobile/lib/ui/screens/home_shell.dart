import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';
import 'conversations_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'post_ad_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goto(int i) {
    if (i != _index) HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const FavoritesScreen(),
      PostAdScreen(onPublished: () => _goto(0)),
      const ConversationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // يمتدّ الجسم تحت الشريط ليتيح لتأثير الـ blur تصوير المحتوى خلفه.
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _FloatingGlassNav(index: _index, onTap: _goto),
    );
  }
}

/// شريط تنقّل عائم بيضوي زجاجي (blur) مع مؤشّر ضبابي ينزلق للتبويب المختار —
/// بأسلوب iOS الحديث.
class _FloatingGlassNav extends StatelessWidget {
  const _FloatingGlassNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _height = kBottomNavBarHeight;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          // يحمل الظلّ خارج الاقتصاص كي لا يُقصّ.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: _height,
                decoration: BoxDecoration(
                  color: sx.surface.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: sx.outline.withOpacity(0.7)),
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final slot = c.maxWidth / 5;
                    const blobH = 46.0;
                    final blobW = slot - 12;
                    return Stack(
                      children: [
                        // المؤشّر الضبابي المنزلق — يتبع الاتجاه RTL عبر start.
                        AnimatedPositionedDirectional(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          top: (_height - blobH) / 2,
                          start: slot * index + (slot - blobW) / 2,
                          width: blobW,
                          height: blobH,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            // يختفي تحت زر «بيع» المركزي (فالزر نفسه هو المؤشّر).
                            opacity: index == 2 ? 0 : 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: sx.accent.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: sx.accent.withOpacity(0.22),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Row(
                            children: [
                              _NavItem(
                                icon: Icons.home_outlined,
                                selectedIcon: Icons.home_rounded,
                                label: 'الرئيسية',
                                selected: index == 0,
                                onTap: () => onTap(0),
                              ),
                              _NavItem(
                                icon: Icons.favorite_border_rounded,
                                selectedIcon: Icons.favorite_rounded,
                                label: 'المفضلة',
                                selected: index == 1,
                                onTap: () => onTap(1),
                              ),
                              _SellButton(
                                selected: index == 2,
                                onTap: () => onTap(2),
                              ),
                              _NavItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                selectedIcon: Icons.chat_bubble_rounded,
                                label: 'المحادثات',
                                selected: index == 3,
                                onTap: () => onTap(3),
                              ),
                              _NavItem(
                                icon: Icons.person_outline_rounded,
                                selectedIcon: Icons.person_rounded,
                                label: 'حسابي',
                                selected: index == 4,
                                onTap: () => onTap(4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    final color = selected ? sx.accent : sx.textSecondary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر «بيع» المركزي بتدرّج العلامة.
class _SellButton extends StatelessWidget {
  const _SellButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: sx.accent.withOpacity(selected ? 0.5 : 0.32),
                    blurRadius: selected ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 2),
            Text(
              'بيع',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? sx.accent : sx.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
