import 'package:shared_preferences/shared_preferences.dart';

import 'sequential_operation_queue.dart';

/// Stores only the public, validated prospect feed. Private receipts and user
/// prices never pass through this cache.
abstract interface class ProspectFeedCache {
  Future<String?> load();

  Future<void> save(String raw);
}

class SharedPreferencesProspectFeedCache implements ProspectFeedCache {
  SharedPreferencesProspectFeedCache({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'prospect_feed_cache_v1';
  static final _queue = SequentialOperationQueue();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> load() => _queue.schedule(_loadNow);

  @override
  Future<void> save(String raw) =>
      _queue.schedule(() => _preferences.setString(storageKey, raw));

  Future<String?> _loadNow() => _preferences.getString(storageKey);
}
