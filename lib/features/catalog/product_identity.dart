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

  bool get isGeneric =>
      isKnown &&
      variant == null &&
      productType == null &&
      fatPercent == null &&
      color == null &&
      shape == null &&
      meatType == null;

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
  // A filled baked snack is not the same price identity as sliced cheese.
  if (text.contains('croiss')) {
    return const ProductIdentity(
      familyKey: 'backware',
      productType: 'croissant',
    );
  }
  if (_hasAny(text, const ['milch', 'h milch', 'vollmilch'])) {
    return ProductIdentity(
      familyKey: 'milch',
      variant: _hasWord(text, 'h milch') ? 'h' : null,
      productType: _milkType(text),
      fatPercent: _percent(text),
    );
  }
  if (text.contains('joghurt') || text.contains('jogurt')) {
    return ProductIdentity(
      familyKey: 'joghurt',
      variant: _yoghurtVariant(text),
    );
  }
  if (_hasAny(text, const [
    'hackfleisch',
    'hackfl',
    'rinderhack',
    'rinderhackfleisch',
    'gem hack',
  ])) {
    return ProductIdentity(
      familyKey: 'hackfleisch',
      meatType:
          _hasAny(text, const [
                'rinderhack',
                'rinderhackfleisch',
                'rind hack',
                'rind',
              ]) ||
              RegExp(r'\br\s+hack(?:fleisch|fl)?\b').hasMatch(text)
          ? 'rind'
          : _hasAny(text, const [
              'gemischt',
              'gemischtes',
              'gem hack',
              'hackfl gem',
            ])
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
  if (_hasAny(text, const ['spaetzle', 'spätzle', 'linguine', 'kritharaki'])) {
    return ProductIdentity(familyKey: 'nudeln', productType: _pastaType(text));
  }
  if (_hasAny(text, const [
    'eier',
    'ei',
    'freilandeier',
    'bodenhaltungseier',
    'bioeier',
  ])) {
    return ProductIdentity(familyKey: 'eier', variant: _eggVariant(text));
  }
  if (_hasAny(text, const ['kartoffel', 'kartoffeln'])) {
    return const ProductIdentity(familyKey: 'kartoffeln');
  }
  if (_hasAny(text, const ['butter'])) {
    return const ProductIdentity(familyKey: 'butter');
  }
  if (_hasAny(text, const [
    'reis',
    'basmatireis',
    'parboiledreis',
    'risottoreis',
  ])) {
    return ProductIdentity(familyKey: 'reis', productType: _riceType(text));
  }
  if (_hasAny(text, const [
    'mehl',
    'weizenmehl',
    'vollkornmehl',
    'dinkelmehl',
    'type 405',
    'type 550',
  ])) {
    return ProductIdentity(familyKey: 'mehl', productType: _flourType(text));
  }
  if (_hasAny(text, const [
    'oel',
    'rapsoel',
    'sonnenblumenoel',
    'olivenoel',
    'speiseoel',
    'kokosoel',
  ])) {
    return ProductIdentity(familyKey: 'oel', productType: _oilType(text));
  }
  if (_hasAny(text, const ['zucker', 'puderzucker', 'haushaltszucker'])) {
    return ProductIdentity(familyKey: 'zucker', productType: _sugarType(text));
  }
  if (_hasAny(text, const ['salz', 'speisesalz'])) {
    return const ProductIdentity(familyKey: 'salz');
  }
  if (_hasAny(text, const ['ketchup'])) {
    return const ProductIdentity(familyKey: 'ketchup');
  }
  // Tomato products must be classified before fresh tomatoes. Matching the
  // token "tomate" alone must never turn tomato paste/sauce into fresh produce.
  if (_hasAny(text, const ['tomatenmark', 'tomaten mark'])) {
    return const ProductIdentity(familyKey: 'tomatenmark', productType: 'mark');
  }
  if (_hasAny(text, const [
    'passata',
    'passierte tomaten',
    'passierte',
    'geh tomaten',
    'gehackte tomaten',
    'dosentomaten',
    'dosen tomaten',
  ])) {
    return const ProductIdentity(
      familyKey: 'tomatenkonserve',
      productType: 'konserve',
    );
  }
  if (_hasAny(text, const ['tomatensauce', 'tomaten sauce'])) {
    return const ProductIdentity(
      familyKey: 'tomatensauce',
      productType: 'sauce',
    );
  }
  if (_hasAny(text, const [
    'tomate',
    'tomaten',
    'rispentomaten',
    'rispen tomaten',
    'partytomaten',
    'party tomaten',
    'cherrytomaten',
    'cherry tomaten',
    'cocktailtomaten',
    'cocktail tomaten',
  ])) {
    return ProductIdentity(familyKey: 'tomaten', variant: _tomatoVariant(text));
  }
  if (_hasAny(text, const ['weintrauben', 'trauben'])) {
    return const ProductIdentity(familyKey: 'weintrauben');
  }
  if (_hasWord(text, 'fischstäbchen')) {
    return const ProductIdentity(familyKey: 'fischstäbchen');
  }
  if (_hasAny(text, const [
        'aufbackbroetchen',
        'aufback broetchen',
        'broetchen',
        'semmel',
      ]) ||
      text.contains('broetchen')) {
    return ProductIdentity(
      familyKey: 'broetchen',
      variant:
          text.startsWith('aufback') ||
              _hasAny(text, const ['aufback', 'backofen'])
          ? 'aufback'
          : null,
    );
  }
  if (_hasAny(text, const ['marmelade', 'konfituere', 'fruchtaufstrich'])) {
    return const ProductIdentity(familyKey: 'marmelade');
  }
  if (_hasAny(text, const [
    'nudel',
    'nudeln',
    'pasta',
    'spaghetti',
    'penne',
    'fusilli',
    'farfalle',
    'rigatoni',
    'tortellini',
    'lasagne',
    'spaetzle',
    'spätzle',
    'linguine',
    'kritharaki',
  ])) {
    return ProductIdentity(familyKey: 'nudeln', productType: _pastaType(text));
  }
  if (_hasAny(text, const [
    'kaffee',
    'cafe',
    'nescafe',
    'espresso',
    'kaffeebohnen',
    'bohnenkaffee',
    'filterkaffee',
    'instantkaffee',
  ])) {
    return ProductIdentity(familyKey: 'kaffee', productType: _coffeeType(text));
  }
  if (_hasAny(text, const ['sandwichtoast', 'toast'])) {
    return const ProductIdentity(familyKey: 'toast');
  }
  if (_hasAny(text, const [
    'käse',
    'kaese',
    'gouda',
    'edamer',
    'emmentaler',
    'bergkäse',
    'bergkaese',
    'butterkäse',
    'butterkaese',
    'tilsiter',
  ])) {
    return ProductIdentity(familyKey: 'kaese', variant: _cheeseVariant(text));
  }
  if (_hasAny(text, const [
    'wurst',
    'salami',
    'lyoner',
    'schinkenwurst',
    'fleischwurst',
    'mortadella',
    'cervelat',
  ])) {
    return ProductIdentity(familyKey: 'wurst', variant: _sausageVariant(text));
  }
  return const ProductIdentity(familyKey: null);
}

bool compatibleProductIdentity(
  ProductIdentity request,
  ProductIdentity candidate,
) {
  if (!request.isKnown || request.familyKey != candidate.familyKey) {
    return false;
  }
  if (request.productType != null &&
      request.productType != candidate.productType) {
    return false;
  }
  if (request.fatPercent != null &&
      request.fatPercent != candidate.fatPercent) {
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
  if (request.variant != null && request.variant != candidate.variant) {
    return false;
  }
  return true;
}

String? _pastaType(String text) {
  for (final type in const [
    'spaghetti',
    'penne',
    'fusilli',
    'farfalle',
    'rigatoni',
    'tortellini',
    'lasagne',
    'spaetzle',
    'linguine',
    'kritharaki',
  ]) {
    if (_hasWord(text, type)) return type;
  }
  return null;
}

String? _coffeeType(String text) {
  if (_hasAny(text, const ['entkoffeiniert', 'koffeinfrei'])) return 'decaf';
  if (_hasAny(text, const ['instantkaffee', 'loeslicher kaffee', 'loeslich'])) {
    return 'instant';
  }
  if (_hasAny(text, const ['espresso'])) return 'espresso';
  if (_hasAny(text, const ['filterkaffee', 'filter'])) return 'filter';
  if (_hasAny(text, const ['kaffeebohnen', 'bohnenkaffee'])) return 'beans';
  return null;
}

String? _milkType(String text) =>
    _hasAny(text, const ['laktosefrei', 'laktosefreie']) ? 'laktosefrei' : null;

String? _yoghurtVariant(String text) {
  if (_hasAny(text, const ['griechisch', 'griechischer', 'griechische'])) {
    return 'griechisch';
  }
  if (_hasAny(text, const ['fruchtjoghurt', 'frucht joghurt', 'frucht'])) {
    return 'frucht';
  }
  if (_hasWord(text, 'skyr')) return 'skyr';
  if (_hasAny(text, const ['naturjoghurt', 'natur joghurt', 'natur'])) {
    return 'natur';
  }
  return null;
}

String? _eggVariant(String text) {
  if (_hasAny(text, const ['bioeier', 'bio eier', 'bio ei'])) return 'bio';
  if (_hasAny(text, const ['freilandeier', 'freiland eier', 'freiland ei'])) {
    return 'freiland';
  }
  if (_hasAny(text, const ['bodenhaltungseier', 'bodenhaltung eier'])) {
    return 'boden';
  }
  return null;
}

String? _riceType(String text) {
  if (_hasWord(text, 'basmati') || _hasWord(text, 'basmatireis')) {
    return 'basmati';
  }
  if (_hasWord(text, 'parboiled') || _hasWord(text, 'parboiledreis')) {
    return 'parboiled';
  }
  if (_hasWord(text, 'risotto') || _hasWord(text, 'risottoreis')) {
    return 'risotto';
  }
  return null;
}

String? _flourType(String text) {
  if (_hasWord(text, 'dinkel') || _hasWord(text, 'dinkelmehl')) {
    return 'dinkel';
  }
  if (_hasWord(text, 'vollkorn') || _hasWord(text, 'vollkornmehl')) {
    return 'vollkorn';
  }
  if (_hasWord(text, '405') || _hasWord(text, 'type 405')) return 'type405';
  if (_hasWord(text, '550') || _hasWord(text, 'type 550')) return 'type550';
  if (_hasWord(text, 'weizen') || _hasWord(text, 'weizenmehl')) {
    return 'weizen';
  }
  return null;
}

String? _oilType(String text) {
  if (_hasAny(text, const ['rapsoel', 'raps oel'])) return 'raps';
  if (_hasAny(text, const ['sonnenblumenoel', 'sonnenblumen oel'])) {
    return 'sonnenblume';
  }
  if (_hasAny(text, const ['olivenoel', 'oliven oel'])) return 'olive';
  if (_hasAny(text, const ['kokosoel', 'kokos oel'])) return 'kokos';
  return null;
}

String? _sugarType(String text) {
  if (_hasAny(text, const ['puderzucker', 'puder zucker'])) return 'puder';
  if (_hasAny(text, const ['brauner zucker', 'braunzucker'])) return 'braun';
  if (_hasAny(text, const ['weisser zucker', 'weisszucker'])) return 'weiss';
  return null;
}

String normalizeIdentityText(String value) => value
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss')
    .replaceAll('é', 'e')
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

bool _hasAny(String text, List<String> words) =>
    words.any((word) => _hasWord(text, word));

double? _percent(String text) {
  final match = RegExp(r'(\d+(?:[,.]\d+)?)\s*%').firstMatch(text);
  return match == null
      ? null
      : double.tryParse(match.group(1)!.replaceAll(',', '.'));
}

String? _cheeseVariant(String text) {
  for (final term in const [
    'gouda',
    'edamer',
    'emmentaler',
    'bergkaese',
    'butterkaese',
    'tilsiter',
  ]) {
    if (_hasWord(text, term)) return term;
  }
  return null;
}

String? _sausageVariant(String text) {
  for (final term in const [
    'salami',
    'lyoner',
    'schinkenwurst',
    'fleischwurst',
    'mortadella',
    'cervelat',
  ]) {
    if (_hasWord(text, term)) return term;
  }
  return null;
}

String? _tomatoVariant(String text) {
  if (_hasAny(text, const ['rispentomaten', 'rispen tomaten'])) return 'rispe';
  if (_hasAny(text, const ['partytomaten', 'party tomaten'])) return 'party';
  if (_hasAny(text, const ['cherrytomaten', 'cherry tomaten'])) return 'cherry';
  if (_hasAny(text, const ['cocktailtomaten', 'cocktail tomaten'])) {
    return 'cocktail';
  }
  return null;
}

String? _color(String text) {
  if (_hasAny(text, const ['rot', 'rote', 'roter', 'rotes'])) return 'rot';
  if (_hasAny(text, const ['gelb', 'gelbe', 'gelber'])) return 'gelb';
  if (_hasAny(text, const ['gruen', 'grüne', 'gruen'])) return 'gruen';
  return null;
}
