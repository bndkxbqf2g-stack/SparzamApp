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

  test(
    'fresh tomato request is not compatible with preserved tomato products',
    () {
      final fresh = identifyProduct('Tomaten');
      final passata = identifyProduct('Passata');
      expect(compatibleProductIdentity(fresh, passata), isFalse);
    },
  );

  test('preserved tomato request still accepts preserved tomato evidence', () {
    expect(
      compatibleProductIdentity(
        identifyProduct('Passata'),
        identifyProduct('Gehackte Tomaten'),
      ),
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
    expect(identifyProduct('Passierte Tomaten').familyKey, 'tomatenkonserve');
    expect(identifyProduct('Gehackte Tomaten').familyKey, 'tomatenkonserve');
    expect(
      compatibleProductIdentity(
        identifyProduct('Tomate'),
        identifyProduct('Passierte Tomaten'),
      ),
      isFalse,
    );
  });
}
