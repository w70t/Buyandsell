import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final Category category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Listing> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final page = await context
          .read<ApiService>()
          .listings(categoryId: widget.category.id, size: 40);
      setState(() {
        _listings = page.items;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.nameAr)),
      body: _loading
          ? const LoadingView()
          : _listings.isEmpty
              ? const EmptyState(message: 'لا توجد إعلانات في هذا القسم')
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _listings.length,
                  itemBuilder: (context, i) => ListingCard(
                    listing: _listings[i],
                    onTap: () => openListing(context, _listings[i].id),
                  ),
                ),
    );
  }
}
