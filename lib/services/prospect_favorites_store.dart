import 'package:shared_preferences/shared_preferences.dart';

/// Persists the retailers a shopper explicitly pinned in the prospect feed.
///
/// The store names are the canonical names from the validated prospect feed.
class ProspectFavoritesStore {
  ProspectFavoritesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'prospect_favorite_stores_v1';

  final SharedPreferencesAsync _preferences;

  /// Returns null when the shopper has never configured favorites.
  Future<Set<String>?> load() async {
    List<String>? values;
    try {
      values = await _preferences.getStringList(storageKey);
    } catch (_) {
      // Widget tests and unsupported platforms have no preference channel.
      return null;
    }
    if (values == null) return null;
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<void> save(Iterable<String> storeNames) {
    final values = storeNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return _preferences.setStringList(storageKey, values);
  }
}
