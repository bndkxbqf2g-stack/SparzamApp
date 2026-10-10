import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/stores.dart';
import '../models/receipt_alias.dart';
import 'store_identity.dart';

class ReceiptAliasStore {
  static const _key = 'receipt_aliases_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<ReceiptAlias>> load() async {
    final values = await _preferences.getStringList(_key);
    if (values == null) return <ReceiptAlias>[];
    return values
        .map((value) {
          try {
            return ReceiptAlias.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<ReceiptAlias>()
        .toList();
  }

  Future<void> confirm({
    required String storeName,
    required String rawLabel,
    required String productId,
    required DateTime now,
  }) async {
    final normalized = normalizeReceiptAlias(rawLabel);
    if (normalized.isEmpty) return;
    final canonicalStore = canonicalReceiptAliasStoreName(storeName);
    final current = await load();
    final byKey = <String, ReceiptAlias>{
      for (final item in current) item.key: item,
    };
    ReceiptAlias? previous;
    for (final item in current) {
      if (_sameAliasStore(item.storeName, storeName) &&
          _sameAliasLabel(item.normalizedLabel, normalized)) {
        previous = item;
        break;
      }
    }
    if (previous != null) byKey.remove(previous.key);
    final next = ReceiptAlias(
      storeName: canonicalStore,
      normalizedLabel: normalized,
      productId: productId,
      confirmations: previous?.productId == productId
          ? previous!.confirmations + 1
          : 1,
      updatedAt: now,
    );
    byKey[next.key] = next;
    await _preferences.setStringList(
      _key,
      byKey.values.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<String?> learnedProductId({
    required String storeName,
    required String rawLabel,
    int minConfirmations = 2,
  }) async => (await learnedAlias(
    storeName: storeName,
    rawLabel: rawLabel,
    minConfirmations: minConfirmations,
  ))?.productId;

  Future<ReceiptAlias?> learnedAlias({
    required String storeName,
    required String rawLabel,
    int minConfirmations = 2,
  }) async {
    final normalized = normalizeReceiptAlias(rawLabel);
    for (final item in await load()) {
      if (_sameAliasStore(item.storeName, storeName) &&
          _sameAliasLabel(item.normalizedLabel, normalized) &&
          item.confirmations >= minConfirmations) {
        return item;
      }
    }
    return null;
  }

  Future<void> save(List<ReceiptAlias> aliases) => _preferences.setStringList(
    _key,
    aliases.map((item) => jsonEncode(item.toJson())).toList(),
  );
}

String normalizeReceiptAlias(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[._-]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Keeps learned receipt aliases on the configured market identity.
///
/// Receipt OCR may include a town or use a spelling such as `ALDI SUED`.
/// Unknown labels remain untouched so an alias can still be reviewed instead
/// of being assigned to an unrelated market.
String canonicalReceiptAliasStoreName(String value) =>
    canonicalStoreName(value, stores) ?? value.trim();

bool _sameAliasStore(String left, String right) =>
    _normalizeAliasStore(canonicalReceiptAliasStoreName(left)) ==
        _normalizeAliasStore(canonicalReceiptAliasStoreName(right));

bool _sameAliasLabel(String left, String right) =>
    _foldReceiptAlias(left) == _foldReceiptAlias(right);

String _foldReceiptAlias(String value) => value
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss');

String _normalizeAliasStore(String value) =>
    normalizeStoreIdentityText(_foldReceiptAlias(value));
