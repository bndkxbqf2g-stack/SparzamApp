import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/recent_purchase.dart';
import 'sequential_operation_queue.dart';

class RecentPurchaseStore {
  static const _storageKey = 'recent_purchases';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<RecentPurchase>> load() => _queue.schedule(_loadNow);

  Future<List<RecentPurchase>> _loadNow() async {
    final values = await _preferences.getStringList(_storageKey);
    if (values == null) return <RecentPurchase>[];

    final purchases = <RecentPurchase>[];
    for (final value in values) {
      try {
        purchases.add(RecentPurchase.fromJson(value));
      } catch (_) {
        // Beschädigte Einzel-Einträge werden ignoriert.
      }
    }
    return purchases.take(30).toList();
  }

  Future<void> save(List<RecentPurchase> purchases) {
    final snapshot = List<RecentPurchase>.of(purchases, growable: false);
    return _queue.schedule(() => _saveNow(snapshot));
  }

  Future<void> _saveNow(List<RecentPurchase> purchases) =>
      _preferences.setStringList(
        _storageKey,
        purchases.take(30).map((item) => item.toJson()).toList(),
      );

  Future<List<RecentPurchase>> add(
    Product product,
    int quantity,
    List<RecentPurchase> current,
  ) {
    final snapshot = List<RecentPurchase>.of(current, growable: false);
    return _queue.schedule(() async {
      final base = await _mergeWithStored(snapshot);
      final previous = base.where((item) => item.id == product.id).firstOrNull;
      final purchase = RecentPurchase(
        id: product.id,
        name: product.name,
        unit: product.unit,
        group: product.group,
        purchaseCount: (previous?.purchaseCount ?? 0) + 1,
        totalQuantity: (previous?.totalQuantity ?? 0) + quantity,
        ean: product.ean ?? previous?.ean,
      );

      final next = <RecentPurchase>[
        purchase,
        ...base.where((item) => item.id != purchase.id),
      ].take(30).toList();

      await _saveNow(next);
      return next;
    });
  }

  Future<List<RecentPurchase>> _mergeWithStored(
    List<RecentPurchase> current,
  ) async {
    final byId = <String, RecentPurchase>{
      for (final purchase in await _loadNow()) purchase.id: purchase,
    };
    for (final purchase in current) {
      byId[purchase.id] = purchase;
    }
    return byId.values.toList();
  }
}
