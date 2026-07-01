import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../navigation.dart';
import '../widgets/common.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  List<Listing> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await context.read<ApiService>().myListings();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(Listing l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: Text('هل تريد حذف "${l.title}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await context.read<ApiService>().deleteListing(l.id);
        setState(() => _items.removeWhere((e) => e.id == l.id));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعلاناتي')),
      body: _loading
          ? const LoadingView()
          : _items.isEmpty
              ? const EmptyState(message: 'لم تنشر أي إعلان بعد')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final l = _items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => openListing(context, l.id),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: l.cover != null
                                ? CachedNetworkImage(imageUrl: l.cover!, fit: BoxFit.cover)
                                : Container(color: AppTheme.surface2, child: const Icon(Icons.image_not_supported_outlined)),
                          ),
                        ),
                        title: Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${formatPrice(l.price)} • ${l.status == 'active' ? 'نشط' : l.status}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _delete(l),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
