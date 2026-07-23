import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
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
    final sx = context.sx;
    final pages = [
      const HomeScreen(),
      const FavoritesScreen(),
      PostAdScreen(onPublished: () => _goto(0)),
      const ConversationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: sx.surface,
          border: Border(top: BorderSide(color: sx.outline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'الرئيسية',
                  selected: _index == 0,
                  onTap: () => _goto(0),
                ),
                _NavItem(
                  icon: Icons.favorite_border_rounded,
                  selectedIcon: Icons.favorite_rounded,
                  label: 'المفضلة',
                  selected: _index == 1,
                  onTap: () => _goto(1),
                ),
                _SellButton(selected: _index == 2, onTap: () => _goto(2)),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  selectedIcon: Icons.chat_bubble_rounded,
                  label: 'المحادثات',
                  selected: _index == 3,
                  onTap: () => _goto(3),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'حسابي',
                  selected: _index == 4,
                  onTap: () => _goto(4),
                ),
              ],
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
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
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
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: sx.accent.withOpacity(0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
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
