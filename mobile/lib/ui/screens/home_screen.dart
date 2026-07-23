import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/category_icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../widgets/common.dart';
import '../widgets/listing_grid.dart';
import '../widgets/skeleton.dart';
import 'category_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pageSize = 20;

  late ApiService _api;
  List<Category> _categories = [];
  final List<Listing> _listings = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = context.read<ApiService>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await _api.categories();
      final page = await _api.listings(page: 1, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _categories = cats.where((c) => c.slug != 'all').toList();
        _listings
          ..clear()
          ..addAll(page.items);
        _page = 1;
        _hasMore = page.items.length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالخادم';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _api.listings(page: _page + 1, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _page += 1;
        _listings.addAll(page.items);
        _hasMore = page.items.length >= _pageSize;
      });
    } catch (_) {
      // نتجاهل فشل تحميل المزيد — تبقى القائمة الحالية.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) {
      _loadMore();
    }
    return false;
  }

  void _openSearch({int? categoryId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialCategoryId: categoryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        edgeOffset: 120,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                toolbarHeight: 58,
                titleSpacing: 16,
                // شريط زجاجي: شفاف مع تمويه المحتوى المارّ خلفه عند التمرير.
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: const GlassBar(),
                title: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'سوقنا',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: sx.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          'بيع واشترِ في كل العراق',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: sx.textSecondary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(62),
                  child: _SearchBar(onTap: _openSearch),
                ),
              ),
              if (_loading) ...[
                const SliverToBoxAdapter(child: _CategoriesSkeleton()),
                const SliverListingGridSkeleton(count: 6),
              ] else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    message: _error!,
                    subtitle: 'تأكد من اتصالك بالإنترنت وحاول مجدداً',
                    icon: Icons.wifi_off_rounded,
                    actionLabel: 'إعادة المحاولة',
                    onAction: _load,
                  ),
                )
              else ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(title: 'تصفح الأقسام'),
                ),
                SliverToBoxAdapter(child: _categoriesRow()),
                const SliverToBoxAdapter(
                  child: SectionHeader(title: 'أحدث الإعلانات'),
                ),
                if (_listings.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message: 'لا توجد إعلانات بعد',
                      subtitle: 'كن أول من ينشر إعلاناً في سوقنا',
                      icon: Icons.storefront_outlined,
                    ),
                  )
                else ...[
                  SliverListingGrid(items: _listings),
                  SliverLoadingFooter(visible: _loadingMore),
                ],
              ],
              // مساحة سفلية بمقدار الشريط الزجاجي كي لا يختفي آخر الإعلانات خلفه.
              SliverToBoxAdapter(
                child: SizedBox(height: glassNavInset(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoriesRow() {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = _categories[i];
          final color = categoryColor(c.icon);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CategoryScreen(category: c)),
              );
            },
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  PressableScale(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: categoryGradient(c.icon),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(categoryIcon(c.icon),
                          color: Colors.white, size: 27),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.nameAr,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.sx.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return SxShimmer(
      child: SizedBox(
        height: 106,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => const Column(
            children: [
              SkeletonBox(width: 58, height: 58, radius: 18),
              SizedBox(height: 8),
              SkeletonBox(width: 44, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final void Function({int? categoryId}) onTap;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTap: () => onTap(),
        child: PressableScale(
          pressedScale: 0.985,
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: sx.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sx.outline),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: sx.textSecondary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ابحث عن سيارات، هواتف، عقارات…',
                  style: TextStyle(color: sx.textSecondary, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: sx.accentSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.tune_rounded, color: sx.accent, size: 16),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
