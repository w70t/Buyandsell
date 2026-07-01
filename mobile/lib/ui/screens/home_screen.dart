import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/category_icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';
import 'category_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ApiService _api;
  List<Category> _categories = [];
  List<Listing> _listings = [];
  bool _loading = true;
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
      final page = await _api.listings(size: 30);
      setState(() {
        _categories = cats.where((c) => c.slug != 'all').toList();
        _listings = page.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل الإعلانات';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            }),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? EmptyState(message: _error!, icon: Icons.wifi_off)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(child: _categoriesRow()),
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                                  child: Text('أحدث الإعلانات',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              if (_listings.isEmpty)
                                const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: EmptyState(message: 'لا توجد إعلانات بعد'),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.all(12),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 0.72,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, i) => ListingCard(
                                        listing: _listings[i],
                                        onTap: () => openListing(context, _listings[i].id),
                                      ),
                                      childCount: _listings.length,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoriesRow() {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = _categories[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CategoryScreen(category: c)),
            ),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.tile,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(categoryIcon(c.icon), color: AppTheme.accent, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(c.nameAr,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 8),
              Text('ابحث عن سيارات، هواتف، عقارات…', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
