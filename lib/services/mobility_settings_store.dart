import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mobility_settings.dart';
import 'sequential_operation_queue.dart';

class MobilitySettingsStore {
  static const _key = 'mobility_settings_v1';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<MobilitySettings> load() => _queue.schedule(_loadNow);

  Future<MobilitySettings> _loadNow() async {
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
      _queue.schedule(() => _saveNow(settings));

  Future<void> _saveNow(MobilitySettings settings) =>
      _preferences.setString(_key, jsonEncode(settings.toJson()));
}
