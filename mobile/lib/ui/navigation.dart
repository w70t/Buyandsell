import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/auth_provider.dart';
import '../state/favorites_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/listing_detail_screen.dart';

Future<void> openAuth(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AuthScreen()),
  );
  if (context.mounted && context.read<AuthProvider>().isLoggedIn) {
    await context.read<FavoritesProvider>().refresh();
  }
}

void openListing(BuildContext context, int id) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: id)),
  );
}

void openChat(
  BuildContext context, {
  required String conversationId,
  required int listingId,
  required int otherUserId,
  required String title,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        conversationId: conversationId,
        listingId: listingId,
        otherUserId: otherUserId,
        title: title,
      ),
    ),
  );
}

String conversationKey(int listingId, int a, int b) {
  final low = a <= b ? a : b;
  final high = a <= b ? b : a;
  return 'c.$listingId.$low.$high';
}

/// Convenience to require login before an action.
bool requireLogin(BuildContext context) {
  final auth = context.read<AuthProvider>();
  if (!auth.isLoggedIn) {
    openAuth(context);
    return false;
  }
  return true;
}

extension ListingNav on Listing {
  void open(BuildContext context) => openListing(context, id);
}
