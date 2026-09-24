import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/receipt_alias.dart';

class ReceiptAliasStore {
  static const _key = 'receipt_aliases_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<ReceiptAlias>> load() async {
    final values = await _preferences.getStringList(_key);
    if (values == null) return <ReceiptAlias>[];
    return values.map((value) {
      try {
        return ReceiptAlias.fromJson(
          jsonDecode(value) as Map<String, dynamic>,
        );
      } catch (_) {
        return null;
      }
    }).whereType<ReceiptAlias>().toList();
  }

  Future<void> confirm({
    required String storeName,
    required String rawLabel,
    required String productId,
    required DateTime now,
  }) async {
    final normalized = normalizeReceiptAlias(rawLabel);
    if (normalized.isEmpty) return;
    final current = await load();
    final key = '${storeName.toLowerCase()}|$normalized';
    final byKey = <String, ReceiptAlias>{for (final item in current) item.key: item};
    final previous = byKey[key];
    byKey[key] = ReceiptAlias(
      storeName: storeName,
      normalizedLabel: normalized,
      productId: productId,
      confirmations:
          previous?.productId == productId ? previous!.confirmations + 1 : 1,
      updatedAt: now,
    );
    await _preferences.setStringList(
      _key,
      byKey.values.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<String?> learnedProductId({
    required String storeName,
    required String rawLabel,
    int minConfirmations = 2,
  }) async {
    final key =
        '${storeName.toLowerCase()}|${normalizeReceiptAlias(rawLabel)}';
    for (final item in await load()) {
      if (item.key == key && item.confirmations >= minConfirmations) {
        return item.productId;
      }
    }
    return null;
  }
}

String normalizeReceiptAlias(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[._-]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
