import 'dart:convert';

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
  /// Keep the single replaceable feed entry below browser preference quotas.
  /// A live/bundled feed remains authoritative when a future source response
  /// is larger than this bounded local cache.
  static const maxRawBytes = 4 * 1024 * 1024;
  static final _queue = SequentialOperationQueue();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> load() => _queue.schedule(_loadNow);

  @override
  Future<void> save(String raw) => _queue.schedule(() async {
    if (utf8.encode(raw).length > maxRawBytes) {
      throw StateError('Prospektfeed-Cache überschreitet das Speicherlimit.');
    }
    await _preferences.setString(storageKey, raw);
  });

  Future<String?> _loadNow() => _preferences.getString(storageKey);
}
