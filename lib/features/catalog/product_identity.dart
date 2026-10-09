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
  if (_hasAny(text, const ['chips', 'pringles', 'lays', 'kartoffelchips'])) {
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
  if (_hasAny(text, const ['pudding', 'pud', 'dessert', 'delacreme'])) {
    return const ProductIdentity(familyKey: 'dessert');
  }
  if (_hasAny(text, const ['ice cream', 'eis', 'pirulo', 'bounty ice'])) {
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
  if (_hasAny(text, const [
    'creme',
    'sahne',
    'schlagsahne',
    'schlag sahne',
    'kochcreme',
  ])) {
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
  if (_hasAny(text, const [
    'wasser',
    'mineralwasser',
    'tafelwasser',
    'quellwasser',
    'stillwasser',
    'wasser medium',
  ])) {
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
    return const ProductIdentity(
      familyKey: 'kaese',
      variant: 'butterkaese',
    );
  }
  if (_hasAny(text, const ['buttergemuese', 'butter gemuese'])) {
    return const ProductIdentity(
      familyKey: 'gemuese',
      productType: 'buttergemuese',
    );
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
  ])) {
    return ProductIdentity(
      familyKey: 'wurst',
      variant: _hasAny(text, const ['leberkaese', 'leber kaese'])
          ? 'leberkaese'
          : _hasAny(text, const ['kaese salami', 'kaesesalami'])
          ? 'salami'
          : 'wiener',
    );
  }
  if (_hasAny(text, const [
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
  ])) {
    return ProductIdentity(familyKey: 'kaese', variant: _cheeseVariant(text));
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
  if (_hasAny(text, const [
    'fleisch',
    'rindfleisch',
    'schweinefleisch',
    'kalbfleisch',
    'rind',
    'schwein',
    'kalb',
    'gefluegel',
    'haehnchen',
  ])) {
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
  if (_hasAny(text, const ['schokolade'])) {
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
  return const ProductIdentity(familyKey: null);
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
      RegExp(r'\b[a-z]{3,}ghurt\b').hasMatch(text) ||
      _hasAny(text, const [
        'obstgarten',
        'frucht knusper',
        'frucht & knusper',
      ]);
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
      candidate.productType == 'eistee') {
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
  if (_hasAny(text, const ['kamillentee', 'kamillen tee'])) return 'kamille';
  if (_hasAny(text, const ['pfefferminztee', 'pfefferminz tee'])) {
    return 'pfefferminze';
  }
  if (_hasAny(text, const ['schwarztee'])) return 'schwarz';
  if (_hasAny(text, const ['kraeutertee', 'kraeuter tee'])) return 'kraeuter';
  if (_hasAny(text, const ['gruenentee', 'gruen tee'])) return 'gruen';
  return null;
}

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
  if (_hasAny(text, const ['kindermilch', 'kinder milch'])) return 'kindermilch';
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
      'kochhinterschink',
      'schinken',
    ]) ||
    RegExp(
      r'(?<![a-z0-9])(?:[a-z]+wurst|[a-z]+schinken|wurst[a-z]+|schinken[a-z]+)(?![a-z0-9])',
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
    'schaf kaese',
    'ziegenkaese',
    'ziegen kaese',
    'kaesescheiben',
    'kaese scheiben',
    'frischkaese',
    'frischk',
    'schmelzkaese',
    'schmelzk',
  ]) {
    if (_hasWord(text, term)) {
      return switch (term) {
        'gou' => 'gouda',
        'hart kaese' => 'hartkaese',
        'schnitt kaese' => 'schnittkaese',
        'weich kaese' => 'weichkaese',
        'schaf kaese' => 'schafkaese',
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
