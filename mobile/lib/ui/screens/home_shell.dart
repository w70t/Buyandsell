import 'package:flutter/material.dart';

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

  void _goto(int i) => setState(() => _index = i);

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
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goto,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'المفضلة'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'أضف إعلان'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'المحادثات'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
