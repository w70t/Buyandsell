import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/governorates.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../widgets/common.dart';
import '../widgets/listing_grid.dart';
import '../widgets/skeleton.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialCategoryId});

  final int? initialCategoryId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _pageSize = 20;

  late ApiService _api;
  final _queryCtrl = TextEditingController();
  Timer? _debounce;

  List<Category> _categories = [];
  final List<Listing> _results = [];
  int _total = 0;

  int? _categoryId;
  String? _governorate;
  int? _minPrice;
  int? _maxPrice;
  String _sort = 'recent';

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;

  static const _sortLabels = {
    'recent': 'الأحدث',
    'price_asc': 'السعر: من الأقل',
    'price_desc': 'السعر: من الأعلى',
  };

  bool get _hasPriceFilter => _minPrice != null || _maxPrice != null;
  bool get _filtersActive => _hasPriceFilter || _sort != 'recent';

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _api = context.read<ApiService>();
      try {
        _categories =
            (await _api.categories()).where((c) => c.slug != 'all').toList();
      } catch (_) {}
      await _search();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    setState(() {}); // لتحديث زر المسح
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final page = await _api.listings(
        q: _queryCtrl.text.trim(),
        categoryId: _categoryId,
        governorate: _governorate,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sort: _sort,
        page: 1,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _results
          ..clear()
          ..addAll(page.items);
        _total = page.total;
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
      final page = await _api.listings(
        q: _queryCtrl.text.trim(),
        categoryId: _categoryId,
        governorate: _governorate,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sort: _sort,
        page: _page + 1,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page += 1;
        _results.addAll(page.items);
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

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sort: _sort,
        sortLabels: _sortLabels,
      ),
    );
    if (result != null) {
      setState(() {
        _minPrice = result.minPrice;
        _maxPrice = result.maxPrice;
        _sort = result.sort;
      });
      _search();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    autofocus: widget.initialCategoryId == null,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'عن ماذا تبحث؟',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _queryCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _queryCtrl.clear();
                                setState(() {});
                                _search();
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _openFilters,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _filtersActive ? sx.accent : sx.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _filtersActive ? sx.accent : sx.outline,
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: _filtersActive ? sx.onAccent : sx.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _chips<int>(
            selected: _categoryId,
            allLabel: 'كل الأقسام',
            items: {for (final c in _categories) c.id: c.nameAr},
            onSelect: (id) {
              setState(() => _categoryId = id);
              _search();
            },
          ),
          const SizedBox(height: 6),
          _chips<String>(
            selected: _governorate,
            allLabel: 'كل المحافظات',
            items: {for (final g in iraqGovernorates) g: g},
            onSelect: (g) {
              setState(() => _governorate = g);
              _search();
            },
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: CustomScrollView(
                slivers: [
                  if (_loading)
                    const SliverListingGridSkeleton(count: 6)
                  else if (_results.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        message: 'لا توجد نتائج',
                        subtitle: 'جرّب كلمات أو فلاتر مختلفة',
                        icon: Icons.search_off_rounded,
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Text(
                          'النتائج: $_total إعلان',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sx.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    SliverListingGrid(items: _results),
                    SliverLoadingFooter(visible: _loadingMore),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips<T>({
    required T? selected,
    required String allLabel,
    required Map<T, String> items,
    required void Function(T?) onSelect,
  }) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(allLabel, selected == null, () => onSelect(null)),
          for (final entry in items.entries)
            _chip(
              entry.value,
              selected == entry.key,
              () => onSelect(selected == entry.key ? null : entry.key),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final sx = context.sx;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? sx.accent : sx.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? sx.accent : sx.outline),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? sx.onAccent : sx.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterResult {
  const _FilterResult({this.minPrice, this.maxPrice, required this.sort});

  final int? minPrice;
  final int? maxPrice;
  final String sort;
}

/// ورقة فلاتر: نطاق السعر + الترتيب.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.minPrice,
    required this.maxPrice,
    required this.sort,
    required this.sortLabels,
  });

  final int? minPrice;
  final int? maxPrice;
  final String sort;
  final Map<String, String> sortLabels;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final TextEditingController _min = TextEditingController(
      text: widget.minPrice?.toString() ?? '');
  late final TextEditingController _max = TextEditingController(
      text: widget.maxPrice?.toString() ?? '');
  late String _sort = widget.sort;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  int? _parse(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفلاتر',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: sx.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'السعر (د.ع)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: sx.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'من'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'إلى'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'الترتيب',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: sx.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in widget.sortLabels.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _sort == entry.key,
                  onSelected: (_) => setState(() => _sort = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    const _FilterResult(sort: 'recent'),
                  ),
                  child: const Text('مسح الفلاتر'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _FilterResult(
                      minPrice: _parse(_min.text),
                      maxPrice: _parse(_max.text),
                      sort: _sort,
                    ),
                  ),
                  child: const Text('تطبيق'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
