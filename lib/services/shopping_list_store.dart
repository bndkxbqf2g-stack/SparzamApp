import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/list_item.dart';
import '../models/named_shopping_list.dart';
import '../models/product.dart';
import '../models/recent_purchase.dart';

class ShoppingListStore {
  static const _storageKey = 'shopping_list';
  static const _listsStorageKey = 'shopping_lists_v1';
  static const _knownItemsStorageKey = 'known_shopping_items';
  static const _preferredProductsStorageKey = 'preferred_products_by_group';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<Map<String, String>> loadPreferredProducts() async {
    final values = await _preferences.getStringList(_preferredProductsStorageKey);
    if (values == null) return <String, String>{'butter': 'butter_streichzart'};

    final result = <String, String>{};
    for (final value in values) {
      final parts = value.split('|');
      if (parts.length == 2) result[parts[0]] = parts[1];
    }
    return result;
  }

  Future<void> savePreferredProduct(String group, String productId) async {
    final current = await loadPreferredProducts();
    current[group] = productId;
    await _preferences.setStringList(
      _preferredProductsStorageKey,
      current.entries.map((entry) => '${entry.key}|${entry.value}').toList(),
    );
  }

  Future<List<RecentPurchase>> loadKnownItems() async {
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

  Future<void> saveKnownItem(Product product) async {
    final current = await loadKnownItems();
    final item = RecentPurchase.fromProduct(product);
    final next = [item, ...current.where((existing) => existing.id != item.id)];
    await _preferences.setStringList(
      _knownItemsStorageKey,
      next.map((entry) => entry.toJson()).toList(),
    );
  }

  Future<void> removeKnownItem(String id) async {
    final current = await loadKnownItems();
    await _preferences.setStringList(
      _knownItemsStorageKey,
      current
          .where((item) => item.id != id)
          .map((entry) => entry.toJson())
          .toList(),
    );
  }

  Future<void> removePreferredProduct(String group, String id) async {
    final current = await loadPreferredProducts();
    if (current[group] != id) return;
    current.remove(group);
    await _preferences.setStringList(
      _preferredProductsStorageKey,
      current.entries.map((entry) => '${entry.key}|${entry.value}').toList(),
    );
  }

  Future<List<ListItem>> load() async {
    final values = await _preferences.getStringList(_storageKey);
    if (values == null) return <ListItem>[];

    final items = <ListItem>[];
    for (final value in values) {
      try {
        final json = jsonDecode(value) as Map<String, dynamic>;
        items.add(
          ListItem(
            product: Product(
              id: json['id'] as String,
              name: json['name'] as String,
              unit: json['unit'] as String,
              group: json['group'] as String,
              ean: json['ean'] as String?,
            ),
            quantity: (json['quantity'] as num?)?.toInt() ?? 1,
          ),
        );
      } catch (_) {
        // Beschädigte Einzel-Einträge werden ignoriert.
      }
    }
    return items;
  }

  Future<void> save(List<ListItem> items) async {
    await _preferences.setStringList(
      _storageKey,
      items.map((item) => jsonEncode({
        'id': item.product.id,
        'name': item.product.name,
        'unit': item.product.unit,
        'group': item.product.group,
        'ean': item.product.ean,
        'quantity': item.quantity,
      })).toList(),
    );
  }

  Future<void> clear() => _preferences.remove(_storageKey);

  Future<List<NamedShoppingList>> loadNamedLists() async {
    final values = await _preferences.getStringList(_listsStorageKey);
    if (values == null) return const <NamedShoppingList>[];
    final result = <NamedShoppingList>[];
    for (final value in values) {
      try {
        result.add(NamedShoppingList.fromJson(
          jsonDecode(value) as Map<String, dynamic>,
        ));
      } catch (_) {
        // Beschädigte Listen werden ignoriert, die übrigen bleiben nutzbar.
      }
    }
    return result;
  }

  Future<void> saveNamedLists(List<NamedShoppingList> lists) =>
      _preferences.setStringList(
        _listsStorageKey,
        lists.map((list) => jsonEncode(list.toJson())).toList(),
      );
}
