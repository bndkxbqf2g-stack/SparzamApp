import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/market_price.dart';

class MarketPriceStore {
  static const _key = 'market_prices_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<MarketPrice>> load() async {
    final values = await _preferences.getStringList(_key);
    if (values == null) return <MarketPrice>[];

    final result = <MarketPrice>[];
    for (final value in values) {
      try {
        result.add(
          MarketPrice.fromJson(jsonDecode(value) as Map<String, dynamic>),
        );
      } catch (_) {
        // Defekte Einzel-Einträge werden ignoriert.
      }
    }
    return result;
  }

  Future<List<MarketPrice>> upsert(
    MarketPrice price,
    List<MarketPrice> current,
  ) async {
    final next = [
      price,
      ...current.where((item) => item.key != price.key),
    ];
    await _save(next);
    return next;
  }

  Future<List<MarketPrice>> remove(
    String productId,
    String storeName,
    List<MarketPrice> current,
  ) async {
    final next = current
        .where(
          (item) =>
              item.productId != productId || item.storeName != storeName,
        )
        .toList();
    await _save(next);
    return next;
  }

  Future<void> _save(List<MarketPrice> prices) =>
      _preferences.setStringList(
        _key,
        prices.map((price) => jsonEncode(price.toJson())).toList(),
      );
}
