import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/shopping_list/shopping_price_badge.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/features/offers/prospect_price_statistics.dart';

void main() {
  testWidgets('Preisfenster zeigt Coupon als effektiven Preis', (tester) async {
    const product = Product(
      id: 'coupon-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    final offer = Offer(
      id: 'coupon-offer',
      productId: product.id,
      storeName: 'Kaufland',
      originalPrice: 1.29,
      offerPrice: 0.89,
      couponPercent: 10,
      validUntil: DateTime(2099, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingPriceBadge(
            item: ListItem(product: product),
            prices: const <MarketPrice>[],
            offers: <Offer>[offer],
            enabledStores: const <String>[],
          ),
        ),
      ),
    );

    expect(find.textContaining('Angebot, effektiv Kaufland'), findsOneWidget);
    expect(find.textContaining('0,80 €'), findsOneWidget);
  });

  testWidgets('Preisfenster zeigt Produktbild und Angebotsbild', (
    tester,
  ) async {
    final product = Product(
      id: 'cheese',
      name: 'Käse',
      unit: 'Packung',
      group: 'Milch & Käse',
      imageUrl: 'https://example.com/product.jpg',
    );
    final offer = Offer(
      id: 'offer-1',
      productId: product.id,
      storeName: 'Kaufland',
      originalPrice: 2.39,
      offerPrice: 1.49,
      validUntil: DateTime(2026, 10, 1),
      imageUrl: 'https://example.com/offer.jpg',
      source: 'leaflet',
      proofRef: 'proof',
    );
    final item = ListItem(product: product, quantity: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingPriceBadge(
            item: item,
            prices: const <MarketPrice>[],
            offers: <Offer>[offer],
            enabledStores: const <String>[],
          ),
        ),
      ),
    );
    expect(find.text('1/6 Märkte'), findsOneWidget);
    await tester.tap(find.textContaining('Angebot Kaufland'));
    await tester.pumpAndSettle();

    expect(find.text('PENNY'), findsOneWidget);
    expect(
      find.text('Kein aktueller, vergleichbarer Preisbeleg'),
      findsWidgets,
    );
    await tester.scrollUntilVisible(
      find.text('Käse · Kaufland'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Käse · Kaufland'), findsOneWidget);
    expect(find.text('Käse'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('Preisfenster kennzeichnet historischen Prospekt-Median', (
    tester,
  ) async {
    const product = Product(
      id: 'history-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    final history = ProspectPriceHistorySummary(
      productId: product.id,
      storeName: 'ALDI Süd',
      medianPrice: 0.95,
      latestValidUntil: DateTime(2026, 9, 20),
      kind: PriceObservationKind.offer,
      observationCount: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingPriceBadge(
            item: ListItem(product: product),
            prices: const <MarketPrice>[],
            offers: const <Offer>[],
            prospectPriceHistory: {product.id: history},
            enabledStores: const <String>['ALDI Süd', 'PENNY'],
          ),
        ),
      ),
    );

    expect(find.textContaining('Prospekt-Median ALDI Süd'), findsOneWidget);
    expect(find.textContaining('0/2 Märkte · 1 Historie'), findsOneWidget);
    await tester.tap(find.textContaining('Prospekt-Median ALDI Süd'));
    await tester.pumpAndSettle();
    expect(find.text('Prospekt-Historie (1 Markt)'), findsOneWidget);
    await tester.tap(find.text('Prospekt-Historie (1 Markt)'));
    await tester.pumpAndSettle();
    expect(find.text('Milch · Prospekt-Historie'), findsOneWidget);
    expect(find.text('ALDI Süd'), findsOneWidget);
    expect(find.textContaining('2 Prospektbeobachtung(en)'), findsOneWidget);
    expect(find.textContaining('Angebotshistorie'), findsOneWidget);
    expect(find.text('0,95 €'), findsNWidgets(2));
  });
}
