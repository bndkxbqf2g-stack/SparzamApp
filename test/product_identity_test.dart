import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_identity.dart';

void main() {
  test('generic milk competes across compatible fat variants', () {
    expect(compatibleProductIdentity(identifyProduct('Milch'), identifyProduct('GL H-Milch 1,5% 1L')), isTrue);
    expect(compatibleProductIdentity(identifyProduct('Milch'), identifyProduct('GL H-Milch 3,5% 1 L')), isTrue);
  });

  test('specific milk fat does not match another fat', () {
    expect(compatibleProductIdentity(identifyProduct('Milch 1,5%'), identifyProduct('H-Milch 3,5%')), isFalse);
    expect(compatibleProductIdentity(identifyProduct('Milch 1,5%'), identifyProduct('Marke XY H-Vollmilch 1,5% 1L')), isTrue);
  });

  test('paprika family excludes paprika-flavoured chips', () {
    expect(identifyProduct('Paprika Mix 500g').familyKey, 'paprika');
    expect(identifyProduct('Pringles Paprika').familyKey, 'chips');
    expect(compatibleProductIdentity(identifyProduct('Paprika'), identifyProduct('Pringles Paprika')), isFalse);
  });

  test('paprika variants and generic request follow specificity', () {
    expect(compatibleProductIdentity(identifyProduct('rote Paprika'), identifyProduct('rote Spitzpaprika')), isTrue);
    expect(compatibleProductIdentity(identifyProduct('rote Paprika'), identifyProduct('gelbe Paprika')), isFalse);
    expect(compatibleProductIdentity(identifyProduct('Paprika'), identifyProduct('Paprika Mix 500g')), isTrue);
  });

  test('hackfleisch and yoghurt retain variant constraints', () {
    expect(compatibleProductIdentity(identifyProduct('Hackfleisch'), identifyProduct('Rinderhackfleisch')), isTrue);
    expect(compatibleProductIdentity(identifyProduct('Rinderhackfleisch'), identifyProduct('gemischtes Hackfleisch')), isFalse);
    expect(compatibleProductIdentity(identifyProduct('Joghurt'), identifyProduct('normaler Naturjoghurt')), isTrue);
    expect(compatibleProductIdentity(identifyProduct('Naturjoghurt'), identifyProduct('Naturjoghurt')), isTrue);
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

  test('compound product names do not use a bare substring as identity', () {
    expect(identifyProduct('Milchreis').familyKey, isNull);
    expect(identifyProduct('Wa.Stein.Pizza Mozz. 350g').familyKey, 'pizza');
    expect(compatibleProductIdentity(identifyProduct('Mozzarella'), identifyProduct('Wa.Stein.Pizza Mozz. 350g')), isFalse);
  });
}


test('fresh tomato request is not compatible with preserved tomato products', () {
  final fresh=identifyProduct('Tomaten');
  final passata=identifyProduct('Passata');
  expect(compatibleProductIdentity(fresh, passata), isFalse);
});


test('preserved tomato request still accepts preserved tomato evidence', () {
  expect(compatibleProductIdentity(identifyProduct('Passata'), identifyProduct('Gehackte Tomaten')), isTrue);
});
