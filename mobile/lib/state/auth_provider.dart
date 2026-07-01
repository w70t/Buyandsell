import 'package:flutter/foundation.dart';

import '../core/token_store.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._tokens);

  final ApiService _api;
  final TokenStore _tokens;

  UserModel? user;
  bool booting = true;

  bool get isLoggedIn => user != null;

  Future<void> bootstrap() async {
    await _tokens.load();
    if (_tokens.isLoggedIn) {
      try {
        user = await _api.me();
      } catch (_) {
        await _tokens.clear();
        user = null;
      }
    }
    booting = false;
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    user = await _api.login(phone, password);
    notifyListeners();
  }

  Future<void> register(String name, String phone, String password) async {
    user = await _api.register(name, phone, password);
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokens.clear();
    user = null;
    notifyListeners();
  }
}
