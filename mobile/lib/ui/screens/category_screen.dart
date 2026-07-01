import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/category_icons.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../widgets/common.dart';
import '../widgets/listing_grid.dart';
import '../widgets/skeleton.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final Category category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  static const _pageSize = 20;

  final List<Listing> _listings = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await context
          .read<ApiService>()
          .listings(categoryId: widget.category.id, page: 1, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _listings
          ..clear()
          ..addAll(page.items);
        _page = 1;
        _hasMore = page.items.length >= _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final page = await context.read<ApiService>().listings(
          categoryId: widget.category.id, page: _page + 1, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _page += 1;
        _listings.addAll(page.items);
        _hasMore = page.items.length >= _pageSize;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) _loadMore();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(widget.category.icon);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(categoryIcon(widget.category.icon),
                  color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(widget.category.nameAr),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_loading)
                const SliverListingGridSkeleton(count: 6)
              else if (_listings.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    message: 'لا توجد إعلانات في هذا القسم',
                    subtitle: 'كن أول من ينشر إعلاناً هنا',
                  ),
                )
              else ...[
                SliverListingGrid(items: _listings),
                SliverLoadingFooter(visible: _loadingMore),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
