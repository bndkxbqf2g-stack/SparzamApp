import 'package:shared_preferences/shared_preferences.dart';

/// Stores only the public, validated prospect feed. User data and private
/// receipts never pass through this cache.
abstract interface class ProspectFeedCache {
  Future<String?> load();

  Future<void> save(String raw);
}

class SharedPreferencesProspectFeedCache implements ProspectFeedCache {
  SharedPreferencesProspectFeedCache({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'prospect_feed_cache_v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> load() => _preferences.getString(storageKey);

  @override
  Future<void> save(String raw) async {
    await _preferences.setString(storageKey, raw);
  }
}
