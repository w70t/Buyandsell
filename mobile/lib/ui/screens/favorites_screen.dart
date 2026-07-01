import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Listing> _items = [];
  bool _loading = false;

  Future<void> _load() async {
    if (!context.read<AuthProvider>().isLoggedIn) return;
    setState(() => _loading = true);
    try {
      _items = await context.read<ApiService>().favorites();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        actions: [
          if (loggedIn)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: !loggedIn
          ? LoginRequired(message: 'سجّل الدخول لعرض المفضلة', onLogin: () => openAuth(context))
          : _FavoritesBody(loading: _loading, items: _items, onLoad: _load),
    );
  }
}

class _FavoritesBody extends StatefulWidget {
  const _FavoritesBody({required this.loading, required this.items, required this.onLoad});

  final bool loading;
  final List<Listing> items;
  final Future<void> Function() onLoad;

  @override
  State<_FavoritesBody> createState() => _FavoritesBodyState();
}

class _FavoritesBodyState extends State<_FavoritesBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoad());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.items.isEmpty) return const LoadingView();
    if (widget.items.isEmpty) {
      return const EmptyState(message: 'لا توجد إعلانات في المفضلة', icon: Icons.favorite_border);
    }
    return RefreshIndicator(
      onRefresh: widget.onLoad,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: widget.items.length,
        itemBuilder: (context, i) => ListingCard(
          listing: widget.items[i],
          onTap: () => openListing(context, widget.items[i].id),
        ),
      ),
    );
  }
}
