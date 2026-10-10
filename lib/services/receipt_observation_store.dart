import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/receipt_observation.dart';

class ReceiptObservationStore {
  static const _key = 'receipt_observations_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<ReceiptObservation>> load() async {
    final values = await _preferences.getStringList(_key);
    if (values == null) return <ReceiptObservation>[];
    final result = <ReceiptObservation>[];
    for (final value in values) {
      try {
        result.add(
          ReceiptObservation.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // Defekte Einzelbeobachtungen blockieren die übrige Preishistorie nicht.
      }
    }
    return _canonicalize(result).values.toList()
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
  }

  Future<int> addMany(Iterable<ReceiptObservation> observations) async {
    final current = await load();
    final byKey = _canonicalize(current);
    var changedCount = 0;
    var changed = false;
    for (final entry in _canonicalize(observations).entries) {
      final previous = byKey[entry.key];
      final observation = previous == null
          ? entry.value
          : _mergeObservation(previous, entry.value);
      if (previous == null) {
        changedCount++;
        changed = true;
      } else if (jsonEncode(previous.toJson()) !=
          jsonEncode(observation.toJson())) {
        changedCount++;
        changed = true;
      }
      byKey[entry.key] = observation;
    }
    if (!changed) return 0;
    final next = byKey.values.toList()
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
    await _preferences.setStringList(
      _key,
      next.map((item) => jsonEncode(item.toJson())).toList(),
    );
    // The import dialog uses this value to decide whether an import changed
    // anything. Count updates as well as first-time inserts so a corrected
    // identity is not reported as an empty save.
    return changedCount;
  }

  Future<void> replaceAll(List<ReceiptObservation> observations) =>
      _preferences.setStringList(
        _key,
        observations.map((item) => jsonEncode(item.toJson())).toList(),
      );

  /// The source line number is useful evidence but is not stable across OCR
  /// engines and PDF text extraction. Group rows by their receipt fingerprint
  /// and stable row content, then number repeated equal rows by their order.
  /// This also lets legacy `fingerprint|line` ids converge to the current
  /// `fingerprint|item:n` ids on the next read or import.
  Map<String, ReceiptObservation> _canonicalize(
    Iterable<ReceiptObservation> observations,
  ) {
    final byReceipt = <String, List<ReceiptObservation>>{};
    for (final observation in observations) {
      byReceipt
          .putIfAbsent(
            observation.receiptFingerprint,
            () => <ReceiptObservation>[],
          )
          .add(observation);
    }
    final result = <String, ReceiptObservation>{};
    for (final group in byReceipt.values) {
      group.sort((a, b) {
        final line = a.rowLine.compareTo(b.rowLine);
        return line != 0 ? line : a.id.compareTo(b.id);
      });
      final occurrences = <String, int>{};
      for (final observation in group) {
        final signature = _rowSignature(observation);
        final occurrence = (occurrences[signature] ?? 0) + 1;
        occurrences[signature] = occurrence;
        final key = '${observation.receiptFingerprint}|$signature|$occurrence';
        final previous = result[key];
        result[key] = previous == null
            ? observation
            : _mergeObservation(previous, observation);
      }
    }
    return result;
  }

  String _rowSignature(ReceiptObservation observation) => jsonEncode([
    observation.rawLabel,
    observation.totalPrice,
    observation.quantity,
    observation.quantityUnit,
    observation.unitPrice,
    observation.discounted,
    observation.storeName,
  ]);

  ReceiptObservation _mergeObservation(
    ReceiptObservation previous,
    ReceiptObservation incoming,
  ) {
    // Re-importing a receipt must not erase an explicit identity confirmation
    // (or an automatic product created for the same row) merely because the
    // second review was left unselected.
    if (previous.productId != null && incoming.productId == null) {
      return _withIdentity(
        incoming,
        productId: previous.productId,
        identityConfirmed: previous.identityConfirmed,
      );
    }
    if (previous.identityConfirmed && !incoming.identityConfirmed) {
      return _withIdentity(
        incoming,
        productId: previous.productId,
        identityConfirmed: true,
      );
    }
    return incoming;
  }

  ReceiptObservation _withIdentity(
    ReceiptObservation source, {
    required String? productId,
    required bool identityConfirmed,
  }) => ReceiptObservation(
    id: source.id,
    receiptFingerprint: source.receiptFingerprint,
    rowLine: source.rowLine,
    rawLabel: source.rawLabel,
    familyKey: source.familyKey,
    storeName: source.storeName,
    observedAt: source.observedAt,
    totalPrice: source.totalPrice,
    quantity: source.quantity,
    quantityUnit: source.quantityUnit,
    unitPrice: source.unitPrice,
    discounted: source.discounted,
    productId: productId,
    identityConfirmed: identityConfirmed,
  );
}
