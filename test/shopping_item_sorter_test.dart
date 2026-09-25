import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_item_sorter.dart';
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
  const butter = Product(
    id: 'butter_block',
    name: 'Butter',
    unit: '250 g',
    group: 'butter',
  );
  const noodles = Product(
    id: 'nudeln',
    name: 'Spaghetti',
    unit: '500 g',
    group: 'nudeln',
  );

  test('Artikel mit gutem Angebot werden nach oben priorisiert', () {
    final items = [
      ListItem(product: noodles),
      ListItem(product: milk),
    ];
    final offers = [
      Offer(
        id: 'milk_offer',
        productId: 'milch_35',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.99,
        validUntil: DateTime(2026, 9, 25),
      ),
    ];

    final result = prioritizeOfferItems(
      items,
      offers,
      now: DateTime(2026, 9, 22),
    );

    expect(result.map((item) => item.product.id), ['milch_35', 'nudeln']);
  });

  test('bei mehreren Angeboten steht höhere Ersparnis zuerst', () {
    final items = [
      ListItem(product: milk),
      ListItem(product: butter),
    ];
    final offers = [
      Offer(
        id: 'milk_offer',
        productId: 'milch_35',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 1.09,
        validUntil: DateTime(2026, 9, 25),
      ),
      Offer(
        id: 'butter_offer',
        productId: 'butter_block',
        storeName: 'Lidl',
        originalPrice: 1.79,
        offerPrice: 0.99,
        validUntil: DateTime(2026, 9, 25),
      ),
    ];

    final result = prioritizeOfferItems(
      items,
      offers,
      now: DateTime(2026, 9, 22),
    );

    expect(result.first.product.id, 'butter_block');
  });

  test('ohne Angebot bleibt ursprüngliche Reihenfolge erhalten', () {
    final items = [
      ListItem(product: noodles),
      ListItem(product: milk),
    ];

    final result = prioritizeOfferItems(
      items,
      const <Offer>[],
      now: DateTime(2026, 9, 22),
    );

    expect(result.map((item) => item.product.id), ['nudeln', 'milch_35']);
  });
}
