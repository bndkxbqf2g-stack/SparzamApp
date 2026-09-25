import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/recent_purchase.dart';

class RecentPurchaseStore {
  static const _storageKey = 'recent_purchases';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<RecentPurchase>> load() async {
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

  Future<List<RecentPurchase>> add(
    Product product,
    int quantity,
    List<RecentPurchase> current,
  ) async {
    final previous = current.where((item) => item.id == product.id).firstOrNull;
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
      ...current.where((item) => item.id != purchase.id),
    ].take(30).toList();

    await _preferences.setStringList(
      _storageKey,
      next.map((item) => item.toJson()).toList(),
    );
    return next;
  }
}
