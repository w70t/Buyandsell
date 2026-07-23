import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Conversation> _items = [];
  bool _loading = false;
  bool _loadedOnce = false;

  Future<void> _load() async {
    if (!context.read<AuthProvider>().isLoggedIn) return;
    _loadedOnce = true;
    setState(() => _loading = true);
    try {
      _items = await context.read<ApiService>().conversations();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    // إعادة التحميل تلقائياً بعد تسجيل الدخول (التبويب يُبنى قبل الدخول).
    if (!loggedIn) {
      _loadedOnce = false;
    } else if (!_loadedOnce && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: const Text('المحادثات'),
        actions: [
          if (loggedIn)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      body: !loggedIn
          ? LoginRequired(
              message: 'سجّل الدخول لعرض محادثاتك',
              onLogin: () => openAuth(context),
            )
          : _loading && _items.isEmpty
              ? _skeleton()
              : _items.isEmpty
                  ? const EmptyState(
                      message: 'لا توجد محادثات بعد',
                      subtitle:
                          'راسل بائعاً من صفحة أي إعلان وستظهر المحادثة هنا',
                      icon: Icons.forum_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      edgeOffset: glassTopInset(context),
                      child: ListView.separated(
                        padding: EdgeInsets.only(
                            top: glassTopInset(context) + 8,
                            bottom: glassNavInset(context)),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 78,
                          color: sx.outline,
                        ),
                        itemBuilder: (context, i) => _tile(_items[i]),
                      ),
                    ),
    );
  }

  Widget _tile(Conversation c) {
    final sx = context.sx;
    final hasUnread = c.unread > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: InitialsAvatar(name: c.otherUserName, radius: 24),
      title: Row(
        children: [
          Expanded(
            child: Text(
              c.otherUserName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                color: sx.textPrimary,
              ),
            ),
          ),
          Text(
            timeAgo(c.lastAt),
            style: TextStyle(
              fontSize: 11,
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
              color: hasUnread ? sx.accent : sx.textSecondary,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.listingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sx.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          hasUnread ? FontWeight.w700 : FontWeight.w400,
                      color: hasUnread ? sx.textPrimary : sx.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: sx.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${c.unread}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: sx.onAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
      onTap: () async {
        await openChat(
          context,
          conversationId: c.conversationId,
          listingId: c.listingId,
          otherUserId: c.otherUserId,
          title: c.otherUserName,
        );
        _load();
      },
    );
  }

  Widget _skeleton() {
    return SxShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 7,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              SkeletonBox(width: 48, height: 48, radius: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 130, height: 13),
                    SizedBox(height: 8),
                    SkeletonBox(width: 200, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
