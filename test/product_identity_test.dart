import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_identity.dart';

void main() {
  test('generic milk competes across compatible fat variants', () {
    expect(
      compatibleProductIdentity(
        identifyProduct('Milch'),
        identifyProduct('GL H-Milch 1,5% 1L'),
      ),
      isTrue,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Milch'),
        identifyProduct('GL H-Milch 3,5% 1 L'),
      ),
      isTrue,
    );
  });

  test('specific milk fat does not match another fat', () {
    expect(
      compatibleProductIdentity(
        identifyProduct('Milch 1,5%'),
        identifyProduct('H-Milch 3,5%'),
      ),
      isFalse,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Milch 1,5%'),
        identifyProduct('Marke XY H-Vollmilch 1,5% 1L'),
      ),
      isTrue,
    );
  });

  test('paprika family excludes paprika-flavoured chips', () {
    expect(identifyProduct('Paprika Mix 500g').familyKey, 'paprika');
    expect(identifyProduct('Pringles Paprika').familyKey, 'chips');
    expect(
      compatibleProductIdentity(
        identifyProduct('Paprika'),
        identifyProduct('Pringles Paprika'),
      ),
      isFalse,
    );
  });

  test('paprika variants and generic request follow specificity', () {
    expect(
      compatibleProductIdentity(
        identifyProduct('rote Paprika'),
        identifyProduct('rote Spitzpaprika'),
      ),
      isTrue,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('rote Paprika'),
        identifyProduct('gelbe Paprika'),
      ),
      isFalse,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Paprika'),
        identifyProduct('Paprika Mix 500g'),
      ),
      isTrue,
    );
  });

  test('hackfleisch and yoghurt retain variant constraints', () {
    expect(
      compatibleProductIdentity(
        identifyProduct('Hackfleisch'),
        identifyProduct('Rinderhackfleisch'),
      ),
      isTrue,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Rinderhackfleisch'),
        identifyProduct('gemischtes Hackfleisch'),
      ),
      isFalse,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Joghurt'),
        identifyProduct('normaler Naturjoghurt'),
      ),
      isTrue,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Naturjoghurt'),
        identifyProduct('Naturjoghurt'),
      ),
      isTrue,
    );
  });

  test('new retailer wording resolves without a stored alias', () {
    final identity = identifyProduct('Marke XY H-Vollmilch 3,5% 1L');
    expect(identity.familyKey, 'milch');
    expect(identity.fatPercent, 3.5);
  });

  test('general food families resolve common receipt forms', () {
    expect(identifyProduct('K-Schmand 24% 200g').familyKey, 'schmand');
    expect(identifyProduct('Bananen Lose MT').familyKey, 'bananen');
    expect(identifyProduct('Apfel rot 1kg').familyKey, 'aepfel');
  });

  test('compound groceries do not inherit the ingredient price identity', () {
    expect(identifyProduct('Eier-Spätzle').familyKey, 'nudeln');
    expect(identifyProduct('Eier-Spätzle').productType, 'spaetzle');
    expect(identifyProduct('Schinken-Käse-Croissant').familyKey, 'backware');
    expect(identifyProduct('Weizenbrötchen').familyKey, 'broetchen');
    expect(identifyProduct('Linguine').familyKey, 'nudeln');
    expect(identifyProduct('Kritharaki').familyKey, 'nudeln');
  });

  test('abbreviated beef mince does not match mixed mince', () {
    final beef = identifyProduct('XXL R.-Hackfleisch');
    expect(beef.meatType, 'rind');
    expect(
      compatibleProductIdentity(beef, identifyProduct('Hackfleisch gemischt')),
      isFalse,
    );
  });

  test('compound product names do not use a bare substring as identity', () {
    expect(identifyProduct('Milchreis').familyKey, isNull);
    expect(identifyProduct('Wa.Stein.Pizza Mozz. 350g').familyKey, 'pizza');
    expect(
      compatibleProductIdentity(
        identifyProduct('Mozzarella'),
        identifyProduct('Wa.Stein.Pizza Mozz. 350g'),
      ),
      isFalse,
    );
  });

  test('milchschnitte stays separate from ordinary milk', () {
    final snack = identifyProduct('MILCH-SCHNITTE Snack je 10 St.');

    expect(snack.familyKey, 'snack');
    expect(snack.productType, 'milchschnitte');
    expect(
      compatibleProductIdentity(identifyProduct('Milch'), snack),
      isFalse,
    );
  });

  test(
    'coffee compounds keep appliances and pastries out of coffee search',
    () {
      expect(
        identifyProduct('BRANDT Kaffee-Gebäck 201 g').familyKey,
        'backware',
      );
      expect(
        identifyProduct('NESCAFÉ Latte Kaffeegetränk 205 ml').familyKey,
        'kaffeegetraenk',
      );
      expect(
        identifyProduct('KRUPS Nescafé Dolce Gusto Piccolo XS').familyKey,
        'kaffeemaschine',
      );
      expect(
        identifyProduct('JACOBS Kaffeekapseln 20 Stück').familyKey,
        'kaffee',
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Kaffee'),
          identifyProduct('BRANDT Kaffee-Gebäck 201 g'),
        ),
        isFalse,
      );
    },
  );

  test('cheese compounds keep sausages out of cheese search', () {
    final cheese = identifyProduct('Käse');
    expect(identifyProduct('Mühlenhof Käse-Wiener 600 g').familyKey, 'wurst');
    expect(identifyProduct('K-CLASSIC Bayr. Leberkäse').familyKey, 'wurst');
    expect(
      compatibleProductIdentity(
        cheese,
        identifyProduct('Mühlenhof Käse-Wiener 600 g'),
      ),
      isFalse,
    );
    expect(identifyProduct('OLD AMSTERDAM Holl. Hartkäse').familyKey, 'kaese');
  });

  test('bread, pasta and salt ingredients keep snack products separate', () {
    expect(
      identifyProduct('BÄCKERKRÖNUNG Donut Franzbrötchen-Style').familyKey,
      'backware',
    );
    expect(identifyProduct('BARILLA Pasta-Sauce').familyKey, 'sauce');
    expect(
      identifyProduct('K-CLASSIC Käse- oder Salz-Stängli').familyKey,
      'snack',
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Brötchen'),
        identifyProduct('BÄCKERKRÖNUNG Donut Franzbrötchen-Style'),
      ),
      isFalse,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Nudeln'),
        identifyProduct('BARILLA Pasta-Sauce'),
      ),
      isFalse,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Salz'),
        identifyProduct('K-CLASSIC Käse- oder Salz-Stängli'),
      ),
      isFalse,
    );
  });

  test('pizza donuts and knabbermaeuse stay separate from nearby families', () {
    final pizzaDonut = identifyProduct('Pizza-Donut Schin.');
    expect(pizzaDonut.familyKey, 'backware');
    expect(pizzaDonut.productType, 'donut');
    expect(pizzaDonut.variant, 'schinken');
    expect(
      compatibleProductIdentity(pizzaDonut, identifyProduct('Pizza')),
      isFalse,
    );

    final mice = identifyProduct('KLC.Kn.Mäuse Salz');
    expect(mice.familyKey, 'snack');
    expect(mice.productType, 'knabbermaeuse');
    expect(
      compatibleProductIdentity(mice, identifyProduct('Kartoffelchips')),
      isFalse,
    );
  });

  test(
    'beverage, bread and household compounds keep staple searches precise',
    () {
      expect(identifyProduct('RAMA Brotaufstrich').familyKey, 'aufstrich');
      expect(identifyProduct('Kastenweißbrot').familyKey, 'brot');
      expect(identifyProduct('Kastenweißbrot').productType, 'weiss');
      expect(identifyProduct('BRAUN Wasserkocher').familyKey, 'wassergeraet');
      expect(identifyProduct('ADELHOLZENER Mineralwasser').familyKey, 'wasser');
      expect(identifyProduct('MEICA Saft-Bockwurst').familyKey, 'wurst');
      expect(identifyProduct('K-CLASSIC Apfelsaft').familyKey, 'saft');
      expect(identifyProduct('REINERT Teewurst').familyKey, 'wurst');
      expect(identifyProduct('MAYFAIR Kamillentee').familyKey, 'tee');
      expect(identifyProduct('Freeway Eistee').productType, 'eistee');
      expect(
        identifyProduct('K-CARINURA Hundenahrung Premium-Fleischgenuss')
            .familyKey,
        'tiernahrung',
      );
      expect(identifyProduct('IRONMAXX Sahne-Protein').familyKey, 'protein');
      expect(identifyProduct('NIVEA Creme').familyKey, 'kosmetik');
      expect(
        identifyProduct('NUTELLA Nuss-Nugat-Creme').familyKey,
        'suessigkeit',
      );
      expect(
        identifyProduct('NESTLÉ Choco Crossies Original oder Choclait Chips')
            .familyKey,
        'schokolade',
      );

      expect(
        compatibleProductIdentity(
          identifyProduct('Brot'),
          identifyProduct('RAMA Brotaufstrich'),
        ),
        isFalse,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Brot'),
          identifyProduct('Sandwichtoast'),
        ),
        isTrue,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Wasser'),
          identifyProduct('BRAUN Wasserkocher'),
        ),
        isFalse,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Saft'),
          identifyProduct('MEICA Saft-Bockwurst'),
        ),
        isFalse,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Tee'),
          identifyProduct('REINERT Teewurst'),
        ),
        isFalse,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Tee'),
          identifyProduct('Freeway Eistee'),
        ),
        isFalse,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Eistee'),
          identifyProduct('Freeway Eistee'),
        ),
        isTrue,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Fleisch'),
          identifyProduct('Hackfleisch gemischt'),
        ),
        isTrue,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Fleisch'),
          identifyProduct('K-CARINURA Hundenahrung Premium-Fleischgenuss'),
        ),
        isFalse,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Sahne'),
          identifyProduct('IRONMAXX Sahne-Protein'),
        ),
        isFalse,
      );
      expect(
        compatibleProductIdentity(
          identifyProduct('Chips'),
          identifyProduct('NESTLÉ Choco Crossies Original oder Choclait Chips'),
        ),
        isFalse,
      );
    },
  );

  test('milk ingredient compounds stay out of the plain milk family', () {
    expect(identifyProduct('K-CLASSIC Kondensmilch XXL').familyKey, isNull);
    expect(identifyProduct('K-CLASSIC Milch-Riegel').familyKey, 'snack');
    expect(
      identifyProduct('LINDENHOF Faire Milch Gouda jung').familyKey,
      'kaese',
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Milch'),
        identifyProduct('LINDENHOF Faire Milch Gouda jung'),
      ),
      isFalse,
    );
  });

  test('prospect punctuation does not hide a concrete milk identity', () {
    final identity = identifyProduct(
      'PENNY ZUKUNFTSBAUER Frische Vollmilch* je 1 l',
    );
    expect(identity.familyKey, 'milch');
    expect(
      compatibleProductIdentity(identifyProduct('Milch'), identity),
      isTrue,
    );
  });

  test('compound milk labels from prospect feeds remain searchable as milk', () {
    final identity = identifyProduct(
      'BERCHTESGADENER LAND Haltbare Berg- & Alpenmilch je 1-l-Packg.',
    );

    expect(identity.familyKey, 'milch');
    expect(
      compatibleProductIdentity(identifyProduct('Milch'), identity),
      isTrue,
    );
  });

  test('compound sausage labels from prospect feeds remain searchable as sausage', () {
    final identity = identifyProduct(
      'NOTHWANG Grobe Bratwurst je 100 g',
    );

    expect(identity.familyKey, 'wurst');
    expect(
      compatibleProductIdentity(identifyProduct('Wurst'), identity),
      isTrue,
    );
  });

  test(
    'fresh tomato request is not compatible with preserved tomato products',
    () {
      final fresh = identifyProduct('Tomaten');
      final passata = identifyProduct('Passata');
      expect(compatibleProductIdentity(fresh, passata), isFalse);
    },
  );

  test('preserved tomato request still accepts preserved tomato evidence', () {
    final preserved = identifyProduct('Tomatenkonserve');
    expect(preserved.familyKey, 'tomatenkonserve');
    expect(preserved.productType, isNull);
    expect(
      compatibleProductIdentity(preserved, identifyProduct('Gehackte Tomaten')),
      isTrue,
    );
  });

  test('explicit mince variant is not a generic family request', () {
    expect(identifyProduct('Hackfleisch').isGeneric, isTrue);
    expect(identifyProduct('Hackfleisch gemischt').isGeneric, isFalse);
    expect(identifyProduct('Rinderhackfleisch').isGeneric, isFalse);
  });

  test('common staples resolve to their grocery families', () {
    expect(identifyProduct('Freilandeier 10 Stück').familyKey, 'eier');
    expect(identifyProduct('Naturjoghurt 500 g').familyKey, 'joghurt');
    expect(identifyProduct('Aufbackbrötchen 6 Stück').familyKey, 'broetchen');
    expect(identifyProduct('Erdbeer-Konfitüre').familyKey, 'marmelade');
    expect(identifyProduct('Penne Rigate 500 g').familyKey, 'nudeln');
    expect(identifyProduct('Nescafé Classic 200 g').familyKey, 'kaffee');
  });

  test('generic staples include variants but specific forms stay distinct', () {
    expect(
      compatibleProductIdentity(
        identifyProduct('Brötchen'),
        identifyProduct('Aufbackbrötchen 6 Stück'),
      ),
      isTrue,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Aufbackbrötchen'),
        identifyProduct('Brötchen'),
      ),
      isFalse,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Nudeln'),
        identifyProduct('Penne'),
      ),
      isTrue,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Penne'),
        identifyProduct('Spaghetti'),
      ),
      isFalse,
    );
  });

  test('everyday pantry families keep concrete variants separate', () {
    expect(identifyProduct('Basmati Reis').productType, 'basmati');
    expect(identifyProduct('Parboiled Reis').productType, 'parboiled');
    expect(
      compatibleProductIdentity(
        identifyProduct('Reis'),
        identifyProduct('Basmati Reis'),
      ),
      isTrue,
    );
    expect(
      compatibleProductIdentity(
        identifyProduct('Basmati Reis'),
        identifyProduct('Parboiled Reis'),
      ),
      isFalse,
    );

    expect(identifyProduct('Weizenmehl Type 405').familyKey, 'mehl');
    expect(identifyProduct('Weizenmehl Type 405').productType, 'type405');
    expect(identifyProduct('Rapsöl').productType, 'raps');
    expect(identifyProduct('Puderzucker').productType, 'puder');
    expect(identifyProduct('Speisesalz').familyKey, 'salz');
  });

  test('common dairy and egg variants remain identifiable', () {
    expect(identifyProduct('Laktosefreie Milch').productType, 'laktosefrei');
    expect(identifyProduct('Griechischer Joghurt').variant, 'griechisch');
    expect(identifyProduct('Fruchtjoghurt').variant, 'frucht');
    expect(identifyProduct('Bio-Eier').variant, 'bio');
    expect(identifyProduct('Freilandeier').variant, 'freiland');
    expect(
      compatibleProductIdentity(
        identifyProduct('Bio-Eier'),
        identifyProduct('Freilandeier'),
      ),
      isFalse,
    );
  });

  test('preserved tomato products stay outside the fresh tomato family', () {
    final passata = identifyProduct('Passierte Tomaten');
    final chopped = identifyProduct('Gehackte Tomaten');
    expect(passata.familyKey, 'tomatenkonserve');
    expect(passata.productType, 'passata');
    expect(chopped.familyKey, 'tomatenkonserve');
    expect(chopped.productType, 'gehackt');
    expect(
      compatibleProductIdentity(identifyProduct('Tomate'), passata),
      isFalse,
    );
    expect(compatibleProductIdentity(passata, chopped), isFalse);
  });

  test('compound bread labels resolve to bread without snack false positives', () {
    final wheatBread = identifyProduct('Weizenmischbrot je 1-kg-Stück');
    expect(wheatBread.familyKey, 'brot');
    expect(wheatBread.productType, 'misch');
    expect(identifyProduct('Bauernbaguette Je 300 g').familyKey, 'brot');
    expect(
      identifyProduct('K-WINTER EDITION Marzipanbrot').familyKey,
      isNot('brot'),
    );
    expect(identifyProduct('Bayerische Brotzeit').familyKey, isNot('brot'));
  });

  test('compound fresh-salad labels stay separate from prepared salads', () {
    expect(identifyProduct('Feldsalat* je 150-g-Schale').familyKey, 'salat');
    expect(
      identifyProduct('Deutsche Romana Salatherzen* je 2-Stück-Packung')
          .familyKey,
      'salat',
    );
    expect(identifyProduct('Dtsch. Mini-Romanasalat').familyKey, 'salat');
    expect(identifyProduct('FRANK ROSIN Feinkostsalat').familyKey, isNot('salat'));
    expect(identifyProduct('Salatgurke').familyKey, isNot('salat'));
  });

  test('compound yoghurt labels stay separate from yoghurt ingredients', () {
    expect(identifyProduct('Ehrmann Almighurt Je 150 g').familyKey, 'joghurt');
    expect(identifyProduct('EHRMANN Obstgarten* je 125 g').familyKey, 'joghurt');
    expect(
      identifyProduct('BERCHTESGADENER LAND Frucht & Knusper').familyKey,
      'joghurt',
    );
    expect(
      identifyProduct('K-CLASSIC Frischkäsezubereitung light oder mit Joghurt')
          .familyKey,
      'kaese',
    );
    expect(
      identifyProduct('DR. OETKER Löffelglück Fruchtgrütze').familyKey,
      isNot('joghurt'),
    );
  });

  test('compound butter labels stay separate from ordinary butter', () {
    expect(
      identifyProduct('AMMERLÄNDER Butterkäse').familyKey,
      'kaese',
    );
    expect(
      identifyProduct('AMMERLÄNDER Butterkäse').variant,
      'butterkaese',
    );
    expect(
      identifyProduct('K-BIO Bio-Buttergemüse').familyKey,
      'gemuese',
    );
    expect(
      identifyProduct('K-BIO Bio-Buttergemüse').productType,
      'buttergemuese',
    );
    expect(
      identifyProduct('Landliebe Butter oder Die Streichzarte').familyKey,
      'butter',
    );
  });
}
