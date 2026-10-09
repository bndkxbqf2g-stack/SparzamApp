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

  // Chocolate snacks may contain the word "chips", but they do not share
  // the potato-chip price identity.
  if (_hasAny(text, const [
    'choco crossies',
    'choclait chips',
    'schoko chips',
    'schokochips',
  ])) {
    return const ProductIdentity(familyKey: 'schokolade', productType: 'snack');
  }
  // A Pizza-Donut is a baked snack with its own price identity. The pizza
  // token must not make it share a route price with frozen pizza.
  if (_hasAny(text, const ['pizza donut', 'pizzadonut'])) {
    return ProductIdentity(
      familyKey: 'backware',
      productType: 'donut',
      variant: _donutVariant(text),
    );
  }
  if (_hasAny(text, const ['chips', 'pringles', 'lays', 'kartoffelchips']) ||
      _hasJoinedPart(text, 'chips')) {
    return const ProductIdentity(familyKey: 'chips', productType: 'chips');
  }
  // Kaufland abbreviates "Knabbermäuse Salz" as `Kn.Mäuse Salz`. It is a
  // snack product, not a potato-chip identity.
  if (_hasAny(text, const ['knabbermaeuse', 'knabber maeuse', 'kn maeuse'])) {
    return const ProductIdentity(
      familyKey: 'snack',
      productType: 'knabbermaeuse',
    );
  }
  if (_hasWord(text, 'pizza') || _hasAny(text, const ['steinofenpizza'])) {
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
  // Milchschnitte is a chilled snack, not ordinary milk. Resolve the
  // compound before the generic milk rule so a search for "Milch" cannot
  // recommend a snack offer as a staple product.
  if (_hasAny(text, const ['milchschnitte', 'milch schnitte'])) {
    return const ProductIdentity(
      familyKey: 'snack',
      productType: 'milchschnitte',
    );
  }
  // Infant-formula labels contain a compound ending in "milch", but they
  // are not ordinary milk for a household shopping list. Keep them in a
  // separate baby-food family before the special drink and milk rules.
  if (_hasAny(text, const [
    'folgemilch',
    'folge milch',
    'anfangsmilch',
    'anfangs milch',
    'saeuglingsmilch',
    'saeuglings milch',
    'babymilch',
    'baby milch',
    'kindermilch',
    'kinder milch',
  ])) {
    return ProductIdentity(
      familyKey: 'babynahrung',
      productType: _babyMilkType(text),
    );
  }
  if (_hasAny(text, const ['muellermilch', 'milchgetraenk', 'milchdrink'])) {
    return const ProductIdentity(familyKey: 'milchgetraenk');
  }
  // Buttermilk and plant-based milk labels contain a compound ending in
  // "milch", but they are not ordinary cow's milk. Keep them in the drink
  // family so a generic milk search cannot reuse their prices.
  if (_hasAny(text, const [
    'buttermilch',
    'butter milch',
    'kokosmilch',
    'kokos milch',
    'sojamilch',
    'soja milch',
    'hafermilch',
    'hafer milch',
    'mandelmilch',
    'mandel milch',
  ])) {
    return ProductIdentity(
      familyKey: 'milchgetraenk',
      productType: _specialMilkDrinkType(text),
    );
  }
  // "Milch" also appears as an ingredient in unrelated products. Keep
  // those products out of the milk price family so a generic milk search does
  // not surface condensed milk, milk bars, chocolate or cheese first. The
  // later family rules still resolve the concrete product (for example
  // `Milch-Schokolade` as chocolate).
  if (_hasMilkFamilyToken(text) &&
      !_isMilkIngredientCompound(text) &&
      !_hasAny(text, const [
        'kaese',
        'gouda',
        'edamer',
        'emmentaler',
        'bergkaese',
        'butterkaese',
        'tilsiter',
        'camembert',
        'frischkaese',
        'frischk',
        'schmelzkaese',
        'schmelzk',
      ])) {
    return ProductIdentity(
      familyKey: 'milch',
      variant: _hasWord(text, 'h milch') ? 'h' : null,
      productType: _milkType(text),
      fatPercent: _percent(text),
    );
  }
  // Some current prospect feeds omit the generic noun from established
  // yoghurt lines such as "Almighurt", "Obstgarten" and "Frucht &
  // Knusper". Recognize those structural dairy labels, but keep yoghurt as
  // an ingredient separate from products such as yoghurt-based fresh cheese.
  if (_hasYoghurtFamilyToken(text)) {
    return ProductIdentity(
      familyKey: 'joghurt',
      variant: _yoghurtVariant(text),
    );
  }
  if (_hasDessertFamilyToken(text)) {
    return const ProductIdentity(familyKey: 'dessert');
  }
  if (_hasQuarkFamilyToken(text)) {
    return const ProductIdentity(familyKey: 'quark');
  }
  // Prospects sometimes put non-food tableware next to tea offers. A tea
  // glass must not become a hot-tea price candidate just because the label
  // contains the standalone word "Tee".
  if (_isTeaTablewareLabel(text)) {
    return const ProductIdentity(
      familyKey: 'haushalt',
      productType: 'tee_geschirr',
    );
  }
  // "EIS" is also used as a short non-food label. Resolve the known
  // advent-calendar wording before the generic ice-cream rule so a household
  // item cannot inherit a frozen-dessert price.
  if (_isNonFoodIceLabel(text)) {
    return const ProductIdentity(
      familyKey: 'haushalt',
      productType: 'adventskalender',
    );
  }
  if (_isProteinIceSnackLabel(text)) {
    return const ProductIdentity(
      familyKey: 'snack',
      productType: 'protein_snack',
    );
  }
  if (_hasAny(text, const [
    'ice cream',
    'eis',
    'eisbecher',
    'pirulo',
    'bounty ice',
  ])) {
    return const ProductIdentity(familyKey: 'eis', productType: 'eis');
  }
  if (_hasAny(text, const [
        'protein',
        'proteccino',
        'eiweissshake',
        'eiweiss drink',
      ]) &&
      !_hasAny(text, const [
        'fleisch',
        'rind',
        'schwein',
        'kalb',
        'gefluegel',
        'haehnchen',
        'hundenahrung',
        'hundefutter',
        'hundetrockenfutter',
        'hunde trockenfutter',
        'katzenfutter',
        'tierfutter',
        'tiernahrung',
      ])) {
    return const ProductIdentity(familyKey: 'protein');
  }
  if (_hasAny(text, const [
    'nivea',
    "l'oreal",
    'l oreal',
    'kosmetik',
    'make up',
    'shampoo',
    'duschgel',
  ])) {
    return const ProductIdentity(familyKey: 'kosmetik');
  }
  if (_hasAny(text, const ['nutella', 'nuss nougat', 'nussnougat'])) {
    return const ProductIdentity(familyKey: 'suessigkeit');
  }
  if (_isCheeseCreamLabel(text)) {
    return const ProductIdentity(familyKey: 'kaese', variant: 'creme');
  }
  if (_isSavoryCreamCompound(text)) {
    return const ProductIdentity(familyKey: 'feinkost', productType: 'creme');
  }
  if (_hasCreamFamilyToken(text)) {
    return ProductIdentity(familyKey: 'creme', productType: _creamType(text));
  }
  if (_hasAny(text, const [
    'bier',
    'pils',
    'radler',
    'rad',
    'helles bier',
    'moench hell',
    'desperados',
  ])) {
    return const ProductIdentity(familyKey: 'bier');
  }
  if (_hasAny(text, const ['limonade', 'gazoz', 'uludag'])) {
    return const ProductIdentity(familyKey: 'limonade');
  }
  if (_hasAny(text, const [
    'wasserkocher',
    'wasserkessel',
    'wasserfilter',
    'wasserflter',
    'tischwasserfilter',
    'wassersprudler',
    'wasserfilter kartuschen',
    'maxtra',
  ])) {
    return const ProductIdentity(
      familyKey: 'wassergeraet',
      productType: 'haushalt',
    );
  }
  if (_hasWaterFamilyToken(text)) {
    return ProductIdentity(
      familyKey: 'wasser',
      productType:
          _hasAny(text, const ['mineralwasser', 'tafelwasser', 'quellwasser'])
          ? 'mineral'
          : null,
    );
  }
  // These labels contain beverage words but are sausage/salad products. They
  // must be resolved before the generic juice/tea families below.
  if (_hasAny(text, const ['fleischsalat'])) {
    return const ProductIdentity(
      familyKey: 'salat',
      productType: 'fleischsalat',
    );
  }
  if (_hasAny(text, const [
    'bockwurst',
    'teewurst',
    'fruehstuecksfleisch',
    'fruehstuecks fleisch',
  ])) {
    return ProductIdentity(familyKey: 'wurst', variant: _sausageVariant(text));
  }
  if (_hasAny(text, const [
    'saft',
    'fruchtsaft',
    'fruchtsaftgetraenk',
    'fruchtnektar',
    'apfelsaft',
    'orangensaft',
    'traubensaft',
    'nektar',
    'saftgetraenk',
  ])) {
    return ProductIdentity(familyKey: 'saft', productType: _juiceType(text));
  }
  if (_hasAny(text, const [
    'tee',
    'eistee',
    'teegetraenk',
    'kamillentee',
    'kamillen tee',
    'kraeutertee',
    'kraeuter tee',
    'pfefferminztee',
    'pfefferminz tee',
    'schwarztee',
    'gruenentee',
    'gruen tee',
  ])) {
    return ProductIdentity(familyKey: 'tee', productType: _teaType(text));
  }
  if (_hasAny(text, const [
    'hundenahrung',
    'hundefutter',
    'hundetrockenfutter',
    'hunde trockenfutter',
    'katzenfutter',
    'tierfutter',
    'tiernahrung',
  ])) {
    return const ProductIdentity(familyKey: 'tiernahrung');
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
  // Kaufland abbreviates "Kloß Fränkische Art" as `K.Klo Frän.Art750g`.
  // The short token `Klo` is also used in the household alias `Klopapier`,
  // so resolve the dumpling family before the generic toilet-paper rule.
  if (text.contains('kloss') ||
      text.contains('kloesse') ||
      RegExp(r'\bklo\s+fraen(?:kisch)?\b').hasMatch(text)) {
    return const ProductIdentity(
      familyKey: 'kloesse',
      productType: 'kartoffel',
    );
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
  if (_hasAny(text, const ['kartoffel', 'kartoffeln', 'wedges'])) {
    return ProductIdentity(
      familyKey: 'kartoffeln',
      productType: _hasWord(text, 'wedges') ? 'wedges' : null,
    );
  }
  // "Butter" also appears in compound labels for cheese and vegetables.
  // Resolve those products before the generic butter rule so their offers
  // cannot be reused as a spread or cooking-butter price.
  if (_hasAny(text, const ['butterkaese', 'butter kaese'])) {
    return const ProductIdentity(familyKey: 'kaese', variant: 'butterkaese');
  }
  if (_hasAny(text, const ['buttergemuese', 'butter gemuese'])) {
    return const ProductIdentity(
      familyKey: 'gemuese',
      productType: 'buttergemuese',
    );
  }
  if (_hasAny(text, const ['erdnussbutter', 'erdnuss butter'])) {
    return const ProductIdentity(
      familyKey: 'aufstrich',
      productType: 'erdnussbutter',
    );
  }
  if (_hasAny(text, const ['butterschmalz'])) {
    return const ProductIdentity(familyKey: 'butter', variant: 'butterschmalz');
  }
  if (_hasAny(text, const ['butter'])) {
    return const ProductIdentity(familyKey: 'butter');
  }
  if (_isChocolateRiceLabel(text)) {
    return const ProductIdentity(
      familyKey: 'schokolade',
      productType: 'reis_snack',
    );
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
  if (_hasSugarFamilyToken(text)) {
    return ProductIdentity(familyKey: 'zucker', productType: _sugarType(text));
  }
  if (_hasAny(text, const [
    'salz staengli',
    'salzstaengli',
    'kaese staengli',
    'kaese oder salz staengli',
  ])) {
    return const ProductIdentity(familyKey: 'snack', productType: 'staengli');
  }
  if (_hasAny(text, const ['salz', 'speisesalz'])) {
    return const ProductIdentity(familyKey: 'salz');
  }
  if (_hasAny(text, const ['ketchup'])) {
    return const ProductIdentity(familyKey: 'ketchup');
  }
  if (_hasAny(text, const [
    'kraeuter',
    'ital kraeuter',
    'italienische kraeuter',
  ])) {
    return const ProductIdentity(familyKey: 'kraeuter');
  }
  if (_hasAny(text, const ['toilettenpapier', 'klopapier', 'klo'])) {
    return const ProductIdentity(familyKey: 'toilettenpapier');
  }
  if (_hasAny(text, const ['softlan', 'weichspueler', 'weichspüler'])) {
    return const ProductIdentity(familyKey: 'weichspueler');
  }
  if (_hasAny(text, const ['kohlrabi'])) {
    return const ProductIdentity(familyKey: 'kohlrabi');
  }
  if (_hasSaladFamilyToken(text)) {
    return ProductIdentity(
      familyKey: 'salat',
      productType: _hasWord(text, 'eisbergsalat') ? 'eisberg' : null,
    );
  }
  if (_hasAny(text, const ['zwiebel', 'zwiebeln'])) {
    return ProductIdentity(familyKey: 'zwiebeln', color: _color(text));
  }
  if (_hasAny(text, const ['ananas', 'ananasscheiben'])) {
    return const ProductIdentity(familyKey: 'ananas');
  }
  if (_hasAny(text, const ['mais', 'gemuese mais', 'gemüsemais'])) {
    return const ProductIdentity(familyKey: 'mais');
  }
  if (_hasAny(text, const ['erbsen', 'erbsen moehren', 'erbsen möhren'])) {
    return ProductIdentity(
      familyKey: 'gemuese',
      productType: _hasAny(text, const ['moehren', 'möhren'])
          ? 'erbsen_moehren'
          : 'erbsen',
    );
  }
  if (_hasAny(text, const ['kaiser gemuese', 'kaiser', 'kaisergemuese'])) {
    return const ProductIdentity(
      familyKey: 'gemuese',
      productType: 'kaisergemuese',
    );
  }
  if (_hasVegetableFamilyToken(text)) {
    return const ProductIdentity(familyKey: 'gemuese');
  }
  // Tomato products must be classified before fresh tomatoes. Matching the
  // token "tomate" alone must never turn tomato paste/sauce into fresh produce.
  if (_hasAny(text, const ['tomatenmark', 'tomaten mark'])) {
    return const ProductIdentity(familyKey: 'tomatenmark', productType: 'mark');
  }
  if (_hasAny(text, const [
    'tomatenkonserve',
    'konserventomaten',
    'konserven tomaten',
  ])) {
    return const ProductIdentity(familyKey: 'tomatenkonserve');
  }
  if (_hasAny(text, const ['passata', 'passierte tomaten', 'passierte'])) {
    return const ProductIdentity(
      familyKey: 'tomatenkonserve',
      productType: 'passata',
    );
  }
  if (_hasAny(text, const [
    'gehackte tomaten',
    'gehackte',
    'geh tomaten',
    'dosentomaten',
    'dosen tomaten',
  ])) {
    return const ProductIdentity(
      familyKey: 'tomatenkonserve',
      productType: 'gehackt',
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
    'ta rot',
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
  if (_hasAny(text, const ['donut', 'franzbroetchen', 'franz broetchen'])) {
    return const ProductIdentity(familyKey: 'backware', productType: 'donut');
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
  if (_hasAny(text, const ['brotaufstrich', 'brotaufstriche', 'brotbelag'])) {
    return const ProductIdentity(
      familyKey: 'aufstrich',
      productType: 'brotaufstrich',
    );
  }
  if (_hasBreadFamilyToken(text)) {
    return ProductIdentity(familyKey: 'brot', productType: _breadType(text));
  }
  if (_hasAny(text, const ['marmelade', 'konfituere', 'fruchtaufstrich'])) {
    return const ProductIdentity(familyKey: 'marmelade');
  }
  if (_hasAny(text, const [
    'pasta sauce',
    'pastasauce',
    'pasta sosse',
    'pastasosse',
    'nudel sauce',
    'nudelsauce',
    'nudel sosse',
    'nudelsosse',
  ])) {
    return const ProductIdentity(familyKey: 'sauce', productType: 'pasta');
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
  if (_isToyCoffeeLabel(text)) {
    return const ProductIdentity(
      familyKey: 'haushalt',
      productType: 'spielzeug',
    );
  }
  // Coffee also appears as an ingredient or as part of a non-coffee product
  // name. Keep those products out of a generic coffee search while still
  // recognizing capsules and pads as coffee variants.
  if (_hasAny(text, const [
    'kaffee gebaeck',
    'kaffeegebaeck',
    'kaffee kuchen',
    'kaffeekuchen',
    'kaffee torte',
    'kaffeetorte',
    'kaffee bonbon',
    'kaffeebonbon',
  ])) {
    return const ProductIdentity(
      familyKey: 'backware',
      productType: 'kaffeegebaeck',
    );
  }
  if (_hasAny(text, const [
    'kaffee getraenk',
    'kaffeegetraenk',
    'kaffee drink',
  ])) {
    return const ProductIdentity(familyKey: 'kaffeegetraenk');
  }
  if (_hasAny(text, const [
    'kaffeemaschine',
    'kaffee maschine',
    'kaffeevollautomat',
    'espressomaschine',
    'dolce gusto piccolo',
    'dolce gusto genio',
    'dolce gusto maschine',
  ])) {
    return const ProductIdentity(familyKey: 'kaffeemaschine');
  }
  if (_hasAny(text, const [
    'kaffee',
    'cafe',
    'landkaffee',
    'kaffeekapsel',
    'kaffeekapseln',
    'kaffee kapsel',
    'kaffeepad',
    'kaffeepads',
    'kaffee pads',
    'dolce gusto',
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
  if (_isChickenCheeseSnackLabel(text)) {
    return const ProductIdentity(
      familyKey: 'snack',
      productType: 'kaese_ecken',
    );
  }
  if (_isCheesecakeSnackLabel(text)) {
    return const ProductIdentity(
      familyKey: 'snack',
      productType: 'kaesekuchen',
    );
  }
  // Cheese can be only an ingredient in a sausage or snack. Those products
  // retain their own identity so a generic cheese request cannot route them
  // as cheese.
  if (_hasAny(text, const [
    'kaese wiener',
    'kaesewiener',
    'kaese salami',
    'kaesesalami',
    'leberkaese',
    'leber kaese',
    'fleischkaese',
    'fleisch kaese',
  ])) {
    return ProductIdentity(
      familyKey: 'wurst',
      variant: _hasAny(text, const ['leberkaese', 'leber kaese'])
          ? 'leberkaese'
          : _hasAny(text, const ['fleischkaese', 'fleisch kaese'])
          ? 'fleischkaese'
          : _hasAny(text, const ['kaese salami', 'kaesesalami'])
          ? 'salami'
          : 'wiener',
    );
  }
  if (_hasCheeseFamilyToken(text)) {
    return ProductIdentity(familyKey: 'kaese', variant: _cheeseVariant(text));
  }
  if (_hasAny(text, const ['piccolinis'])) {
    return const ProductIdentity(familyKey: 'pizza', productType: 'pizza');
  }
  if (_hasAny(text, const ['schinkenkrustenbraten', 'eisbein'])) {
    return const ProductIdentity(familyKey: 'fleisch', productType: 'braten');
  }
  if (_hasAny(text, const ['schnitzel'])) {
    return const ProductIdentity(
      familyKey: 'fleisch',
      productType: 'schnitzel',
    );
  }
  if (_hasSausageFamilyToken(text)) {
    return ProductIdentity(familyKey: 'wurst', variant: _sausageVariant(text));
  }
  if (_hasAny(text, const ['fischstäbchen', 'fischstaebchen'])) {
    return const ProductIdentity(familyKey: 'fischstäbchen');
  }
  if (_hasAny(text, const ['schlemmerfilet', 'fischfilet'])) {
    return const ProductIdentity(
      familyKey: 'fischfilet',
      productType: 'schlemmerfilet',
    );
  }
  if (_hasAny(text, const ['haehnchenbrust', 'hähnchenbrust'])) {
    return const ProductIdentity(
      familyKey: 'fleisch',
      productType: 'hähnchenbrust',
    );
  }
  if (_hasAny(text, const ['schlemmerbraten', 'braten'])) {
    return const ProductIdentity(familyKey: 'fleisch', productType: 'braten');
  }
  if (_hasMeatFamilyToken(text)) {
    return ProductIdentity(familyKey: 'fleisch', meatType: _meatType(text));
  }
  if (_hasAny(text, const ['nudeltopf', 'linseneintopf', 'eintopf'])) {
    return ProductIdentity(
      familyKey: 'eintopf',
      productType: _hasWord(text, 'linseneintopf')
          ? 'linseneintopf'
          : 'nudeltopf',
    );
  }
  if (_hasAny(text, const ['muesliriegel', 'müsliriegel', 'riegel'])) {
    return const ProductIdentity(
      familyKey: 'snack',
      productType: 'muesliriegel',
    );
  }
  if (_hasChocolateFamilyToken(text)) {
    return const ProductIdentity(familyKey: 'schokolade');
  }
  if (_hasAny(text, const ['haribo', 'baella', 'balla', 'suessigkeit'])) {
    return const ProductIdentity(familyKey: 'suessigkeit');
  }
  if (_hasAny(text, const [
    'hollandaise',
    'hollandaise sauce',
    'holl legere',
    'holl zitrone',
  ])) {
    return const ProductIdentity(
      familyKey: 'sauce',
      productType: 'hollandaise',
    );
  }
  final currentProspectIdentity = _currentProspectIdentity(text);
  if (currentProspectIdentity != null) return currentProspectIdentity;
  return const ProductIdentity(familyKey: null);
}

/// Resolves common food labels used by the current public prospect feed when
/// they do not contain one of the established catalog nouns. The rules are
/// family-level and intentionally conservative: they make an offer searchable
/// without claiming a concrete brand, pack size, or price identity.
ProductIdentity? _currentProspectIdentity(String text) {
  if (_hasAny(text, const ['mandarine', 'mandarinen'])) {
    return const ProductIdentity(familyKey: 'mandarinen');
  }
  if (_hasAny(text, const ['kiwi', 'sungold'])) {
    return const ProductIdentity(familyKey: 'kiwi');
  }
  if (_hasAny(text, const ['avocado'])) {
    return const ProductIdentity(familyKey: 'avocado');
  }
  if (_hasAny(text, const ['pomelo'])) {
    return const ProductIdentity(familyKey: 'pomelo');
  }
  if (_hasAny(text, const ['kaki', 'sharon'])) {
    return const ProductIdentity(familyKey: 'kaki');
  }
  if (_hasAny(text, const ['orange', 'orangen'])) {
    return const ProductIdentity(familyKey: 'orangen');
  }
  if (_hasAny(text, const ['mango'])) {
    return const ProductIdentity(familyKey: 'mango');
  }
  if (_hasAny(text, const [
    'heidelbeere',
    'heidelbeeren',
    'himbeere',
    'himbeeren',
    'physalis',
  ]) ||
      _hasJoinedPart(text, 'heidelbeere') ||
      _hasJoinedPart(text, 'himbeere')) {
    return ProductIdentity(
      familyKey: 'beeren',
      productType: _hasAny(text, const ['heidelbeere', 'heidelbeeren'])
          ? 'heidelbeere'
          : _hasAny(text, const ['himbeere', 'himbeeren'])
          ? 'himbeere'
          : 'physalis',
    );
  }
  if (_hasAny(text, const ['zwetschge', 'zwetschgen']) ||
      _hasJoinedPart(text, 'zwetschge')) {
    return const ProductIdentity(familyKey: 'zwetschgen');
  }
  if (_hasAny(text, const ['zitrone', 'zitronen'])) {
    return const ProductIdentity(familyKey: 'zitronen');
  }
  if (_hasAny(text, const ['trauben', 'tafeltrauben', 'weintrauben']) ||
      _hasJoinedSuffix(text, 'trauben')) {
    return const ProductIdentity(familyKey: 'weintrauben');
  }
  if (_hasAny(text, const ['salatgurke', 'gurke', 'gurken']) ||
      _hasJoinedSuffix(text, 'gurken')) {
    return const ProductIdentity(familyKey: 'gurken');
  }
  if (_hasAny(text, const ['moehre', 'moehren', 'karotte', 'karotten'])) {
    return const ProductIdentity(familyKey: 'moehren');
  }
  if (_hasJoinedPart(text, 'moehre') || _hasJoinedPart(text, 'karotte')) {
    return const ProductIdentity(familyKey: 'moehren');
  }
  if (_hasAny(text, const ['spinat'])) {
    return const ProductIdentity(familyKey: 'spinat');
  }
  if (_hasAny(text, const ['spitzkohl', 'rosenkohl', 'kohl'])) {
    return const ProductIdentity(familyKey: 'kohl');
  }
  if (_hasAny(text, const ['sellerie'])) {
    return const ProductIdentity(familyKey: 'sellerie');
  }
  if (_hasAny(text, const ['rote bete', 'rotebete'])) {
    return const ProductIdentity(familyKey: 'rotebete');
  }
  if (_hasAny(text, const ['zucchini'])) {
    return const ProductIdentity(familyKey: 'zucchini');
  }
  if (_hasAny(text, const ['edamame', 'pilze', 'champignon'])) {
    return const ProductIdentity(familyKey: 'gemuese');
  }
  if (_hasAny(text, const [
    'zierkurbis',
    'zierkuerbis',
    'halloween kurbis',
    'halloween kuerbis',
    'folienballon',
    'kuerbis schnitz',
    'kuerbis schnitzset',
  ])) {
    return null;
  }
  if (_hasAny(text, const ['kuerbissuppe', 'kuerbis suppe'])) {
    return const ProductIdentity(familyKey: 'suppe');
  }
  if (_hasAny(text, const ['kuerbiskuchen', 'kuerbis kuchen'])) {
    return const ProductIdentity(familyKey: 'dessert');
  }
  if (_hasAny(text, const ['kuerbis', 'kuerbisse']) ||
      _hasJoinedPart(text, 'kuerbis')) {
    return const ProductIdentity(familyKey: 'kuerbis');
  }
  if (_hasAny(text, const [
    'pfannengericht',
    'fertiggericht',
    'fertiggerichte',
    'fruehlingsrollen',
    'gyoza',
    'sushi',
    'chicken nuggets',
    'nuggets',
    'chicken',
    'mikrowellengericht',
  ])) {
    return const ProductIdentity(familyKey: 'fertiggericht');
  }
  if (_hasAny(text, const [
    'mousse',
    'tiramisu',
    'cheesecake',
    'lava cake',
    'cake pops',
    'macaron',
    'mini desserts',
    'creme brulee',
    'paradiescreme',
    'fruchtgruetze',
    'törtchen',
    'toertchen',
    'kuechlein',
    'macarons',
    'kuchen',
  ])) {
    return const ProductIdentity(familyKey: 'dessert');
  }
  if (_hasAny(text, const [
        'berliner',
        'pfannkuchen',
        'magdalenas',
        'torte',
        'pastel de nata',
        'churros',
        'schnecken',
      ]) ||
      _hasJoinedPart(text, 'torte') ||
      _hasJoinedPart(text, 'schnecke')) {
    return const ProductIdentity(familyKey: 'backware');
  }
  if (_hasAny(text, const [
        'dorade',
        'doraden',
        'lachs',
        'seelachs',
        'rotbarsch',
        'thunfisch',
        'kabeljau',
        'garnele',
        'garnelen',
      ]) ||
      _hasJoinedSuffix(text, 'lachs') ||
      _hasJoinedSuffix(text, 'kabeljau') ||
      _hasJoinedPart(text, 'fisch') ||
      _hasJoinedPart(text, 'barsch') ||
      _hasJoinedPart(text, 'garnelen')) {
    return const ProductIdentity(familyKey: 'fisch');
  }
  if (_hasAny(text, const ['mayonnaise', 'mayo'])) {
    return const ProductIdentity(familyKey: 'mayonnaise');
  }
  if (_hasAny(text, const ['pesto', 'sojasauce', 'sriracha'])) {
    return ProductIdentity(
      familyKey: 'sauce',
      productType: _hasWord(text, 'pesto')
          ? 'pesto'
          : _hasWord(text, 'sojasauce')
          ? 'soja'
          : 'sriracha',
    );
  }
  if (_hasAny(text, const ['hummus'])) {
    return const ProductIdentity(familyKey: 'aufstrich', productType: 'hummus');
  }
  if (_hasAny(text, const ['dip'])) {
    return const ProductIdentity(familyKey: 'aufstrich', productType: 'dip');
  }
  if (_hasAny(text, const ['margarine', 'streichfett', 'sanella'])) {
    return const ProductIdentity(familyKey: 'margarine');
  }
  if (_hasAny(text, const ['oliven', 'olive'])) {
    return const ProductIdentity(familyKey: 'oliven');
  }
  if (_hasAny(text, const ['kakao', 'kakaoshake'])) {
    return const ProductIdentity(familyKey: 'kakao');
  }
  if (_hasAny(text, const ['smoothie'])) {
    return const ProductIdentity(familyKey: 'smoothie');
  }
  if (_hasAny(text, const ['energy drink', 'energy'])) {
    return const ProductIdentity(familyKey: 'energydrink');
  }
  if (_hasAny(text, const ['sirup'])) {
    return const ProductIdentity(familyKey: 'sirup');
  }
  if (_hasAny(text, const ['cola', 'limo', 'pepsi', 'coca cola'])) {
    return const ProductIdentity(familyKey: 'limonade');
  }
  if (_hasAny(text, const ['weinessig', 'wein essig'])) return null;
  if (_hasAny(text, const ['wein', 'roséwein', 'rosewein'])) {
    return const ProductIdentity(familyKey: 'wein');
  }
  if (_hasAny(text, const ['sekt', 'prosecco'])) {
    return const ProductIdentity(familyKey: 'sekt');
  }
  if (_hasAny(text, const [
        'gin',
        'rum',
        'whisky',
        'wodka',
        'vodka',
        'aperol',
        'likoer',
        'weinbrand',
      ]) ||
      _hasJoinedSuffix(text, 'likoer')) {
    return const ProductIdentity(familyKey: 'spirituosen');
  }
  if (_hasAny(text, const [
    'cracker',
    'salzstangen',
    'tortillas',
    'popcorn',
    'flips',
    'knabber',
  ])) {
    return const ProductIdentity(familyKey: 'snack');
  }
  if (_hasAny(text, const [
    'bonbon',
    'pastillen',
    'cookies',
    'keks',
    'pralinen',
    'praline',
    'marzipan',
    'waffel',
    'mon cheri',
  ])) {
    return const ProductIdentity(familyKey: 'suessigkeit');
  }
  if (_hasAny(text, const ['hunde', 'hund', 'lucky dog', 'katze', 'katzen'])) {
    return const ProductIdentity(familyKey: 'tiernahrung');
  }
  if (_hasJoinedPart(text, 'kefir')) {
    return const ProductIdentity(
      familyKey: 'milchgetraenk',
      productType: 'kefir',
    );
  }
  if (_hasAny(text, const ['sauce', 'hellmann'])) {
    return const ProductIdentity(familyKey: 'sauce', productType: 'sauce');
  }
  if (_hasAny(text, const ['feinkostsalat'])) {
    return const ProductIdentity(familyKey: 'feinkost', productType: 'salat');
  }
  if (_hasAny(text, const ['apricot peppers', 'peppers'])) {
    return const ProductIdentity(familyKey: 'paprika');
  }
  if (_hasAny(text, const ['snack', 'frucht snack'])) {
    return const ProductIdentity(familyKey: 'snack');
  }
  if (_hasAny(text, const ['getraenkepulver', 'nesquik'])) {
    return const ProductIdentity(familyKey: 'kakao');
  }
  if (_hasJoinedPart(text, 'shot')) {
    return const ProductIdentity(familyKey: 'saft', productType: 'shot');
  }
  if (_hasAny(text, const ['trinkmahlzeit'])) {
    return const ProductIdentity(familyKey: 'protein');
  }
  if (_hasAny(text, const ['matcha'])) {
    return const ProductIdentity(familyKey: 'tee', productType: 'matcha');
  }
  if (_hasAny(text, const ['naturradler'])) {
    return const ProductIdentity(familyKey: 'bier');
  }
  if (_hasJoinedPart(text, 'hund')) {
    return const ProductIdentity(familyKey: 'tiernahrung');
  }
  if (_hasAny(text, const ['purina', 'felix', 'perfect fit', 'gourmet gold'])) {
    return const ProductIdentity(familyKey: 'tiernahrung');
  }
  if (_hasAny(text, const ['sauerkraut', 'mildessa'])) {
    return const ProductIdentity(familyKey: 'sauerkraut');
  }
  if (_hasAny(text, const ['sauerkirsche', 'sauerkirschen'])) {
    return const ProductIdentity(familyKey: 'kirschen');
  }
  if (_hasAny(text, const ['fond'])) {
    return const ProductIdentity(familyKey: 'bruehe');
  }
  if (_hasAny(text, const ['curry paste', 'currypaste'])) {
    return const ProductIdentity(familyKey: 'sauce', productType: 'curry');
  }
  if (_hasAny(text, const ['wuerze', 'maggi wuerze'])) {
    return const ProductIdentity(familyKey: 'sauce', productType: 'wuerze');
  }
  if (_hasAny(text, const ['suppe', 'suppen', 'terrine', 'terrin'])) {
    return const ProductIdentity(familyKey: 'suppe');
  }
  if (_hasAny(text, const ['guai thiau', 'soba', 'udon', 'noodle', 'pho'])) {
    return const ProductIdentity(familyKey: 'nudeln', productType: 'asia');
  }
  if (_hasAny(text, const [
    'porridge',
    'cerealien',
    'muesli',
    'haferflocken',
    'basis muesli',
  ])) {
    return ProductIdentity(
      familyKey: 'fruehstueck',
      productType: _hasAny(text, const ['porridge'])
          ? 'porridge'
          : _hasAny(text, const ['haferflocken'])
          ? 'haferflocken'
          : 'muesli',
    );
  }
  if (_hasAny(text, const ['chiasamen'])) {
    return const ProductIdentity(familyKey: 'saaten', productType: 'chia');
  }
  if (_hasAny(text, const ['haselnusscreme', 'nuss nougat', 'nussnougat'])) {
    return const ProductIdentity(
      familyKey: 'aufstrich',
      productType: 'nusscreme',
    );
  }
  if (_hasAny(text, const [
        'walnuss',
        'walnuesse',
        'cashew',
        'paranuss',
        'mandel',
        'studentenfutter',
        'nuss mix',
        'nussmix',
      ]) ||
      _hasJoinedPart(text, 'walnuss') ||
      _hasJoinedPart(text, 'cashew') ||
      _hasJoinedPart(text, 'paranuss') ||
      _hasJoinedPart(text, 'haselnuss') ||
      _hasJoinedPart(text, 'mandel') ||
      _hasJoinedPart(text, 'erdnuss')) {
    return const ProductIdentity(familyKey: 'nuesse');
  }
  if (_hasJoinedPart(text, 'sultanine') ||
      _hasJoinedPart(text, 'rosine') ||
      _hasJoinedPart(text, 'dattel')) {
    return const ProductIdentity(familyKey: 'trockenfrucht');
  }
  if (_hasAny(text, const [
        'backzutat',
        'backzutaten',
        'backaroma',
        'trockenhefe',
        'vanille extrakt',
        'vanille paste',
        'mohn back',
        'kuchenglasur',
        'streudekor',
        'krokant',
        'streusel',
        'perlchen',
        'marshmallow',
      ]) ||
      _hasJoinedPart(text, 'marshmallow')) {
    return const ProductIdentity(familyKey: 'backzutaten');
  }
  if (_hasAny(text, const ['honig', 'blueternhonig', 'blütenhonig'])) {
    return const ProductIdentity(familyKey: 'honig');
  }
  if (_hasAny(text, const ['ingwer shot', 'ingwer-shot', 'shot'])) {
    return const ProductIdentity(familyKey: 'saft', productType: 'shot');
  }
  if (_hasAny(text, const ['red bull'])) {
    return const ProductIdentity(familyKey: 'energydrink');
  }
  if (_hasAny(text, const ['amaro', 'weinaperitif', 'havana club', 'lillet'])) {
    return const ProductIdentity(familyKey: 'spirituosen');
  }
  if (_hasAny(text, const ['alkoholisches mixgetraenk', 'mixgetraenk'])) {
    return const ProductIdentity(familyKey: 'spirituosen');
  }
  if (_hasJoinedPart(text, 'wein') ||
      _hasAny(text, const [
        'riesling',
        'trollinger',
        'shiraz',
        'cabernet',
        'pinot',
        'merlot',
        'muscato',
        'burgunder',
        'tempranillo',
        'imiglykos',
        'bubbly',
      ])) {
    return const ProductIdentity(familyKey: 'wein');
  }
  if (_hasAny(text, const ['pilsener', 'weissbier', 'helles', 'radler']) ||
      _hasJoinedPart(text, 'bier') ||
      _hasJoinedPart(text, 'pils')) {
    return const ProductIdentity(familyKey: 'bier');
  }
  if (_hasAny(text, const [
        'fruchtgummi',
        'bonbons',
        'lebkuchen',
        'spekulatius',
        'schoko',
        'schokolinsen',
        'schokobons',
        'nougat',
        'waffelschnitte',
        'schnitten',
        'pick up',
        'werthers',
        'tafelchen',
      ]) ||
      _hasJoinedPart(text, 'fruchtgummi') ||
      _hasJoinedPart(text, 'lebkuchen') ||
      _hasJoinedPart(text, 'marzipan') ||
      _hasJoinedPart(text, 'schoko') ||
      _hasJoinedPart(text, 'schkolad') ||
      _hasJoinedPart(text, 'bonbon') ||
      _hasJoinedPart(text, 'waffel')) {
    return const ProductIdentity(familyKey: 'suessigkeit');
  }
  return null;
}

bool _hasYoghurtFamilyToken(String text) {
  if (_hasAny(text, const [
    'frischkaesezubereitung',
    'frischkaese zubereitung',
    'joghurt dressing',
    'joghurt dip',
    'joghurt sauce',
    'joghurt sosse',
  ])) {
    return false;
  }
  return text.contains('joghurt') ||
      text.contains('jogurt') ||
      _hasWord(text, 'jogh') ||
      _hasWord(text, 'skyr') ||
      RegExp(r'\b[a-z]{3,}ghurt\b').hasMatch(text) ||
      _hasAny(text, const ['obstgarten', 'frucht knusper', 'frucht & knusper']);
}

bool compatibleProductIdentity(
  ProductIdentity request,
  ProductIdentity candidate,
) {
  final sameFamily =
      request.familyKey == candidate.familyKey ||
      // Toast is a stored legacy family. A generic bread request may still
      // include it, while a specific toast request remains distinct.
      (request.familyKey == 'brot' && candidate.familyKey == 'toast') ||
      // Mince is a meat subfamily and remains useful for a generic meat list.
      (request.familyKey == 'fleisch' &&
          request.isGeneric &&
          candidate.familyKey == 'hackfleisch');
  if (!request.isKnown || !sameFamily) {
    return false;
  }
  // A generic "Tee" request means hot tea (tea bags/leaves). Iced tea is a
  // separate ready-to-drink beverage and must only match an explicit
  // "Eistee" request. Without this guard, a cheap iced-tea offer can displace
  // household tea suggestions in the shopping list.
  if (request.familyKey == 'tee' &&
      request.productType == null &&
      (candidate.productType == 'eistee' ||
          candidate.productType == 'teegetraenk')) {
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

/// Opens an abbreviated H-milk request to the ordinary milk choices that can
/// be compared without guessing a fat level. Kaufland receipt labels such as
/// `K.H-Milch` do not state whether the shopper bought 1.5 %, 3.5 %, or plain
/// fresh milk. Keep each catalog product and its price identity separate, but
/// let the shopping flow rank all ordinary milk choices by current evidence.
bool isOpenMilkChoice(ProductIdentity request, ProductIdentity candidate) =>
    request.familyKey == 'milch' &&
    request.variant == 'h' &&
    request.fatPercent == null &&
    request.productType == null &&
    candidate.familyKey == 'milch' &&
    candidate.variant == null &&
    candidate.productType == null;

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

String? _juiceType(String text) {
  if (_hasAny(text, const ['apfelsaft'])) return 'apfel';
  if (_hasAny(text, const ['orangensaft'])) return 'orange';
  if (_hasAny(text, const ['traubensaft'])) return 'traube';
  if (_hasAny(text, const ['nektar', 'fruchtnektar'])) return 'nektar';
  if (_hasAny(text, const ['fruchtsaft', 'fruchtsaftgetraenk'])) {
    return 'frucht';
  }
  return null;
}

String? _teaType(String text) {
  if (_hasAny(text, const ['eistee'])) return 'eistee';
  if (_hasAny(text, const ['teegetraenk', 'tee getraenk'])) {
    return 'teegetraenk';
  }
  if (_hasAny(text, const ['kamillentee', 'kamillen tee'])) return 'kamille';
  if (_hasAny(text, const ['pfefferminztee', 'pfefferminz tee'])) {
    return 'pfefferminze';
  }
  if (_hasAny(text, const ['schwarztee'])) return 'schwarz';
  if (_hasAny(text, const ['kraeutertee', 'kraeuter tee'])) return 'kraeuter';
  if (_hasAny(text, const ['gruenentee', 'gruen tee'])) return 'gruen';
  return null;
}

bool _isTeaTablewareLabel(String text) => _hasAny(text, const [
  'tee glas',
  'tee glaeser',
  'teeglas',
  'teeglaeser',
  'tee tasse',
  'tee tassen',
  'teetasse',
  'teetassen',
]);

bool _isNonFoodIceLabel(String text) =>
    _hasWord(text, 'eis') &&
    _hasAny(text, const ['adventskalender', 'erotisch', 'erotischer', 'adult']);

bool _isProteinIceSnackLabel(String text) =>
    _hasAny(text, const ['ice cream', 'eis']) &&
    _hasAny(text, const ['protein bar', 'energy balls']);

bool _isToyCoffeeLabel(String text) =>
    _hasWord(text, 'holz') && _hasWord(text, 'kaffee');

bool _isCheeseCreamLabel(String text) =>
    _hasAny(text, const ['kaese creme', 'kaesecreme']);

bool _isSavoryCreamCompound(String text) =>
    (text.contains('creme') || _hasWord(text, 'creme')) &&
    (_hasAny(text, const [
          'antipasti',
          'dillcreme',
          'heringshappen',
          'hering',
          'fisch',
          'feinkost',
        ]) ||
        RegExp(r'(?<![a-z0-9])(?:dill|antipasti)creme(?![a-z0-9])')
            .hasMatch(text));

bool _isChocolateRiceLabel(String text) => _hasAny(text, const [
  'schoko reis',
  'schokoreis',
  'reis tafel',
  'reistafel',
]);

bool _isChickenCheeseSnackLabel(String text) =>
    _hasAny(text, const ['kaese ecken', 'kaeseecken']) &&
    _hasAny(text, const ['haehnchen', 'huehnchen', 'chicken']);

bool _isCheesecakeSnackLabel(String text) =>
    _hasAny(text, const ['kaesekuchen', 'kaese kuchen', 'cheesecake']) &&
    _hasAny(text, const ['snack', 'riegel', 'dessert']);

String? _breadType(String text) {
  if (_hasBreadCompound(text, 'weissbrot')) return 'weiss';
  if (_hasBreadCompound(text, 'landbrot')) return 'land';
  if (_hasBreadCompound(text, 'vollkornbrot')) return 'vollkorn';
  if (_hasBreadCompound(text, 'roggenbrot')) return 'roggen';
  if (_hasBreadCompound(text, 'mischbrot')) return 'misch';
  return null;
}

String? _meatType(String text) {
  if (_hasAny(text, const ['rindfleisch', 'rind'])) return 'rind';
  if (_hasAny(text, const ['schweinefleisch', 'schwein'])) return 'schwein';
  if (_hasAny(text, const ['kalbfleisch', 'kalb'])) return 'kalb';
  if (_hasAny(text, const ['gefluegel', 'haehnchen'])) return 'gefluegel';
  return null;
}

String? _milkType(String text) =>
    _hasAny(text, const ['laktosefrei', 'laktosefreie']) ? 'laktosefrei' : null;

String? _babyMilkType(String text) {
  if (_hasAny(text, const ['folgemilch', 'folge milch'])) return 'folgemilch';
  if (_hasAny(text, const ['anfangsmilch', 'anfangs milch'])) {
    return 'anfangsmilch';
  }
  if (_hasAny(text, const ['saeuglingsmilch', 'saeuglings milch'])) {
    return 'saeuglingsmilch';
  }
  if (_hasAny(text, const ['kindermilch', 'kinder milch'])) {
    return 'kindermilch';
  }
  return 'babymilch';
}

String? _specialMilkDrinkType(String text) {
  if (_hasAny(text, const ['buttermilch', 'butter milch'])) {
    return 'buttermilch';
  }
  if (_hasAny(text, const ['kokosmilch', 'kokos milch'])) return 'kokos';
  if (_hasAny(text, const ['sojamilch', 'soja milch'])) return 'soja';
  if (_hasAny(text, const ['hafermilch', 'hafer milch'])) return 'hafer';
  if (_hasAny(text, const ['mandelmilch', 'mandel milch'])) return 'mandel';
  return null;
}

String? _creamType(String text) {
  if (_hasAny(text, const ['kochcreme', 'creme zum kochen', 'kochen'])) {
    return 'kochcreme';
  }
  if (_hasAny(text, const ['creme leicht', 'leicht'])) return 'leicht';
  if (_hasAny(text, const ['schlagsahne', 'schlag sahne'])) {
    return 'schlagsahne';
  }
  return null;
}

String? _yoghurtVariant(String text) {
  if (_hasAny(text, const [
    'joghurt mit der ecke',
    'jogh mit der ecke',
    'mit der ecke',
    'ecke',
  ])) {
    return 'ecke';
  }
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
  if (_hasAny(text, const [
    'freilandeier',
    'freiland eier',
    'freiland ei',
    'eier freiland',
  ])) {
    return 'freiland';
  }
  if (_hasAny(text, const [
    'bodenhaltungseier',
    'bodenhaltung eier',
    'eier bodenhaltung',
  ])) {
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

String normalizeIdentityText(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ô', 'o')
      .replaceAll('û', 'u')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll(RegExp(r'[._/*-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // Kaufland's house-brand marker is sometimes printed without a separator,
  // e.g. `KLCToilettenpapier`. Insert a boundary for the known compound
  // markers so the following product token can still be identified. This is
  // normalization only; it does not create an alias or a price identity.
  return normalized.replaceFirstMapped(
    RegExp(r'^(?:klc|kbio)(?=[a-z])'),
    (match) => '${match.group(0)} ',
  );
}

bool _hasWord(String text, String word) {
  final normalized = normalizeIdentityText(word);
  if (normalized.isEmpty) return false;
  return RegExp(r'(?<![a-z0-9])' + RegExp.escape(normalized) + r'(?![a-z0-9])')
      .hasMatch(text);
}

bool _hasAny(String text, List<String> words) =>
    words.any((word) => _hasWord(text, word));

bool _hasJoinedPart(String text, String part) {
  final normalized = normalizeIdentityText(part);
  if (normalized.isEmpty) return false;
  return _hasWord(text, normalized) ||
      RegExp(
        r'(?<![a-z0-9])[a-z]*' +
            RegExp.escape(normalized) +
            r'[a-z]*(?![a-z0-9])',
      ).hasMatch(text);
}

bool _hasJoinedSuffix(String text, String suffix) =>
    _hasJoinedPart(text, suffix);

bool _hasDessertFamilyToken(String text) =>
    _hasAny(text, const ['pudding', 'pud', 'dessert', 'delacreme']) ||
    RegExp(r'(?<![a-z0-9])[a-z]+pudding(?![a-z0-9])').hasMatch(text);

bool _hasCreamFamilyToken(String text) =>
    _hasAny(text, const [
      'creme',
      'cremefine',
      'sahne',
      'rahm',
      'smetana',
      'schlagsahne',
      'schlag sahne',
      'kochcreme',
    ]) ||
    RegExp(r'(?<![a-z0-9])[a-z]+(?:sahne|rahm)(?![a-z0-9])').hasMatch(text);

bool _hasQuarkFamilyToken(String text) => _hasJoinedPart(text, 'quark');

bool _hasWaterFamilyToken(String text) =>
    _hasAny(text, const [
      'wasser',
      'mineralwasser',
      'tafelwasser',
      'quellwasser',
      'stillwasser',
      'wasser medium',
    ]) ||
    RegExp(r'(?<![a-z0-9])[a-z]+wasser(?![a-z0-9])').hasMatch(text);

bool _hasVegetableFamilyToken(String text) =>
    _hasAny(text, const ['gemuese', 'gemüse']) ||
    RegExp(r'(?<![a-z0-9])[a-z]+gemuese(?![a-z0-9])').hasMatch(text);

bool _hasCheeseFamilyToken(String text) =>
    _hasAny(text, const [
      'käse',
      'kaese',
      'gouda',
      'gou',
      'edamer',
      'emmentaler',
      'bergkäse',
      'bergkaese',
      'butterkäse',
      'butterkaese',
      'tilsiter',
      'camembert',
      'hartkaese',
      'hart kaese',
      'schnittkaese',
      'schnitt kaese',
      'weichkaese',
      'weich kaese',
      'schafkaese',
      'schafskaese',
      'schaf kaese',
      'ziegenkaese',
      'ziegen kaese',
      'kaesescheiben',
      'kaese scheiben',
      'frischkaese',
      'frischkaesezubereitung',
      'frischk',
      'schmelzkaese',
      'schmelzk',
      'grillkaese',
      'pfannenkaese',
      'pizzakaese',
      'reibekaese',
      'limburger',
      'obazda',
      'burrata',
      'zottarella',
      'babybel',
      'kiri',
      'queso',
      'mozzarella',
      'parmigiano',
      'grana padano',
      'feta',
    ]) ||
    RegExp(r'(?<![a-z0-9])[a-z]+kaese[a-z]*(?![a-z0-9])').hasMatch(text);

bool _hasMeatFamilyToken(String text) =>
    _hasAny(text, const [
      'fleisch',
      'rindfleisch',
      'schweinefleisch',
      'kalbfleisch',
      'rind',
      'schwein',
      'kalb',
      'gefluegel',
      'haehnchen',
      'roastbeef',
      'nacken',
      'steak',
      'gulasch',
      'tafelspitz',
      'lammkeule',
      'entenbrust',
      'kohlrouladen',
      'kasseler',
      'beef',
      'rinder',
      'schweine',
      'pute',
      'puten',
      'wild',
      'burger',
    ]) ||
    RegExp(r'(?<![a-z0-9])haehnchen[a-z]+(?![a-z0-9])').hasMatch(text) ||
    RegExp(r'(?<![a-z0-9])[a-z]+fleisch[a-z]*(?![a-z0-9])').hasMatch(text) ||
    _hasJoinedPart(text, 'nacken') ||
    _hasJoinedPart(text, 'roastbeef') ||
    _hasJoinedPart(text, 'steak') ||
    _hasJoinedPart(text, 'gulasch') ||
    _hasJoinedPart(text, 'braten') ||
    _hasJoinedPart(text, 'kohlrouladen');

bool _hasSugarFamilyToken(String text) =>
    _hasAny(text, const ['zucker', 'puderzucker', 'haushaltszucker']) ||
    RegExp(r'(?<![a-z0-9])[a-z]+zucker(?![a-z0-9])').hasMatch(text);

bool _hasChocolateFamilyToken(String text) =>
    _hasJoinedPart(text, 'schokolade') ||
    RegExp(r'(?<![a-z0-9])schokolad[a-z]*(?![a-z0-9])').hasMatch(text);

// Current prospect labels join salad families into compounds such as
// "Feldsalat", "Romanasalat" and "Salatherzen". Prepared salads remain
// separate so a generic fresh-salad search cannot reuse their prices.
bool _hasSaladFamilyToken(String text) {
  if (_hasAny(text, const [
    'feinkostsalat',
    'fleischsalat',
    'kartoffelsalat',
    'nudelsalat',
    'eiersalat',
  ])) {
    return false;
  }
  return _hasAny(text, const [
        'salat',
        'eisbergsalat',
        'feldsalat',
        'romanasalat',
        'salatherzen',
      ]) ||
      RegExp(r'(?<![a-z0-9])(?:feld|romana)[a-z]*salat(?![a-z0-9])')
          .hasMatch(text);
}

// Retailer labels join descriptive words to bread families, for example
// "Weizenmischbrot" or "Bauernbaguette". Keep obvious non-bread compounds
// such as Marzipanbrot and Brotzeit out before accepting those whole tokens.
bool _hasBreadFamilyToken(String text) {
  if (_hasAny(text, const ['brotzeit', 'marzipanbrot'])) return false;
  return _hasAny(text, const [
        'brot',
        'weissbrot',
        'kastenweissbrot',
        'landbrot',
        'vollkornbrot',
        'roggenbrot',
        'mischbrot',
      ]) ||
      RegExp(r'(?<![a-z0-9])[a-z]+(?:brot|baguette)(?![a-z0-9])')
          .hasMatch(text);
}

bool _hasBreadCompound(String text, String suffix) =>
    _hasWord(text, suffix) ||
    RegExp(r'(?<![a-z0-9])[a-z]+' + RegExp.escape(suffix) + r'(?![a-z0-9])')
        .hasMatch(text);

// Retailer labels often join a descriptive word to "Milch", for example
// "Alpenmilch". Treat a whole token ending in "milch" as the milk family,
// while keeping ingredient compounds out through _isMilkIngredientCompound.
// This preserves the conservative word-boundary matching for unrelated
// products and avoids adding one alias per retailer label.
bool _hasMilkFamilyToken(String text) =>
    _hasAny(text, const ['milch', 'h milch', 'vollmilch']) ||
    RegExp(r'(?<![a-z0-9])[a-z]+milch(?![a-z0-9])').hasMatch(text);

// Retailer labels also join sausage families into compounds such as
// "Bratwurst", "Zwiebelmettwurst" and "Leberwurst". Recognize those whole
// tokens without turning a substring inside an unrelated word into a family
// match.
bool _hasSausageFamilyToken(String text) =>
    _hasAny(text, const [
      'wurst',
      'salami',
      'lyoner',
      'schinkenwurst',
      'fleischwurst',
      'mortadella',
      'cervelat',
      'wiener',
      'gelbwurst',
      'kabanos',
      'krakauer',
      'beisser',
      'mettwurst',
      'mett',
      'hot dog',
      'hotdog',
      'chorizo',
      'prosciutto',
      'serrano',
      'tyrolini',
      'kochhinterschink',
      'schinken',
    ]) ||
    _hasJoinedPart(text, 'beisser') ||
    RegExp(
      r'(?<![a-z0-9])(?:[a-z]+wurst|[a-z]+schinken|wurst[a-z]+|schinken[a-z]+|[a-z]+(?:salami|lyoner)|salami[a-z]+|lyoner[a-z]+)(?![a-z0-9])',
    ).hasMatch(text);

bool _isMilkIngredientCompound(String text) => _hasAny(text, const [
  'kondensmilch',
  'milchreis',
  'milchschokolade',
  'milch schokolade',
  'milchschokoladen',
  'milch schokoladen',
  'milch schoko',
  'milchriegel',
  'milch riegel',
]);

double? _percent(String text) {
  final match = RegExp(r'(\d+(?:[,.]\d+)?)\s*%').firstMatch(text);
  return match == null
      ? null
      : double.tryParse(match.group(1)!.replaceAll(',', '.'));
}

String? _cheeseVariant(String text) {
  for (final term in const [
    'gouda',
    'gou',
    'edamer',
    'emmentaler',
    'bergkaese',
    'butterkaese',
    'tilsiter',
    'camembert',
    'hartkaese',
    'hart kaese',
    'schnittkaese',
    'schnitt kaese',
    'weichkaese',
    'weich kaese',
    'schafkaese',
    'schafskaese',
    'schaf kaese',
    'ziegenkaese',
    'ziegen kaese',
    'kaesescheiben',
    'kaese scheiben',
    'frischkaese',
    'frischk',
    'schmelzkaese',
    'schmelzk',
    'grillkaese',
    'pfannenkaese',
    'pizzakaese',
    'reibekaese',
    'limburger',
    'obazda',
    'burrata',
    'zottarella',
    'babybel',
    'kiri',
    'queso',
    'mozzarella',
    'parmigiano',
    'grana padano',
    'feta',
  ]) {
    if (_hasWord(text, term)) {
      return switch (term) {
        'gou' => 'gouda',
        'hart kaese' => 'hartkaese',
        'schnitt kaese' => 'schnittkaese',
        'weich kaese' => 'weichkaese',
        'schaf kaese' => 'schafkaese',
        'schafskaese' => 'schafkaese',
        'ziegen kaese' => 'ziegenkaese',
        'kaese scheiben' => 'kaesescheiben',
        'frischk' => 'frischkaese',
        'schmelzk' => 'schmelzkaese',
        _ => term,
      };
    }
  }
  return null;
}

String? _sausageVariant(String text) {
  if (_hasAny(text, const ['kochschinken', 'kochhinterschink'])) {
    return 'schinken';
  }
  for (final term in const [
    'salami',
    'lyoner',
    'schinkenwurst',
    'fleischwurst',
    'bockwurst',
    'teewurst',
    'fruehstuecksfleisch',
    'mortadella',
    'cervelat',
    'wiener',
    'gelbwurst',
    'kochhinterschink',
    'schinken',
  ]) {
    if (_hasWord(text, term) ||
        (term == 'salami' &&
            RegExp(r'(?<![a-z0-9])[a-z]+salami(?![a-z0-9])').hasMatch(text)) ||
        (term == 'lyoner' &&
            RegExp(r'(?<![a-z0-9])[a-z]+lyoner(?![a-z0-9])').hasMatch(text))) {
      return term;
    }
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

String? _donutVariant(String text) {
  if (_hasAny(text, const ['schinken', 'schink', 'schin'])) return 'schinken';
  return null;
}

String? _color(String text) {
  if (_hasAny(text, const ['rot', 'rote', 'roter', 'rotes'])) return 'rot';
  if (_hasAny(text, const ['gelb', 'gelbe', 'gelber'])) return 'gelb';
  if (_hasAny(text, const ['gruen', 'grüne', 'gruen'])) return 'gruen';
  return null;
}
