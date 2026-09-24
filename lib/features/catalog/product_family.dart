String normalizeProductText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[._-]+'), ' ')
    .replaceAll(RegExp(r'\\s+'), ' ')
    .trim();

const _familyTerms = <String, List<String>>{
  'kaese': [
    'käse', 'kaese', 'gouda', 'edamer', 'emmentaler', 'bergkäse', 'bergkaese',
    'butterkäse', 'butterkaese', 'tilsiter',
  ],
  'wurst': [
    'wurst', 'salami', 'lyoner', 'schinkenwurst', 'fleischwurst',
    'mortadella', 'cervelat',
  ],
};

String? broadProductFamily(String value) {
  final normalized = normalizeProductText(value);
  for (final entry in _familyTerms.entries) {
    if (entry.value.any(normalized.contains)) return entry.key;
  }
  return null;
}

bool isGenericFamilyRequest(String value) {
  final normalized = normalizeProductText(value);
  final family = broadProductFamily(value);
  if (family == null) return false;
  return switch (family) {
    'kaese' => normalized == 'käse' || normalized == 'kaese',
    'wurst' => normalized == 'wurst',
    _ => false,
  };
}
