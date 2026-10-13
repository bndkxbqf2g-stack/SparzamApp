import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/price_data_settings.dart';
import 'sequential_operation_queue.dart';

class PriceDataSettingsStore {
  static const _key = 'price_data_settings_v1';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<PriceDataSettings> load() => _queue.schedule(_loadNow);

  Future<PriceDataSettings> _loadNow() async {
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
      _queue.schedule(() => _saveNow(settings));

  Future<void> _saveNow(PriceDataSettings settings) =>
      _preferences.setString(_key, jsonEncode(settings.toJson()));
}
