import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.listingId,
    required this.otherUserId,
    required this.title,
  });

  final String conversationId;
  final int listingId;
  final int otherUserId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // تحديث دوري خفيف حتى تصل الرسائل الجديدة دون إعادة فتح الشاشة.
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _messages =
          await context.read<ApiService>().conversation(widget.conversationId);
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _refresh() async {
    if (_loading || _sending) return;
    try {
      final fresh =
          await context.read<ApiService>().conversation(widget.conversationId);
      if (mounted && fresh.length != _messages.length) {
        setState(() => _messages = fresh);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await context
          .read<ApiService>()
          .sendMessage(widget.listingId, widget.otherUserId, text);
      _input.clear();
      setState(() => _messages = [..._messages, msg]);
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر إرسال الرسالة')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    final myId = context.read<AuthProvider>().user?.id ?? -1;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            InitialsAvatar(name: widget.title, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const EmptyState(
                        message: 'ابدأ المحادثة الآن',
                        subtitle: 'كن مهذباً واتفقا على مكان عام وآمن للتسليم',
                        icon: Icons.waving_hand_outlined,
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(14),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final mine = m.senderId == myId;
                          final showDate = i == 0 ||
                              chatDate(_messages[i - 1].createdAt) !=
                                  chatDate(m.createdAt);
                          return Column(
                            children: [
                              if (showDate) _dateSeparator(m.createdAt),
                              _bubble(m, mine),
                            ],
                          );
                        },
                      ),
          ),
          _composer(sx),
        ],
      ),
    );
  }

  Widget _dateSeparator(DateTime dt) {
    final sx = context.sx;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: sx.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          chatDate(dt),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: sx.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _bubble(Message m, bool mine) {
    final sx = context.sx;
    // في واجهة RTL: رسائلي على اليسار البصري، والطرف الآخر على اليمين.
    return Align(
      alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          color: mine ? sx.bubbleMine : sx.bubbleOther,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(16),
            topLeft: const Radius.circular(16),
            bottomRight: Radius.circular(mine ? 16 : 4),
            bottomLeft: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              m.body,
              style: TextStyle(
                color: mine ? sx.onBubbleMine : sx.onBubbleOther,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              shortTime(m.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: (mine ? sx.onBubbleMine : sx.onBubbleOther)
                    .withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer(SxColors sx) {
    return Container(
      decoration: BoxDecoration(
        color: sx.surface,
        border: Border(top: BorderSide(color: sx.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(hintText: 'اكتب رسالة…'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : _send,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
