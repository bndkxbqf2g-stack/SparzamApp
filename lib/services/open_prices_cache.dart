import 'package:shared_preferences/shared_preferences.dart';

/// Raw Open Prices response cache. Parsing stays in the adapter so cached
/// responses use the same validation path as live responses.
abstract interface class OpenPricesCache {
  Future<String?> load(String productCode);

  Future<void> save(String productCode, String responseBody);
}

class SharedPreferencesOpenPricesCache implements OpenPricesCache {
  SharedPreferencesOpenPricesCache({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences;

  static const keyPrefix = 'open_prices_response_v1|';
  final SharedPreferencesAsync? _preferences;
  late final SharedPreferencesAsync _lazyPreferences =
      _preferences ?? SharedPreferencesAsync();

  @override
  Future<String?> load(String productCode) async {
    final code = productCode.trim();
    if (code.isEmpty) return null;
    try {
      return await _lazyPreferences.getString(_key(code));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(String productCode, String responseBody) async {
    final code = productCode.trim();
    if (code.isEmpty || responseBody.trim().isEmpty) return;
    try {
      await _lazyPreferences.setString(_key(code), responseBody);
    } catch (_) {
      // Cache availability must never block a live response.
    }
  }

  String _key(String code) => '$keyPrefix${Uri.encodeComponent(code)}';
}
