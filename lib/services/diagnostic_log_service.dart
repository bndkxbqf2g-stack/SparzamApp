import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/diagnostic_log_entry.dart';

class DiagnosticLogService {
  static const _key = 'diagnostic_log_v1';
  static const _maxEntries = 100;
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<DiagnosticLogEntry>> load() async {
    final values = await _preferences.getStringList(_key);
    if (values == null) return <DiagnosticLogEntry>[];
    final entries = <DiagnosticLogEntry>[];
    for (final value in values) {
      try {
        entries.add(
          DiagnosticLogEntry.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // Defekte Logeinträge werden beim nächsten Laden ignoriert.
      }
    }
    return entries;
  }

  Future<void> record({
    required String category,
    required String message,
    String? details,
  }) async {
    if (category.trim().isEmpty || message.trim().isEmpty) return;
    try {
      final current = await load();
      final entry = DiagnosticLogEntry(
        timestamp: DateTime.now().toUtc(),
        category: category.trim(),
        message: message.trim(),
        details: details?.trim().isEmpty == true ? null : details?.trim(),
      );
      final next = [entry, ...current].take(_maxEntries).toList();
      await _preferences.setStringList(
        _key,
        next.map((item) => jsonEncode(item.toJson())).toList(),
      );
    } catch (_) {
      // Fehlerprotokollierung darf den eigentlichen Fehler nicht verschärfen.
    }
  }

  Future<void> clear() => _preferences.remove(_key);

  Future<String> exportText() async {
    final entries = await load();
    if (entries.isEmpty) return 'SparzamApp Diagnoseprotokoll\nKeine Einträge.';
    final buffer = StringBuffer('SparzamApp Diagnoseprotokoll\n');
    for (final entry in entries) {
      buffer
        ..writeln()
        ..writeln('[${entry.timestamp.toIso8601String()}] ${entry.category}')
        ..writeln(entry.message);
      if (entry.details != null) buffer.writeln(entry.details);
    }
    return buffer.toString();
  }
}
