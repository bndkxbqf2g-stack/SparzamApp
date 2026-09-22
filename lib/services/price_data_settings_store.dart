import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/price_data_settings.dart';

class PriceDataSettingsStore {
  static const _key = 'price_data_settings_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<PriceDataSettings> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const PriceDataSettings();

    try {
      return PriceDataSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const PriceDataSettings();
    }
  }

  Future<void> save(PriceDataSettings settings) =>
      _preferences.setString(_key, jsonEncode(settings.toJson()));
}
