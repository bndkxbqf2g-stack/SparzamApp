import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sequential_operation_queue.dart';

/// Stores only the public, validated prospect feed. Private receipts and user
/// prices never pass through this cache.
abstract interface class ProspectFeedCache {
  Future<String?> load();

  Future<void> save(String raw);
}

/// Optional metadata companion for caches that can persist the source/transport
/// capture time without changing the public feed payload. The raw feed is
/// passed back so stale metadata can never be attached to a different body.
abstract interface class ProspectFeedCaptureMetadataCache {
  Future<DateTime?> loadCapturedAt(String raw);

  Future<void> saveCapturedAt(String raw, DateTime value);
}

class SharedPreferencesProspectFeedCache
    implements ProspectFeedCache, ProspectFeedCaptureMetadataCache {
  SharedPreferencesProspectFeedCache({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'prospect_feed_cache_v1';
  static const capturedAtStorageKey = 'prospect_feed_captured_at_v1';
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

  @override
  Future<DateTime?> loadCapturedAt(String raw) =>
      _queue.schedule(() async {
        final cachedRaw = await _preferences.getString(storageKey);
        if (cachedRaw != raw) return null;
        final value = await _preferences.getString(capturedAtStorageKey);
        return DateTime.tryParse(value ?? '');
      });

  @override
  Future<void> saveCapturedAt(String raw, DateTime value) =>
      _queue.schedule(() async {
        final cachedRaw = await _preferences.getString(storageKey);
        if (cachedRaw != raw) return;
        await _preferences.setString(
          capturedAtStorageKey,
          value.toIso8601String(),
        );
      });

  Future<String?> _loadNow() => _preferences.getString(storageKey);
}
