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


/// Canonical comparison key for public retailer labels.
///
/// This deliberately normalizes only presentation differences. It does not
/// resolve arbitrary aliases or infer a branch identity; callers still need
/// their existing exact branch and product checks.
String storeLabelMatchKey(String value) => normalizeStoreIdentityText(value)
    .replaceAll('ae', 'a')
    .replaceAll('oe', 'o')
    .replaceAll('ue', 'u');

/// Matches retailer labels that differ only in public presentation spelling.
bool sameStoreLabel(String candidate, String configured) {
  final candidateKey = storeLabelMatchKey(candidate);
  final configuredKey = storeLabelMatchKey(configured);
  return candidateKey.isNotEmpty && candidateKey == configuredKey;
}
