import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider(this._api);

  final ApiService _api;
  final Set<int> _ids = {};

  bool contains(int id) => _ids.contains(id);
  Set<int> get ids => _ids;

  Future<void> refresh() async {
    try {
      final ids = await _api.favoriteIds();
      _ids
        ..clear()
        ..addAll(ids);
      notifyListeners();
    } catch (_) {
      // ignore — user may be logged out
    }
  }

  void clear() {
    _ids.clear();
    notifyListeners();
  }

  /// Optimistic toggle with rollback on failure.
  Future<void> toggle(int id) async {
    final wasFav = _ids.contains(id);
    if (wasFav) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    try {
      if (wasFav) {
        await _api.removeFavorite(id);
      } else {
        await _api.addFavorite(id);
      }
    } catch (_) {
      // rollback
      if (wasFav) {
        _ids.add(id);
      } else {
        _ids.remove(id);
      }
      notifyListeners();
    }
  }
}
