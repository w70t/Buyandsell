import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../../state/favorites_provider.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/listing_grid.dart';
import '../widgets/skeleton.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Listing> _items = [];
  bool _loading = false;
  bool _loadedOnce = false;

  Future<void> _load() async {
    if (!context.read<AuthProvider>().isLoggedIn) return;
    _loadedOnce = true;
    setState(() => _loading = true);
    try {
      _items = await context.read<ApiService>().favorites();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final favCount = context.watch<FavoritesProvider>().ids.length;
    // إعادة التحميل تلقائياً بعد تسجيل الدخول (التبويب يُبنى قبل الدخول)،
    // وعند تبديل القلوب من أي شاشة أخرى.
    if (!loggedIn) {
      _loadedOnce = false;
      if (_items.isNotEmpty) _items = [];
    } else if (!_loading && (!_loadedOnce || favCount != _items.length)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: const Text('المفضلة'),
        actions: [
          if (loggedIn)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      body: !loggedIn
          ? LoginRequired(
              message: 'سجّل الدخول لعرض المفضلة',
              onLogin: () async {
                await openAuth(context);
                if (mounted) _load();
              },
            )
          : RefreshIndicator(
              onRefresh: _load,
              edgeOffset: glassTopInset(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: glassTopInset(context)),
                  ),
                  if (_loading && !_loadedOnce)
                    const SliverListingGridSkeleton(count: 6)
                  else if (_items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        message: 'لا توجد إعلانات في المفضلة',
                        subtitle: 'اضغط على زر القلب في أي إعلان ليظهر هنا',
                        icon: Icons.favorite_border_rounded,
                      ),
                    )
                  else
                    SliverListingGrid(items: _items),
                  SliverToBoxAdapter(
                    child: SizedBox(height: glassNavInset(context)),
                  ),
                ],
              ),
            ),
    );
  }
}
