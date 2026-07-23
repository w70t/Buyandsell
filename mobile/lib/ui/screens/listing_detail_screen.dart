import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../../state/favorites_provider.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';
import '../widgets/skeleton.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final int listingId;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Listing? _listing;
  List<Listing> _similar = [];
  bool _loading = true;
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiService>();
      final l = await api.listing(widget.listingId);
      if (!mounted) return;
      setState(() {
        _listing = l;
        _loading = false;
      });
      // الإعلانات المشابهة من نفس القسم (لا نُفشل الشاشة إن تعذّر جلبها).
      try {
        final page = await api.listings(categoryId: l.category.id, size: 8);
        if (!mounted) return;
        setState(() {
          _similar = page.items.where((e) => e.id != l.id).take(6).toList();
        });
      } catch (_) {}
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _contactSeller() {
    if (!requireLogin(context)) return;
    HapticFeedback.selectionClick();
    final l = _listing!;
    final me = context.read<AuthProvider>().user!;
    if (me.id == l.seller.id) {
      showAppSnack(context, 'هذا إعلانك أنت');
      return;
    }
    openChat(
      context,
      conversationId: conversationKey(l.id, me.id, l.seller.id),
      listingId: l.id,
      otherUserId: l.seller.id,
      title: l.title,
    );
  }

  void _openViewer(int index) {
    final l = _listing!;
    if (l.images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            _GalleryViewer(images: l.images, initialIndex: index),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: SxShimmer(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              SkeletonBox(height: 300, radius: 0),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 22),
                    SizedBox(height: 12),
                    SkeletonBox(width: 220, height: 16),
                    SizedBox(height: 24),
                    SkeletonBox(height: 90, radius: 16),
                    SizedBox(height: 16),
                    SkeletonBox(height: 70, radius: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final l = _listing;
    if (l == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          message: 'الإعلان غير موجود',
          subtitle: 'ربما حُذف الإعلان أو انتهى',
          icon: Icons.sentiment_dissatisfied_outlined,
        ),
      );
    }

    final isFav = context.watch<FavoritesProvider>().contains(l.id);

    return Scaffold(
      // يمتدّ الجسم تحت شريط الإجراء ليظهر تأثير الزجاج (blur) خلفه.
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: sx.bg,
            leading: _CircleAction(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              _CircleAction(
                icon: isFav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFav ? const Color(0xFFFF5A76) : null,
                onTap: () {
                  if (!requireLogin(context)) return;
                  HapticFeedback.lightImpact();
                  context.read<FavoritesProvider>().toggle(l.id);
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _gallery(l)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السعر + شارة التفاوض.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          formatPrice(l.price, currency: l.currency),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: sx.accent,
                          ),
                        ),
                      ),
                      if (l.negotiable)
                        SxBadge(
                          label: 'قابل للتفاوض',
                          color: sx.warning,
                          icon: Icons.handshake_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: sx.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // شرائح المعلومات.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label:
                            '${l.governorate}${l.city.isNotEmpty ? ' - ${l.city}' : ''}',
                      ),
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: timeAgo(l.createdAt),
                      ),
                      _InfoChip(
                        icon: Icons.visibility_outlined,
                        label: '${l.views} مشاهدة',
                      ),
                      _InfoChip(
                        icon: l.condition == 'new'
                            ? Icons.fiber_new_outlined
                            : Icons.autorenew_rounded,
                        label: l.condition == 'new' ? 'جديد' : 'مستعمل',
                      ),
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: l.category.nameAr,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // الوصف.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sx.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: sx.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوصف',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: sx.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.description,
                          style: TextStyle(
                            height: 1.7,
                            fontSize: 14.5,
                            color: sx.textPrimary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // بطاقة البائع.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sx.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: sx.outline),
                    ),
                    child: Row(
                      children: [
                        InitialsAvatar(name: l.seller.name, radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.seller.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: sx.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'البائع',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: sx.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.verified_user_outlined,
                            color: sx.accent, size: 22),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_similar.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'إعلانات مشابهة'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 230,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _similar.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 160,
                    child: ListingCard(
                      listing: _similar[i],
                      onTap: () => openListing(context, _similar[i].id),
                    ),
                  ),
                ),
              ),
            ),
          ],
          // مساحة سفلية كي لا يختفي آخر المحتوى خلف شريط الإجراء الزجاجي.
          SliverToBoxAdapter(
            child: SizedBox(height: 88 + MediaQuery.of(context).viewPadding.bottom),
          ),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              // شبه شفاف كي يظهر المحتوى المموّه خلف الشريط (زجاجي).
              color: sx.surface.withOpacity(0.72),
              border: Border(top: BorderSide(color: sx.outline.withOpacity(0.6))),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: _contactSeller,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                label: const Text('مراسلة البائع'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gallery(Listing l) {
    final sx = context.sx;
    if (l.images.isEmpty) {
      return Container(
        color: sx.surfaceHigh,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 52,
            color: sx.textSecondary,
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageCtrl,
          onPageChanged: (i) => setState(() => _page = i),
          itemCount: l.images.length,
          itemBuilder: (_, i) {
            final image = CachedNetworkImage(
              imageUrl: l.images[i].url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: sx.shimmerBase),
              errorWidget: (_, __, ___) => Container(color: sx.surfaceHigh),
            );
            return GestureDetector(
              onTap: () => _openViewer(i),
              // الصورة الأولى تشترك بوسم Hero مع بطاقة الإعلان.
              child: i == 0
                  ? Hero(tag: 'listing-${l.id}', child: image)
                  : image,
            );
          },
        ),
        // تظليل سفلي خفيف لوضوح النقاط.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (l.images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                l.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _page ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: i == _page ? Colors.white : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// زر دائري فوق الصورة (رجوع/مفضلة).
class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withOpacity(0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 22, color: color ?? Colors.white),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: sx.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sx.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: sx.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: sx.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// عارض صور بملء الشاشة مع تكبير/تصغير.
class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.images, required this.initialIndex});

  final List<ListingImage> images;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _ctrl =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          '${_index + 1} / ${widget.images.length}',
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _ctrl,
        onPageChanged: (i) => setState(() => _index = i),
        itemCount: widget.images.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.images[i].url,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
