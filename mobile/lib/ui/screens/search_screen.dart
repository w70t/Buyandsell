import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/governorates.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialCategoryId});

  final int? initialCategoryId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late ApiService _api;
  final _queryCtrl = TextEditingController();
  Timer? _debounce;

  List<Category> _categories = [];
  List<Listing> _results = [];
  int? _categoryId;
  String? _governorate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _api = context.read<ApiService>();
      _categories = (await _api.categories()).where((c) => c.slug != 'all').toList();
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
        size: 40,
      );
      setState(() {
        _results = page.items;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بحث')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _queryCtrl,
              autofocus: widget.initialCategoryId == null,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'ابحث…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _queryCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _queryCtrl.clear();
                          _search();
                        },
                      ),
              ),
            ),
          ),
          _chips(
            selected: _categoryId,
            allLabel: 'كل الأقسام',
            items: {for (final c in _categories) c.id: c.nameAr},
            onSelect: (id) {
              setState(() => _categoryId = id);
              _search();
            },
          ),
          _chips(
            selected: _governorate,
            allLabel: 'كل المحافظات',
            items: {for (final g in iraqGovernorates) g: g},
            onSelect: (g) {
              setState(() => _governorate = g);
              _search();
            },
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _results.isEmpty
                    ? const EmptyState(message: 'لا توجد نتائج', icon: Icons.search_off)
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, i) => ListingCard(
                          listing: _results[i],
                          onTap: () => openListing(context, _results[i].id),
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
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(allLabel),
              selected: selected == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          for (final entry in items.entries)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selected == entry.key,
                onSelected: (_) => onSelect(selected == entry.key ? null : entry.key),
              ),
            ),
        ],
      ),
    );
  }
}
