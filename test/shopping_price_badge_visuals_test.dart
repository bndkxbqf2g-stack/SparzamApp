import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/shopping_list/shopping_price_badge.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  testWidgets('Preisfenster zeigt Produktbild und Angebotsbild', (tester) async {
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

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShoppingPriceBadge(
          item: item,
          prices: const <MarketPrice>[],
          offers: <Offer>[offer],
          enabledStores: const <String>[],
        ),
      ),
    ));
    expect(find.text('1/6 Märkte'), findsOneWidget);
    await tester.tap(find.textContaining('Angebot Kaufland'));
    await tester.pumpAndSettle();

    expect(find.text('PENNY'), findsOneWidget);
    expect(find.text('Kein aktueller, vergleichbarer Preisbeleg'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Käse · Kaufland'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Käse · Kaufland'), findsOneWidget);
    expect(find.text('Käse'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
  });
}
