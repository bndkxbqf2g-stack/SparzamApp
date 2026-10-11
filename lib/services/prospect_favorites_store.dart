import 'package:shared_preferences/shared_preferences.dart';

/// Persists the retailers a shopper explicitly pinned in the prospect feed.
///
/// The store names are the canonical names from the validated prospect feed.
class ProspectFavoritesStore {
  ProspectFavoritesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const storageKey = 'prospect_favorite_stores_v1';

  final SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync? _platformPreferences() {
    if (_preferences != null) return _preferences;
    try {
      return SharedPreferencesAsync();
    } catch (_) {
      // Widget tests and unsupported platforms have no preference channel.
      return null;
    }
  }

  /// Returns null when the shopper has never configured favorites.
  Future<Set<String>?> load() async {
    final preferences = _platformPreferences();
    if (preferences == null) return null;

    List<String>? values;
    try {
      values = await preferences.getStringList(storageKey);
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

  Future<void> save(Iterable<String> storeNames) async {
    final preferences = _platformPreferences();
    if (preferences == null) return;

    final values = storeNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    try {
      await preferences.setStringList(storageKey, values);
    } catch (_) {
      // Keep the feed usable when persistence is unavailable.
    }
  }
}
