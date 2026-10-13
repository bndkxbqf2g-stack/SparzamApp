import 'package:shared_preferences/shared_preferences.dart';

import '../models/purchase_record.dart';
import 'sequential_operation_queue.dart';

class PurchaseStore {
  static const _key = 'purchase_history_v1';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<PurchaseRecord>> load() => _queue.schedule(_loadNow);

  Future<List<PurchaseRecord>> _loadNow() async {
    final values = await _preferences.getStringList(_key) ?? const <String>[];
    final records = <PurchaseRecord>[];
    for (final value in values) {
      try {
        records.add(PurchaseRecord.fromJson(value));
      } catch (_) {
        // Beschädigte Einzel-Einträge werden ignoriert.
      }
    }
    records.sort(_newestFirst);
    return records;
  }

  Future<List<PurchaseRecord>> remove(
    String id,
    List<PurchaseRecord> current,
  ) {
    final snapshot = List<PurchaseRecord>.of(current, growable: false);
    return _queue.schedule(() async {
      final base = await _mergeWithStored(snapshot);
      final next = base.where((item) => item.id != id).toList()
        ..sort(_newestFirst);
      await _saveNow(next);
      return next;
    });
  }

  Future<List<PurchaseRecord>> add(
    PurchaseRecord record,
    List<PurchaseRecord> current,
  ) {
    final snapshot = List<PurchaseRecord>.of(current, growable: false);
    return _queue.schedule(() async {
      final base = await _mergeWithStored(snapshot);
      final next = [record, ...base.where((item) => item.id != record.id)]
        ..sort(_newestFirst);
      await _saveNow(next);
      return next;
    });
  }

  Future<void> save(List<PurchaseRecord> records) {
    final snapshot = List<PurchaseRecord>.of(records, growable: false);
    return _queue.schedule(() => _saveNow(snapshot));
  }

  Future<void> _saveNow(List<PurchaseRecord> records) =>
      _preferences.setStringList(
        _key,
        records.map((record) => record.toJson()).toList(),
      );

  Future<List<PurchaseRecord>> _mergeWithStored(
    List<PurchaseRecord> current,
  ) async {
    final byId = <String, PurchaseRecord>{
      for (final record in await _loadNow()) record.id: record,
    };
    for (final record in current) {
      byId[record.id] = record;
    }
    return byId.values.toList();
  }

  static int _newestFirst(PurchaseRecord a, PurchaseRecord b) =>
      b.createdAt.compareTo(a.createdAt);
}
