import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../state/favorites_provider.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import 'my_ads_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: user == null
          ? LoginRequired(message: 'لم تسجّل الدخول بعد', onLogin: () => openAuth(context))
          : ListView(
              children: [
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.tile,
                    child: Icon(Icons.person, size: 34, color: AppTheme.accent),
                  ),
                  title: Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(user.phone),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined, color: AppTheme.accent),
                  title: const Text('إعلاناتي'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyAdsScreen()),
                  ),
                ),
                const Divider(height: 1),
                if (user.isAdmin)
                  const ListTile(
                    leading: Icon(Icons.admin_panel_settings_outlined, color: AppTheme.accent),
                    title: Text('لوحة الإدارة'),
                    subtitle: Text('متاحة عبر واجهة API‏ /api/admin'),
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('تسجيل الخروج'),
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.read<FavoritesProvider>().clear();
                  },
                ),
              ],
            ),
    );
  }
}
