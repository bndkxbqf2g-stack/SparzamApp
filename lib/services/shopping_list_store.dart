import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/list_item.dart';
import '../models/named_shopping_list.dart';
import '../models/product.dart';
import '../models/recent_purchase.dart';
import 'sequential_operation_queue.dart';

class ShoppingListStore {
  static const _storageKey = 'shopping_list';
  static const _listsStorageKey = 'shopping_lists_v1';
  static const _knownItemsStorageKey = 'known_shopping_items';
  static const _preferredProductsStorageKey = 'preferred_products_by_group';
  static const _aisleOrderStorageKey = 'shopping_aisle_order_v1';
  static const _tileViewStorageKey = 'shopping_tile_view_v1';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<Map<String, String>> loadPreferredProducts() =>
      _queue.schedule(_loadPreferredProductsNow);

  Future<Map<String, String>> _loadPreferredProductsNow() async {
    final values = await _preferences.getStringList(
      _preferredProductsStorageKey,
    );
    if (values == null) return <String, String>{'butter': 'butter_streichzart'};

    final result = <String, String>{};
    for (final value in values) {
      final parts = value.split('|');
      if (parts.length == 2) result[parts[0]] = parts[1];
    }
    return result;
  }

  Future<void> savePreferredProduct(String group, String productId) =>
      _queue.schedule(
        () async {
          final current = await _loadPreferredProductsNow();
          current[group] = productId;
          await _preferences.setStringList(
            _preferredProductsStorageKey,
            current.entries
                .map((entry) => '${entry.key}|${entry.value}')
                .toList(),
          );
        },
      );

  Future<List<RecentPurchase>> loadKnownItems() =>
      _queue.schedule(_loadKnownItemsNow);

  Future<List<RecentPurchase>> _loadKnownItemsNow() async {
    final values = await _preferences.getStringList(_knownItemsStorageKey);
    if (values == null) return <RecentPurchase>[];

    final items = <RecentPurchase>[];
    for (final value in values) {
      try {
        items.add(RecentPurchase.fromJson(value));
      } catch (_) {
        // Beschädigte Einzel-Einträge werden ignoriert.
      }
    }
    return items;
  }

  Future<void> saveKnownItem(Product product) => _queue.schedule(
    () async {
      final current = await _loadKnownItemsNow();
      final item = RecentPurchase.fromProduct(product);
      final next = [
        item,
        ...current.where((existing) => existing.id != item.id),
      ];
      await _preferences.setStringList(
        _knownItemsStorageKey,
        next.map((entry) => entry.toJson()).toList(),
      );
    },
  );

  Future<void> saveKnownItems(List<RecentPurchase> items) {
    final snapshot = List<RecentPurchase>.of(items, growable: false);
    return _queue.schedule(
      () => _preferences.setStringList(
        _knownItemsStorageKey,
        snapshot.map((entry) => entry.toJson()).toList(),
      ),
    );
  }

  Future<void> savePreferredProducts(Map<String, String> products) {
    final snapshot = Map<String, String>.from(products);
    return _queue.schedule(
      () => _preferences.setStringList(
        _preferredProductsStorageKey,
        snapshot.entries.map((entry) => '${entry.key}|${entry.value}').toList(),
      ),
    );
  }

  Future<void> removeKnownItem(String id) => _queue.schedule(
    () async {
      final current = await _loadKnownItemsNow();
      await _preferences.setStringList(
        _knownItemsStorageKey,
        current
            .where((item) => item.id != id)
            .map((entry) => entry.toJson())
            .toList(),
      );
    },
  );

  Future<void> removePreferredProduct(String group, String id) =>
      _queue.schedule(
        () async {
          final current = await _loadPreferredProductsNow();
          if (current[group] != id) return;
          current.remove(group);
          await _preferences.setStringList(
            _preferredProductsStorageKey,
            current.entries
                .map((entry) => '${entry.key}|${entry.value}')
                .toList(),
          );
        },
      );

  Future<List<ListItem>> load() => _queue.schedule(_loadNow);

  Future<List<ListItem>> _loadNow() async {
    final values = await _preferences.getStringList(_storageKey);
    if (values == null) return <ListItem>[];

    final items = <ListItem>[];
    for (final value in values) {
      try {
        final json = jsonDecode(value) as Map<String, dynamic>;
        final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
        if (quantity <= 0) continue;
        items.add(
          ListItem(
            product: Product(
              id: json['id'] as String,
              name: json['name'] as String,
              unit: json['unit'] as String,
              group: json['group'] as String,
              ean: json['ean'] as String?,
              imageUrl: json['imageUrl'] as String?,
            ),
            quantity: quantity,
            note: json['note'] as String? ?? '',
            checked: json['checked'] as bool? ?? false,
          ),
        );
      } catch (_) {
        // Beschädigte Einzel-Einträge werden ignoriert.
      }
    }
    return items;
  }

  Future<void> save(List<ListItem> items) {
    final snapshot = List<ListItem>.of(items, growable: false);
    return _queue.schedule(
      () => _preferences.setStringList(
        _storageKey,
        snapshot
            .map(
              (item) => jsonEncode({
                'id': item.product.id,
                'name': item.product.name,
                'unit': item.product.unit,
                'group': item.product.group,
                'ean': item.product.ean,
                'imageUrl': item.product.imageUrl,
                'quantity': item.quantity,
                'note': item.note,
                'checked': item.checked,
              }),
            )
            .toList(),
      ),
    );
  }

  Future<void> clear() => _queue.schedule(() async {
    await _preferences.remove(_storageKey);
  });

  Future<List<NamedShoppingList>> loadNamedLists() =>
      _queue.schedule(_loadNamedListsNow);

  Future<List<NamedShoppingList>> _loadNamedListsNow() async {
    final values = await _preferences.getStringList(_listsStorageKey);
    if (values == null) return const <NamedShoppingList>[];
    final result = <NamedShoppingList>[];
    for (final value in values) {
      try {
        result.add(
          NamedShoppingList.fromJson(jsonDecode(value) as Map<String, dynamic>),
        );
      } catch (_) {
        // Beschädigte Listen werden ignoriert, die übrigen bleiben nutzbar.
      }
    }
    return result;
  }

  Future<void> saveNamedLists(List<NamedShoppingList> lists) {
    final snapshot = List<NamedShoppingList>.of(lists, growable: false);
    return _queue.schedule(
      () => _preferences.setStringList(
        _listsStorageKey,
        snapshot.map((list) => jsonEncode(list.toJson())).toList(),
      ),
    );
  }

  Future<List<String>> loadAisleOrder() => _queue.schedule(() async {
    return await _preferences.getStringList(_aisleOrderStorageKey) ??
        <String>[];
  });

  Future<void> saveAisleOrder(List<String> groups) {
    final snapshot = List<String>.of(groups, growable: false);
    return _queue.schedule(
      () => _preferences.setStringList(
        _aisleOrderStorageKey,
        snapshot,
      ),
    );
  }

  Future<bool> loadTileView() => _queue.schedule(() async {
    return await _preferences.getBool(_tileViewStorageKey) ?? true;
  });

  Future<void> saveTileView(bool enabled) =>
      _queue.schedule(() => _preferences.setBool(_tileViewStorageKey, enabled));
}
