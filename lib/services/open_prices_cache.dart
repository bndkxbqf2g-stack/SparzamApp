import 'package:shared_preferences/shared_preferences.dart';

import 'sequential_operation_queue.dart';

/// Raw Open Prices response cache. Parsing stays in the adapter so cached
/// responses use the same validation path as live responses.
abstract interface class OpenPricesCache {
  Future<String?> load(String productCode);

  Future<void> save(String productCode, String responseBody);
}

class SharedPreferencesOpenPricesCache implements OpenPricesCache {
  SharedPreferencesOpenPricesCache({this._preferences});

  static const keyPrefix = 'open_prices_response_v1|';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync? _preferences;
  late final SharedPreferencesAsync _lazyPreferences =
      _preferences ?? SharedPreferencesAsync();

  @override
  Future<String?> load(String productCode) {
    final code = productCode.trim();
    if (code.isEmpty) return Future<String?>.value(null);
    return _queue.schedule(() => _loadNow(code));
  }

  @override
  Future<void> save(String productCode, String responseBody) {
    final code = productCode.trim();
    if (code.isEmpty || responseBody.trim().isEmpty) {
      return Future<void>.value();
    }
    return _queue.schedule(() => _saveNow(code, responseBody));
  }

  Future<String?> _loadNow(String code) async {
    try {
      return await _lazyPreferences.getString(_key(code));
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveNow(String code, String responseBody) async {
    try {
      await _lazyPreferences.setString(_key(code), responseBody);
    } catch (_) {
      // Cache availability must never block a live response.
    }
  }

  String _key(String code) => '$keyPrefix${Uri.encodeComponent(code)}';
}
