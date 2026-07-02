import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';

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
    final sx = context.sx;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: Text('هل تريد حذف «${l.title}» نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('حذف', style: TextStyle(color: sx.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<ApiService>().deleteListing(l.id);
        setState(() => _items.removeWhere((e) => e.id == l.id));
        if (mounted) {
          showAppSnack(context, 'تم حذف الإعلان', type: SnackType.success);
        }
      } catch (_) {
        if (mounted) {
          showAppSnack(context, 'تعذّر حذف الإعلان', type: SnackType.error);
        }
      }
    }
  }

  (String, Color) _statusOf(Listing l, SxColors sx) {
    switch (l.status) {
      case 'active':
        return ('نشط', sx.success);
      case 'sold':
        return ('مُباع', sx.danger);
      case 'hidden':
        return ('مخفي', sx.textSecondary);
      default:
        return (l.status, sx.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Scaffold(
      appBar: AppBar(title: const Text('إعلاناتي')),
      body: _loading
          ? _skeleton()
          : _items.isEmpty
              ? const EmptyState(
                  message: 'لم تنشر أي إعلان بعد',
                  subtitle: 'اضغط زر «بيع» في الشريط السفلي وابدأ البيع',
                  icon: Icons.inventory_2_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final l = _items[i];
                      final (statusLabel, statusColor) = _statusOf(l, sx);
                      return Material(
                        color: sx.surface,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => openListing(context, l.id),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: sx.outline),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: l.cover != null
                                        ? CachedNetworkImage(
                                            imageUrl: l.cover!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                Container(color: sx.shimmerBase),
                                          )
                                        : Container(
                                            color: sx.surfaceHigh,
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: sx.textSecondary,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: sx.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatPrice(l.price,
                                            currency: l.currency),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: sx.accent,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          SxBadge(
                                            label: statusLabel,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.visibility_outlined,
                                              size: 13,
                                              color: sx.textSecondary),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${l.views}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: sx.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: sx.danger),
                                  onPressed: () => _delete(l),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _skeleton() {
    return SxShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonBox(height: 92, radius: 16),
        ),
      ),
    );
  }
}
