import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../../state/favorites_provider.dart';
import '../navigation.dart';
import '../widgets/common.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final int listingId;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Listing? _listing;
  bool _loading = true;
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final l = await context.read<ApiService>().listing(widget.listingId);
      setState(() {
        _listing = l;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _contactSeller() {
    if (!requireLogin(context)) return;
    final l = _listing!;
    final me = context.read<AuthProvider>().user!;
    if (me.id == l.seller.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا إعلانك')),
      );
      return;
    }
    openChat(
      context,
      conversationId: conversationKey(l.id, me.id, l.seller.id),
      listingId: l.id,
      otherUserId: l.seller.id,
      title: l.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    final l = _listing;
    if (l == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(message: 'الإعلان غير موجود'),
      );
    }

    final isFav = context.watch<FavoritesProvider>().contains(l.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الإعلان'),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppTheme.accent : null),
            onPressed: () {
              if (!requireLogin(context)) return;
              context.read<FavoritesProvider>().toggle(l.id);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _gallery(l),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(formatPrice(l.price, currency: l.currency),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                if (l.negotiable)
                  const Text('قابل للتفاوض', style: TextStyle(color: Colors.orangeAccent)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${l.governorate}${l.city.isNotEmpty ? ' - ${l.city}' : ''}',
                        style: const TextStyle(color: Colors.grey)),
                    const Spacer(),
                    Text(timeAgo(l.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('الوصف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(l.description, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.tile,
                      child: Icon(Icons.person, color: AppTheme.accent),
                    ),
                    title: Text(l.seller.name),
                    subtitle: Text('${l.views} مشاهدة'),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: AppTheme.surface,
        padding: const EdgeInsets.all(12),
        child: SafeArea(
          top: false,
          child: ElevatedButton.icon(
            onPressed: _contactSeller,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('مراسلة البائع'),
          ),
        ),
      ),
    );
  }

  Widget _gallery(Listing l) {
    if (l.images.isEmpty) {
      return Container(
        height: 260,
        color: AppTheme.surface2,
        child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: l.images.length,
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: l.images[i].url,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(color: AppTheme.surface2),
            ),
          ),
          if (l.images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  l.images.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page ? AppTheme.accent : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
