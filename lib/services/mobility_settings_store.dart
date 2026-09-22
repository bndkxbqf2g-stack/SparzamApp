import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mobility_settings.dart';

class MobilitySettingsStore {
  static const _key = 'mobility_settings_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<MobilitySettings> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const MobilitySettings();

    try {
      return MobilitySettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const MobilitySettings();
    }
  }

  Future<void> save(MobilitySettings settings) =>
      _preferences.setString(_key, jsonEncode(settings.toJson()));
}
