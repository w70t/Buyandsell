import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../state/favorites_provider.dart';
import 'common.dart';

/// بطاقة إعلان: صورة بشارات الحالة، زر مفضلة متحرك، سعر بارز وموقع/وقت.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    final isFav = context
        .select<FavoritesProvider, bool>((f) => f.contains(listing.id));

    return Material(
      color: sx.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: sx.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: listing.cover != null
                        ? CachedNetworkImage(
                            imageUrl: listing.cover!,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 250),
                            placeholder: (_, __) =>
                                Container(color: sx.shimmerBase),
                            errorWidget: (_, __, ___) => const _NoImage(),
                          )
                        : const _NoImage(),
                  ),
                  // شارة الحالة (جديد) أعلى اليمين.
                  if (listing.condition == 'new')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: SxBadge(label: 'جديد', color: sx.success),
                    ),
                  if (listing.status == 'sold')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: SxBadge(label: 'مُباع', color: sx.danger),
                    ),
                  // زر المفضلة أعلى اليسار.
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _FavButton(
                      isFav: isFav,
                      onPressed: () => _toggleFav(context),
                    ),
                  ),
                  // عدد الصور.
                  if (listing.images.length > 1)
                    Positioned(
                      bottom: 6,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              '${listing.images.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: sx.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatPrice(listing.price, currency: listing.currency),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sx.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: sx.textSecondary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${listing.governorate} • ${timeAgo(listing.createdAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: sx.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFav(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول لإضافة المفضلة')),
      );
      return;
    }
    context.read<FavoritesProvider>().toggle(listing.id);
  }
}

/// زر مفضلة بنبضة عند التبديل.
class _FavButton extends StatelessWidget {
  const _FavButton({required this.isFav, required this.onPressed});

  final bool isFav;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: AnimatedScale(
            scale: isFav ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 19,
              color: isFav ? const Color(0xFFFF5A76) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Container(
      color: sx.surfaceHigh,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: sx.textSecondary,
          size: 34,
        ),
      ),
    );
  }
}
