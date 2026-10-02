import '../../models/product.dart';
import '../../models/receipt_observation.dart';
import '../catalog/product_identity.dart';

/// Unconfirmed receipt labels can be recalled in search without becoming
/// catalog identities or current prices. Selecting one is an explicit choice.
List<Product> receiptSearchProducts(
  Iterable<ReceiptObservation> observations, {
  required Iterable<Product> catalogProducts,
  DateTime? now,
  int maxAgeDays = 365,
  int maxCandidates = 1000,
}) {
  final today = now ?? DateTime.now();
  final cutoff = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: maxAgeDays));
  final existing = <String>{
    for (final product in catalogProducts) ...[
      normalizeIdentityText(product.name),
      ...product.aliases.map(normalizeIdentityText),
    ],
  };
  final recent =
      observations
          .where(
            (entry) =>
                !entry.identityConfirmed &&
                entry.rawLabel.trim().isNotEmpty &&
                !entry.observedAt.isBefore(cutoff) &&
                !entry.observedAt.isAfter(today),
          )
          .toList()
        ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
  final seen = <String>{};
  final result = <Product>[];
  for (final entry in recent) {
    final raw = entry.rawLabel.trim();
    final key = normalizeIdentityText(raw);
    final display = _displayName(raw, entry.storeName);
    final displayKey = normalizeIdentityText(display);
    if (key.isEmpty ||
        existing.contains(key) ||
        existing.contains(displayKey) ||
        !seen.add(key)) {
      continue;
    }
    final identity = identifyProduct(display);
    result.add(
      Product(
        id: 'receipt_suggestion_${_hash(key)}',
        name: display,
        unit: entry.quantityUnit == 'kg' ? 'kg' : 'Packung',
        group: identity.familyKey ?? 'Sonstiges',
        aliases: display == raw ? const [] : [raw],
      ),
    );
    if (result.length >= maxCandidates) break;
  }
  return result;
}

String _displayName(String raw, String storeName) {
  if (storeName == 'Kaufland') {
    // Remove only the known Kaufland house-brand marker. The original remains
    // an alias; abbreviation expansion and variant claims require user review.
    var display = raw.replaceFirst(
      RegExp(
        r'^(?:KLC|KBio)(?:\.\s*|\s+|(?=[A-Za-zÄÖÜäöü]))',
        caseSensitive: false,
      ),
      '',
    );
    display = display.replaceFirst(
      RegExp(r'^K(?:\.\s*|\s+)', caseSensitive: false),
      '',
    );
    return display;
  }
  return raw;
}

String _hash(String value) {
  var hash = 0x811c9dc5;
  for (final code in value.codeUnits) {
    hash = ((hash ^ code) * 0x01000193).toUnsigned(32);
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
