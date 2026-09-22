import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/stores.dart';
import 'package:sparzamapp/features/store/store_shopping_summary.dart';
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
  const noodles = Product(
    id: 'nudeln',
    name: 'Spaghetti',
    unit: '500 g',
    group: 'nudeln',
  );

  final lidl = stores.firstWhere((store) => store.name == 'Lidl');

  test('Marktübersicht berechnet normale und Angebotsartikel', () {
    final summary = buildStoreShoppingSummary(
      lidl,
      [
        ListItem(product: milk),
        ListItem(product: noodles, quantity: 2),
      ],
      [
        Offer(
          id: 'milk_offer',
          productId: 'milch_35',
          storeName: 'Lidl',
          originalPrice: 1.29,
          offerPrice: 0.99,
          validUntil: DateTime(2026, 9, 25),
        ),
      ],
      now: DateTime(2026, 9, 22),
    );

    expect(summary.lines.length, 2);
    expect(summary.lines.first.item.product.id, 'milch_35');
    expect(summary.lines.first.usesOffer, isTrue);
    expect(summary.savings, closeTo(0.30, 0.001));
    expect(summary.total, closeTo(2.77, 0.001));
  });

  test('Artikel ohne Marktpreis werden nicht angezeigt', () {
    const unknown = Product(
      id: 'custom_unknown',
      name: 'Unbekannt',
      unit: 'Artikel',
      group: 'custom',
    );

    final summary = buildStoreShoppingSummary(
      lidl,
      [ListItem(product: unknown)],
      const <Offer>[],
      now: DateTime(2026, 9, 22),
    );

    expect(summary.lines, isEmpty);
    expect(summary.total, 0);
  });

  test('abgelaufene Angebote werden als Normalpreis behandelt', () {
    final summary = buildStoreShoppingSummary(
      lidl,
      [ListItem(product: milk)],
      [
        Offer(
          id: 'old',
          productId: 'milch_35',
          storeName: 'Lidl',
          originalPrice: 1.29,
          offerPrice: 0.79,
          validUntil: DateTime(2026, 9, 20),
        ),
      ],
      now: DateTime(2026, 9, 22),
    );

    expect(summary.lines.single.usesOffer, isFalse);
    expect(summary.total, 1.29);
    expect(summary.savings, 0);
  });
}
