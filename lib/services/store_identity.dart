import '../models/store.dart';

/// Resolves a source label to one of the configured market identities.
///
/// Matching is limited to the normalized retailer name or that name followed
/// by the configured town. Arbitrary substring matches can assign another
/// business' prices to a market.
String? canonicalStoreName(String? label, Iterable<Store> knownStores) {
  final normalizedLabel = normalizeStoreIdentityText(label ?? '');
  if (normalizedLabel.isEmpty) return null;

  for (final store in knownStores) {
    final name = normalizeStoreIdentityText(store.name);
    final town = normalizeStoreIdentityText(store.location.split('·').first);
    if (normalizedLabel == name ||
        town.isNotEmpty && normalizedLabel == '$name$town') {
      return store.name;
    }
  }
  return null;
}

String normalizeStoreIdentityText(String value) => value
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '');
