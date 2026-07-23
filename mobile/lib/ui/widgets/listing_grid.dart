import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../navigation.dart';
import 'common.dart';
import 'listing_card.dart';

/// شبكة الإعلانات الموحّدة (sliver) المستخدمة في كل الشاشات.
class SliverListingGrid extends StatelessWidget {
  const SliverListingGrid({super.key, required this.items});

  final List<Listing> items;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => EntranceFade(
            index: i,
            child: ListingCard(
              listing: items[i],
              heroTag: 'listing-${items[i].id}',
              onTap: () => openListing(context, items[i].id),
            ),
          ),
          childCount: items.length,
        ),
      ),
    );
  }
}

/// مؤشر «جارٍ تحميل المزيد» أسفل الشبكات ذات التمرير اللانهائي.
class SliverLoadingFooter extends StatelessWidget {
  const SliverLoadingFooter({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: visible
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ),
            )
          : const SizedBox(height: 8),
    );
  }
}
