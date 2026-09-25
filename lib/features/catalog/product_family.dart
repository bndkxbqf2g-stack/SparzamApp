String normalizeProductText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[._-]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

const _familyTerms = <String, List<String>>{
  'schmand': ['schmand'],
  'milch': ['milch', 'h milch', 'vollmilch'],
  'joghurt': ['joghurt', 'jogurt'],
  'eier': ['eier'],
  'kartoffeln': ['kartoffeln'],
  'bananen': ['bananen'],
  'paprika': ['paprika'],
  'tomaten': ['tomaten', 'tomate', 'passata', 'geh tomaten', 'gehackte tomaten'],
  'hackfleisch': ['hackfleisch', 'hackfl gem', 'r hackfleisch', 'rinderhack', 'gem hack'],
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
  if (family == 'hackfleisch') {
    return normalized == 'hackfleisch' || normalized == 'hackfleisch gemischt';
  }
  return switch (family) {
    'kaese' => normalized == 'käse' || normalized == 'kaese',
    'wurst' => normalized == 'wurst',
    _ => _familyTerms[family]!.any((term) =>
        normalized == term || normalized.endsWith(' $term')),
  };
}
