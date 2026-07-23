import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/settings_provider.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import 'my_ads_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: user == null
          ? LoginRequired(
              message: 'لم تسجّل الدخول بعد',
              onLogin: () => openAuth(context),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, glassNavInset(context) + 8),
              children: [
                // بطاقة المستخدم بترويسة متدرجة.
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: InitialsAvatar(name: user.name, radius: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.phone,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.white.withOpacity(0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user.isAdmin)
                        const SxBadge(
                          label: 'مدير',
                          color: Colors.white24,
                          icon: Icons.shield_outlined,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _MenuCard(
                  children: [
                    _MenuTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'إعلاناتي',
                      subtitle: 'إدارة إعلاناتك المنشورة',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyAdsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MenuCard(
                  children: [
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: sx.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          settings.isDark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          color: sx.accent,
                          size: 22,
                        ),
                      ),
                      title: const Text('الوضع الداكن'),
                      subtitle: Text(settings.isDark ? 'مفعّل' : 'متوقف'),
                      value: settings.isDark,
                      onChanged: (v) =>
                          context.read<SettingsProvider>().setDark(v),
                    ),
                    if (user.isAdmin) ...[
                      Divider(indent: 16, endIndent: 16, color: sx.outline),
                      const _MenuTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'لوحة الإدارة',
                        subtitle: 'متاحة عبر واجهة API‏ /api/admin',
                      ),
                    ],
                    Divider(indent: 16, endIndent: 16, color: sx.outline),
                    _MenuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'حول التطبيق',
                      subtitle: 'سوقنا — بيع وشراء في العراق',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'سوقنا',
                        applicationVersion: '1.0.0',
                        applicationIcon: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppTheme.brandGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white),
                        ),
                        children: const [
                          Text('منصّة بيع وشراء في العراق — إعلانات مبوّبة، '
                              'محادثات مباشرة بين البائع والمشتري، ومفضلة.'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MenuCard(
                  children: [
                    _MenuTile(
                      icon: Icons.logout_rounded,
                      title: 'تسجيل الخروج',
                      iconColor: sx.danger,
                      titleColor: sx.danger,
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك بتسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'خروج',
              style: TextStyle(color: dialogCtx.sx.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) context.read<FavoritesProvider>().clear();
    }
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

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
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? sx.accent).withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? sx.accent, size: 22),
      ),
      title: Text(
        title,
        style: titleColor != null
            ? TextStyle(color: titleColor, fontWeight: FontWeight.w600)
            : null,
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_left_rounded, color: sx.textSecondary)
          : null,
    );
  }
}
