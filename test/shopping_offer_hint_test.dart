import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_offer_hint.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const milk = Product(
    id: 'milch_35',
    name: 'Vollmilch 3,5 %',
    unit: '1 l',
    group: 'milch',
  );

  test('bestes aktives Angebot wird für Listenartikel gefunden', () {
    final item = ListItem(product: milk);
    final offers = [
      Offer(
        id: 'lidl_milk',
        productId: 'milch_35',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.99,
        validUntil: DateTime(2026, 9, 25),
      ),
      Offer(
        id: 'edeka_milk',
        productId: 'milch_35',
        storeName: 'EDEKA',
        originalPrice: 1.39,
        offerPrice: 1.09,
        validUntil: DateTime(2026, 9, 25),
      ),
    ];

    final hint = bestShoppingOffer(
      item,
      offers,
      now: DateTime(2026, 9, 22),
    );

    expect(hint, isNotNull);
    expect(hint!.storeName, 'Lidl');
    expect(hint.unitPrice, 0.99);
    expect(hint.savings, greaterThan(0));
  });

  test('abgelaufenes Angebot erzeugt keinen Hinweis', () {
    final item = ListItem(product: milk);
    final offers = [
      Offer(
        id: 'old',
        productId: 'milch_35',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.79,
        validUntil: DateTime(2026, 9, 20),
      ),
    ];

    final hint = bestShoppingOffer(
      item,
      offers,
      now: DateTime(2026, 9, 22),
    );

    expect(hint, isNull);
  });

  test('Coupon wirkt auch im Einkaufsliste-Hinweis', () {
    final item = ListItem(product: milk);
    final offers = [
      Offer(
        id: 'coupon',
        productId: 'milch_35',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.99,
        couponPercent: 10,
        validUntil: DateTime(2026, 9, 25),
      ),
    ];

    final hint = bestShoppingOffer(
      item,
      offers,
      now: DateTime(2026, 9, 22),
    );

    expect(hint, isNotNull);
    expect(hint!.unitPrice, 0.89);
  });
}
