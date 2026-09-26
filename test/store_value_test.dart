import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/stores.dart';
import 'package:sparzamapp/features/store/store_value.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const milk = Product(
    id: 'milch_35',
    name: 'Vollmilch',
    unit: '1 l',
    group: 'milch',
  );

  final lidl = stores.firstWhere((store) => store.name == 'Lidl');

  test('Fahrtkosten werden von der Warenkorbersparnis abgezogen', () {
    final value = evaluateStoreValue(
      lidl,
      [ListItem(product: milk)],
      [
        Offer(
          id: 'milk_offer',
          productId: 'milch_35',
          storeName: 'Lidl',
          originalPrice: 1.29,
          offerPrice: 0.49,
          validUntil: DateTime(2026, 9, 25),
        ),
      ],
      now: DateTime(2026, 9, 22),
    );

    expect(value.basketSavings, closeTo(0.80, 0.001));
    expect(value.travelCost, closeTo(0.528, 0.001));
    expect(value.netAdvantage, closeTo(0.272, 0.001));
    expect(value.isWorthIt, isTrue);
    expect(value.totalWithTravel, closeTo(1.018, 0.001));
  });

  test('Markt lohnt sich nicht wenn Fahrt teurer als Ersparnis ist', () {
    final value = evaluateStoreValue(
      lidl,
      [ListItem(product: milk)],
      [
        Offer(
          id: 'milk_offer',
          productId: 'milch_35',
          storeName: 'Lidl',
          originalPrice: 1.29,
          offerPrice: 1.19,
          validUntil: DateTime(2026, 9, 25),
        ),
      ],
      now: DateTime(2026, 9, 22),
    );

    expect(value.basketSavings, closeTo(0.10, 0.001));
    expect(value.travelCost, closeTo(0.528, 0.001));
    expect(value.netAdvantage, lessThan(0));
    expect(value.isWorthIt, isFalse);
  });
  test('alle konfigurierten Märkte haben eine belegte Markt-ID', () {
    expect(stores, hasLength(7));
    final branchIds = stores.map((store) => store.branchId).toList();
    expect(branchIds, everyElement(isNotNull));
    expect(branchIds.toSet(), hasLength(7));
  });

}
