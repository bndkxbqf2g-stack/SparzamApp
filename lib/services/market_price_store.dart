import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/market_price.dart';
import 'branch_identity.dart';
import 'sequential_operation_queue.dart';

class MarketPriceStore {
  static const _key = 'market_prices_v1';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<MarketPrice>> load() => _queue.schedule(_loadNow);

  Future<List<MarketPrice>> _loadNow() async {
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
  ) => upsertMany([price], current);

  Future<void> save(List<MarketPrice> prices) {
    final snapshot = List<MarketPrice>.of(prices, growable: false);
    return _queue.schedule(() => _saveNow(snapshot));
  }

  Future<List<MarketPrice>> upsertMany(
    Iterable<MarketPrice> prices,
    List<MarketPrice> current,
  ) {
    final incoming = prices.toList(growable: false);
    final snapshot = List<MarketPrice>.of(current, growable: false);
    return _queue.schedule(() async {
      var next = await _mergeWithStored(snapshot);
      var changed = false;
      for (final price in incoming) {
        final existing = next.where((item) => _samePriceSlot(item, price));
        if (existing.isNotEmpty) {
          final currentPrice = existing.first;
          if (price.source == MarketPriceSource.receipt &&
              (currentPrice.source == MarketPriceSource.manual ||
                  currentPrice.updatedAt.isAfter(price.updatedAt))) {
            continue;
          }
          if (price.source == MarketPriceSource.openPrices) {
            if (currentPrice.source == MarketPriceSource.manual ||
                !price.updatedAt.isAfter(currentPrice.updatedAt)) {
              continue;
            }
          }
        }
        next = [price, ...next.where((item) => !_samePriceSlot(item, price))];
        changed = true;
      }
      if (!changed) return next;
      await _saveNow(next);
      return next;
    });
  }

  Future<List<MarketPrice>> remove(
    String productId,
    String storeName,
    List<MarketPrice> current,
  ) {
    final snapshot = List<MarketPrice>.of(current, growable: false);
    return _queue.schedule(() async {
      final base = await _mergeWithStored(snapshot);
      final next = base
          .where(
            (item) =>
                item.productId != productId || item.storeName != storeName,
          )
          .toList();
      await _saveNow(next);
      return next;
    });
  }

  Future<List<MarketPrice>> removeProduct(
    String productId,
    List<MarketPrice> current,
  ) {
    final snapshot = List<MarketPrice>.of(current, growable: false);
    return _queue.schedule(() async {
      final base = await _mergeWithStored(snapshot);
      final next = base
          .where((item) => item.productId != productId)
          .toList();
      await _saveNow(next);
      return next;
    });
  }

  Future<void> _saveNow(List<MarketPrice> prices) => _preferences.setStringList(
    _key,
    prices.map((price) => jsonEncode(price.toJson())).toList(),
  );

  Future<List<MarketPrice>> _mergeWithStored(
    List<MarketPrice> current,
  ) async {
    final bySlot = <String, MarketPrice>{
      for (final price in await _loadNow()) _priceSlotKey(price): price,
    };
    for (final price in current) {
      bySlot[_priceSlotKey(price)] = price;
    }
    return bySlot.values.toList();
  }
}

/// A store/product can have several exact observations when a chain has more
/// than one branch. Keep the legacy locationless slot separate from every
/// branch-specific slot so a cheaper filial cannot overwrite another one.
bool _samePriceSlot(MarketPrice left, MarketPrice right) =>
    left.key == right.key &&
    canonicalBranchId(left.sourceLocationId) ==
        canonicalBranchId(right.sourceLocationId);

String _priceSlotKey(MarketPrice price) =>
    '${price.key}|${canonicalBranchId(price.sourceLocationId) ?? ''}';
