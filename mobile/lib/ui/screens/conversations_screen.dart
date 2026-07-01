import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../navigation.dart';
import '../widgets/common.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Conversation> _items = [];
  bool _loading = false;

  Future<void> _load() async {
    if (!context.read<AuthProvider>().isLoggedIn) return;
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
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        actions: [if (loggedIn) IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: !loggedIn
          ? LoginRequired(message: 'سجّل الدخول لعرض محادثاتك', onLogin: () => openAuth(context))
          : _loading && _items.isEmpty
              ? const LoadingView()
              : _items.isEmpty
                  ? const EmptyState(message: 'لا توجد محادثات بعد', icon: Icons.forum_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = _items[i];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.tile,
                              child: Icon(Icons.person, color: AppTheme.accent),
                            ),
                            title: Text(c.listingTitle,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${c.otherUserName}: ${c.lastMessage}',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(timeAgo(c.lastAt),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                if (c.unread > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                        color: AppTheme.accent, shape: BoxShape.circle),
                                    child: Text('${c.unread}',
                                        style: const TextStyle(fontSize: 10, color: Colors.black)),
                                  ),
                              ],
                            ),
                            onTap: () async {
                              await openChatAndWait(context, c);
                              _load();
                            },
                          );
                        },
                      ),
                    ),
    );
  }

  Future<void> openChatAndWait(BuildContext context, Conversation c) async {
    openChat(
      context,
      conversationId: c.conversationId,
      listingId: c.listingId,
      otherUserId: c.otherUserId,
      title: c.listingTitle,
    );
  }
}
