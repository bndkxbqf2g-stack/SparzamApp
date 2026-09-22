import 'package:shared_preferences/shared_preferences.dart';

import '../models/purchase_record.dart';

class PurchaseStore {
  static const _key = 'purchase_history_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<PurchaseRecord>> load() async {
    final values = await _preferences.getStringList(_key) ?? const <String>[];
    final records = <PurchaseRecord>[];
    for (final value in values) {
      try {
        records.add(PurchaseRecord.fromJson(value));
      } catch (_) {
        // Beschädigte Einzel-Einträge werden ignoriert.
      }
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<List<PurchaseRecord>> remove(
    String id,
    List<PurchaseRecord> current,
  ) async {
    final next = current.where((item) => item.id != id).toList()
      ..sort(_newestFirst);
    await save(next);
    return next;
  }

  Future<List<PurchaseRecord>> add(
    PurchaseRecord record,
    List<PurchaseRecord> current,
  ) async {
    final next = [record, ...current.where((item) => item.id != record.id)]
      ..sort(_newestFirst);
    await save(next);
    return next;
  }

  Future<void> save(List<PurchaseRecord> records) =>
      _preferences.setStringList(
        _key,
        records.map((record) => record.toJson()).toList(),
      );

  static int _newestFirst(PurchaseRecord a, PurchaseRecord b) =>
      b.createdAt.compareTo(a.createdAt);
}
