import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/offers.dart';
import 'package:sparzamapp/features/shopping_list/shopping_price_quotes.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const milk = Product(
    id: 'milch_35',
    name: 'Vollmilch 3,5 %',
    unit: '1 l',
    group: 'milch',
  );
  final item = ListItem(product: milk);
  final receipt = MarketPrice(
    productId: 'milch_35',
    storeName: 'Beispielmarkt',
    price: 1.05,
    updatedAt: DateTime(2026, 7, 14),
    source: MarketPriceSource.receipt,
  );
  final offer = Offer(
    id: 'verified_offer',
    productId: 'milch_35',
    storeName: 'Lidl',
    originalPrice: 1.29,
    offerPrice: 0.89,
    couponPercent: 10,
    validUntil: DateTime(2026, 9, 30),
  );

  test('older receipts remain dated observations alongside current offers', () {
    final quotes = shoppingQuotes(item,
        prices: [receipt],
        offers: [offer],
        now: DateTime(2026, 9, 24));
    expect(quotes, hasLength(2));
    expect(quotes.first.kind, ShoppingQuoteKind.offer);
    expect(quotes.first.unitPrice, 0.89);
    expect(quotes.last.sourceLabel, 'Bonpreis vom 14.07.2026');
    expect(quotes.last.unitPrice, 1.05);
  });

  test('demo offers, Open Prices and unlike products are not used', () {
    final quotes = shoppingQuotes(item,
        prices: [
          MarketPrice(
            productId: 'milch_15',
            storeName: 'Beispielmarkt',
            price: 0.85,
            updatedAt: DateTime(2026, 9, 24),
            source: MarketPriceSource.receipt,
          ),
          MarketPrice(
            productId: 'milch_35',
            storeName: 'Beispielmarkt',
            price: 0.81,
            updatedAt: DateTime(2026, 9, 24),
            source: MarketPriceSource.openPrices,
          ),
        ],
        offers: sampleOffers,
        now: DateTime(2026, 9, 24));
    expect(quotes, isEmpty);
  });

  test('store preference and offer expiry are respected', () {
    expect(shoppingQuotes(item,
        prices: [receipt],
        offers: [offer],
        enabledStores: ['Beispielmarkt'],
        now: DateTime(2026, 9, 24)), hasLength(1));
    expect(shoppingQuotes(item,
        prices: [],
        offers: [offer],
        now: DateTime(2026, 10, 1)), isEmpty);
  });
}
