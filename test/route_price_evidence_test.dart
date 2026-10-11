import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_price_evidence.dart';
import 'package:sparzamapp/features/route/route_price_evidence_card.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/route_plan.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  final today = DateTime(2026, 10, 1);
  const store = Store(
    name: 'Lidl',
    location: 'Zellingen',
    distanceKm: 1,
    prices: {},
  );
  const pricedStore = Store(
    name: 'Lidl',
    location: 'Zellingen',
    distanceKm: 1,
    prices: {'catalog': 1.0},
  );

  test('zeigt Angebotsquelle und vollständige Gültigkeit', () {
    const product = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    final quote = RoutePriceResolver([
      Offer(
        id: 'milk-offer',
        productId: product.id,
        storeName: store.name,
        originalPrice: 1.29,
        offerPrice: 0.89,
        validFrom: DateTime(2026, 9, 29),
        validUntil: DateTime(2026, 10, 3),
        source: 'leaflet',
      ),
    ], now: today).quote(store, ListItem(product: product))!;

    expect(
      routePriceEvidenceLabel(quote, now: today),
      'Angebot · Prospekt · Nachweis fehlt · gültig 29.09.2026–03.10.2026',
    );
  });

  test('kennzeichnet Nachweis und Händler-Website im Routenbeleg', () {
    const product = Product(
      id: 'coffee',
      name: 'Kaffee',
      unit: '500 g',
      group: 'kaffee',
    );
    final quote = RoutePriceResolver([
      Offer(
        id: 'coffee-offer',
        productId: product.id,
        storeName: store.name,
        originalPrice: 8,
        offerPrice: 5,
        validUntil: DateTime(2026, 10, 3),
        source: 'retailer_website',
        proofRef: 'https://example.test/coffee',
      ),
    ], now: today).quote(store, ListItem(product: product))!;

    expect(
      routePriceEvidenceLabel(quote, now: today),
      'Angebot · Händler-Website · Nachweis vorhanden · gültig bis 03.10.2026',
    );
  });

  test('zeigt Quelle, Preisstand, Alter und Qualität eines Bonpreises', () {
    const product = Product(
      id: 'cheese',
      name: 'Käse',
      unit: 'Packung',
      group: 'kaese',
    );
    final quote = RoutePriceResolver(
      const [],
      now: today,
      marketPrices: [
        MarketPrice(
          productId: product.id,
          storeName: pricedStore.name,
          price: 1.79,
          updatedAt: DateTime(2026, 9, 29),
          source: MarketPriceSource.receipt,
          discounted: true,
        ),
      ],
    ).quote(store, ListItem(product: product))!;

    expect(
      routePriceEvidenceLabel(quote, now: today),
      'Kassenbon · Stand 29.09.2026 (vor 2 Tagen) · Preisqualität mittel',
    );
  });

  test('fasst Evidenzklassen ohne Schätzpreise zusammen', () {
    const offerProduct = Product(
      id: 'offer',
      name: 'Angebot',
      unit: 'Stück',
      group: 'sonstiges',
    );
    const receiptProduct = Product(
      id: 'receipt',
      name: 'Bon',
      unit: 'Stück',
      group: 'sonstiges',
    );
    const manualProduct = Product(
      id: 'manual',
      name: 'Eigener Preis',
      unit: 'Stück',
      group: 'sonstiges',
    );
    const openProduct = Product(
      id: 'open',
      name: 'Open Prices',
      unit: 'Stück',
      group: 'sonstiges',
    );
    const catalogProduct = Product(
      id: 'catalog',
      name: 'Hinterlegt',
      unit: 'Stück',
      group: 'sonstiges',
    );
    final items = [
      ListItem(product: offerProduct),
      ListItem(product: receiptProduct),
      ListItem(product: manualProduct),
      ListItem(product: openProduct),
      ListItem(product: catalogProduct),
    ];
    final resolver = RoutePriceResolver(
      [
        Offer(
          id: 'offer-id',
          productId: offerProduct.id,
          storeName: store.name,
          originalPrice: 2,
          offerPrice: 1,
          validUntil: DateTime(2026, 10, 3),
        ),
      ],
      now: today,
      marketPrices: [
        MarketPrice(
          productId: receiptProduct.id,
          storeName: store.name,
          price: 1,
          updatedAt: DateTime(2026, 9, 30),
          source: MarketPriceSource.receipt,
        ),
        MarketPrice(
          productId: manualProduct.id,
          storeName: store.name,
          price: 1,
          updatedAt: today,
          source: MarketPriceSource.manual,
        ),
        MarketPrice(
          productId: openProduct.id,
          storeName: store.name,
          price: 1,
          updatedAt: today,
          source: MarketPriceSource.openPrices,
        ),
      ],
    );
    final plan = RoutePlan(
      stores: const [pricedStore],
      assignments: {pricedStore: items},
      basket: 5,
      travel: 0,
      total: 5,
      unassigned: const [],
    );

    final summary = summarizeRoutePriceEvidence(plan, resolver);

    expect(summary.pricedPositions, 5);
    expect(summary.offers, 1);
    expect(summary.receipts, 1);
    expect(summary.ownPrices, 1);
    expect(summary.openPrices, 1);
    expect(summary.undocumented, 1);
    expect(summary.oldestObservation, DateTime(2026, 9, 30));
  });

  testWidgets('zeigt die Evidenzzusammenfassung verständlich an', (
    tester,
  ) async {
    final summary = RoutePriceEvidenceSummary(
      pricedPositions: 2,
      offers: 1,
      receipts: 1,
      ownPrices: 0,
      openPrices: 0,
      undocumented: 0,
      oldestObservation: DateTime(2026, 9, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RoutePriceEvidenceCard(summary: summary)),
      ),
    );

    expect(find.text('Preisgrundlage dieser Route'), findsOneWidget);
    expect(find.text('1 aktive Angebote'), findsOneWidget);
    expect(find.text('1 Bonpreise'), findsOneWidget);
    expect(find.textContaining('30.09.2026'), findsOneWidget);
  });
}
