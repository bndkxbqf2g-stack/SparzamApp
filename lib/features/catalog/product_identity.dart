/// General product identity extracted from user and receipt text.
class ProductIdentity {
  const ProductIdentity({
    required this.familyKey,
    this.variant,
    this.productType,
    this.fatPercent,
    this.color,
    this.shape,
    this.meatType,
  });

  final String? familyKey;
  final String? variant;
  final String? productType;
  final double? fatPercent;
  final String? color;
  final String? shape;
  final String? meatType;

  bool get isKnown => familyKey != null;

  bool get isGeneric => isKnown &&
      variant == null &&
      productType == null &&
      fatPercent == null &&
      color == null &&
      shape == null &&
      meatType == null ||
      (familyKey == 'hackfleisch' && meatType == 'gemischt');

  String get variantKey => <String>[
        if (variant != null) 'variant:$variant',
        if (productType != null) 'type:$productType',
        if (fatPercent != null) 'fat:${fatPercent!.toStringAsFixed(2)}',
        if (color != null) 'color:$color',
        if (shape != null) 'shape:$shape',
        if (meatType != null) 'meat:$meatType',
      ].join('|');
}

ProductIdentity identifyProduct(String value) {
  final text = normalizeIdentityText(value);

  if (_hasAny(text, const ['chips', 'pringles'])) {
    return const ProductIdentity(familyKey: 'chips', productType: 'chips');
  }
  if (_hasWord(text, 'pizza')) {
    return const ProductIdentity(familyKey: 'pizza', productType: 'pizza');
  }
  if (_hasWord(text, 'schmand')) {
    return const ProductIdentity(familyKey: 'schmand');
  }
  if (_hasAny(text, const ['milch', 'h milch', 'vollmilch'])) {
    return ProductIdentity(
      familyKey: 'milch',
      variant: _hasWord(text, 'h milch') ? 'h' : null,
      fatPercent: _percent(text),
    );
  }
  if (text.contains('joghurt') || text.contains('jogurt')) {
    return ProductIdentity(
      familyKey: 'joghurt',
      variant: _hasAny(text, const ['naturjoghurt', 'natur joghurt', 'natur'])
          ? 'natur'
          : null,
    );
  }
  if (_hasAny(text, const ['hackfleisch', 'hackfl', 'rinderhack', 'rinderhackfleisch', 'gem hack'])) {
    return ProductIdentity(
      familyKey: 'hackfleisch',
      meatType: _hasAny(text, const ['rinderhack', 'rinderhackfleisch', 'rind hack', 'rind'])
          ? 'rind'
          : _hasAny(text, const ['gemischt', 'gemischtes', 'gem hack', 'hackfl gem'])
              ? 'gemischt'
              : null,
    );
  }
  if (_hasAny(text, const ['paprika', 'spitzpaprika'])) {
    return ProductIdentity(
      familyKey: 'paprika',
      color: _color(text),
      shape: _hasAny(text, const ['spitzpaprika', 'spitz paprika'])
          ? 'spitz'
          : _hasWord(text, 'mix')
              ? 'mix'
              : null,
    );
  }
  if (_hasAny(text, const ['banane', 'bananen'])) {
    return const ProductIdentity(familyKey: 'bananen');
  }
  if (_hasAny(text, const ['apfel', 'aepfel', 'äpfel'])) {
    return ProductIdentity(familyKey: 'aepfel', color: _color(text));
  }
  if (_hasAny(text, const ['eier', 'ei'])) {
    return const ProductIdentity(familyKey: 'eier');
  }
  if (_hasAny(text, const ['kartoffel', 'kartoffeln'])) {
    return const ProductIdentity(familyKey: 'kartoffeln');
  }
  if (_hasAny(text, const ['tomate', 'tomaten', 'passata'])) {
    return ProductIdentity(
      familyKey: 'tomaten',
      productType: _hasWord(text, 'passata') ||
              _hasAny(text, const ['geh tomaten', 'gehackte tomaten'])
          ? 'konserve'
          : null,
    );
  }
  if (_hasAny(text, const ['weintrauben', 'trauben'])) {
    return const ProductIdentity(familyKey: 'weintrauben');
  }
  if (_hasWord(text, 'fischstäbchen')) {
    return const ProductIdentity(familyKey: 'fischstäbchen');
  }
  if (_hasAny(text, const ['sandwichtoast', 'toast'])) {
    return const ProductIdentity(familyKey: 'toast');
  }
  if (_hasAny(text, const [
    'käse', 'kaese', 'gouda', 'edamer', 'emmentaler', 'bergkäse',
    'bergkaese', 'butterkäse', 'butterkaese', 'tilsiter',
  ])) {
    return ProductIdentity(familyKey: 'kaese', variant: _cheeseVariant(text));
  }
  if (_hasAny(text, const [
    'wurst', 'salami', 'lyoner', 'schinkenwurst', 'fleischwurst',
    'mortadella', 'cervelat',
  ])) {
    return ProductIdentity(familyKey: 'wurst', variant: _sausageVariant(text));
  }
  return const ProductIdentity(familyKey: null);
}

bool compatibleProductIdentity(ProductIdentity request, ProductIdentity candidate) {
  if (!request.isKnown || request.familyKey != candidate.familyKey) {
    return false;
  }
  if (request.productType != null && request.productType != candidate.productType) {
    return false;
  }
  if (request.fatPercent != null && request.fatPercent != candidate.fatPercent) {
    return false;
  }
  if (request.color != null && request.color != candidate.color) {
    return false;
  }
  if (request.shape != null && request.shape != candidate.shape) {
    return false;
  }
  if (request.meatType != null && request.meatType != candidate.meatType) {
    return false;
  }
  if (request.variant != null && candidate.variant != null &&
      request.variant != candidate.variant) {
    return false;
  }
  return true;
}

String normalizeIdentityText(String value) => value
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss')
    .replaceAll(RegExp(r'[._/-]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool _hasWord(String text, String word) {
  final normalized = normalizeIdentityText(word);
  return text == normalized ||
      text.startsWith('$normalized ') ||
      text.endsWith(' $normalized') ||
      text.contains(' $normalized ');
}

bool _hasAny(String text, List<String> words) => words.any((word) => _hasWord(text, word));

double? _percent(String text) {
  final match = RegExp(r'(\d+(?:[,.]\d+)?)\s*%').firstMatch(text);
  return match == null ? null : double.tryParse(match.group(1)!.replaceAll(',', '.'));
}

String? _cheeseVariant(String text) {
  for (final term in const [
    'gouda', 'edamer', 'emmentaler', 'bergkaese', 'butterkaese', 'tilsiter',
  ]) {
    if (_hasWord(text, term)) return term;
  }
  return null;
}

String? _sausageVariant(String text) {
  for (final term in const [
    'salami', 'lyoner', 'schinkenwurst', 'fleischwurst', 'mortadella', 'cervelat',
  ]) {
    if (_hasWord(text, term)) return term;
  }
  return null;
}

String? _color(String text) {
  if (_hasAny(text, const ['rot', 'rote', 'roter', 'rotes'])) return 'rot';
  if (_hasAny(text, const ['gelb', 'gelbe', 'gelber'])) return 'gelb';
  if (_hasAny(text, const ['gruen', 'grüne', 'gruen'])) return 'gruen';
  return null;
}
