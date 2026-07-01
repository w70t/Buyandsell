import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/token_store.dart';
import 'services/api_service.dart';
import 'state/auth_provider.dart';
import 'state/favorites_provider.dart';
import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokens = TokenStore();
  final client = ApiClient(tokens);
  final api = ApiService(client);

  final auth = AuthProvider(api, tokens);
  final favorites = FavoritesProvider(api);

  // When the refresh token is rejected, drop the session app-wide.
  client.onSessionExpired = () {
    auth.logout();
    favorites.clear();
  };

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
      ],
      child: const SouqnaApp(),
    ),
  );
}
