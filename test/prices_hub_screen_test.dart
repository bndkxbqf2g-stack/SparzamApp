import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/catalog/prices_hub_screen.dart';
import 'package:sparzamapp/features/catalog/market_price_freshness.dart';
import 'package:sparzamapp/features/prospects/prospect_feed_status.dart';
import 'package:sparzamapp/features/price_gaps/price_gap_priority.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  testWidgets('Preise zeigt aktuelle Listenabdeckung und Markt-Hinweis', (
    tester,
  ) async {
    const product = Product(
      id: 'price-hub-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );
    final openedList = <bool>[];
    final openedRoute = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Open Prices · max. 60 Tage',
            shoppingList: [ListItem(product: product)],
            marketPrices: [
              MarketPrice(
                productId: product.id,
                storeName: 'Lidl',
                price: 1.19,
                updatedAt: DateTime.now(),
                source: MarketPriceSource.manual,
              ),
            ],
            enabledStoreNames: const ['Lidl'],
            onOpenList: () => openedList.add(true),
            onOpenRoute: () => openedRoute.add(true),
          ),
        ),
      ),
    );

    expect(find.text('Preisabdeckung deiner Liste'), findsOneWidget);
    expect(find.text('1 von 1 Positionen mit aktuellem Marktpreis'), findsOneWidget);
    expect(find.textContaining('Lidl'), findsOneWidget);
    expect(find.text('1,19 €'), findsOneWidget);

    await tester.tap(find.text('Liste öffnen'));
    await tester.tap(find.text('Route prüfen'));
    expect(openedList, [true]);
    expect(openedRoute, [true]);
  });

  testWidgets('zeigt Herkunft und Datum eines regulären Prospektpreises', (
    tester,
  ) async {
    const product = Product(
      id: 'price-hub-prospect-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Prospektpreise',
            shoppingList: [ListItem(product: product)],
            marketPrices: [
              MarketPrice(
                productId: product.id,
                storeName: 'Lidl',
                price: 1.29,
                updatedAt: DateTime(2026, 10, 13),
                source: MarketPriceSource.prospect,
                kind: PriceObservationKind.regular,
              ),
            ],
            enabledStoreNames: const ['Lidl'],
            now: DateTime(2026, 10, 13),
          ),
        ),
      ),
    );

    final card = find.byKey(
      const ValueKey('price-comparison-price-hub-prospect-milk'),
    );
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.textContaining('Prospektpreis vom 13.10.2026'), findsOneWidget);
    expect(find.textContaining('regulärer Normalpreis'), findsOneWidget);
    expect(find.textContaining('Preisalter: heute'), findsOneWidget);
  });

  testWidgets('öffnet den Marktvergleich je Listenposition', (tester) async {
    const product = Product(
      id: 'price-hub-matrix-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Eigene Preise',
            shoppingList: [ListItem(product: product)],
            marketPrices: [
              MarketPrice(
                productId: product.id,
                storeName: 'Lidl',
                price: 1.19,
                updatedAt: DateTime(2026, 10, 13),
                source: MarketPriceSource.manual,
              ),
            ],
            enabledStoreNames: const ['Lidl', 'ALDI Süd'],
            now: DateTime(2026, 10, 13),
          ),
        ),
      ),
    );

    expect(find.text('Marktvergleich deiner Liste'), findsOneWidget);
    final card = find.byKey(
      const ValueKey('price-comparison-price-hub-matrix-milk'),
    );
    expect(card, findsOneWidget);
    expect(find.text('1/2 Märkte aktuell'), findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Lidl'), findsOneWidget);
    expect(find.text('ALDI Süd'), findsOneWidget);
    expect(find.text('1,19 €'), findsNWidgets(2));
    expect(find.text('Kein aktueller, vergleichbarer Preisbeleg'), findsOneWidget);
  });

  testWidgets('Preise kennzeichnet fehlende aktuelle Preise', (tester) async {
    const milk = Product(
      id: 'price-hub-milk-missing',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );
    const coffee = Product(
      id: 'price-hub-coffee-missing',
      name: 'Kaffee',
      unit: '500 g',
      group: 'Kaffee',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Nur eigene Preise',
            shoppingList: [
              ListItem(product: milk),
              ListItem(product: coffee),
            ],
            enabledStoreNames: const ['Lidl'],
          ),
        ),
      ),
    );

    expect(find.text('0 von 2 Positionen mit aktuellem Marktpreis'), findsOneWidget);
    expect(find.text('2 Positionen ohne aktuellen Preis'), findsOneWidget);
    expect(find.text('2 unbekannt'), findsOneWidget);
  });

  testWidgets('lädt große Marktvergleiche schrittweise', (tester) async {
    final items = List<ListItem>.generate(
      13,
      (index) => ListItem(
        product: Product(
          id: 'price-hub-progress-$index',
          name: 'Produkt $index',
          unit: '1 Stück',
          group: 'Test',
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Testpreise',
            shoppingList: items,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('price-comparison-price-hub-progress-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('price-comparison-price-hub-progress-12')),
      findsNothing,
    );

    final loadMore = find.byKey(
      const ValueKey('price-comparisons-load-more'),
    );
    expect(loadMore, findsOneWidget);
    tester.widget<OutlinedButton>(loadMore).onPressed!.call();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('price-comparison-price-hub-progress-12')),
      findsOneWidget,
    );
  });

  testWidgets('öffnet für fehlende Preise direkt die Auflösung', (tester) async {
    const product = Product(
      id: 'price-hub-gap-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );
    final resolved = <PriceGapPriority>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Nur eigene Preise',
            shoppingList: [ListItem(product: product)],
            enabledStoreNames: const ['Lidl', 'ALDI Süd'],
            onResolvePriceGap: (gap) async => resolved.add(gap),
          ),
        ),
      ),
    );

    final card = find.byKey(
      const ValueKey('price-comparison-price-hub-gap-milk'),
    );
    await tester.tap(card);
    await tester.pumpAndSettle();

    final action = find.byKey(
      const ValueKey('resolve-price-gap-price-hub-gap-milk'),
    );
    expect(action, findsOneWidget);
    tester.widget<TextButton>(action).onPressed!.call();
    await tester.pump();

    expect(resolved, hasLength(1));
    expect(resolved.single.item.product.id, product.id);
    expect(resolved.single.missingMarketCount, 2);
    expect(resolved.single.marketCount, 2);
  });
  test('separates current regular prospect prices from offer evidence', () {
    final quality = calculatePriceDataQuality(
      [
        MarketPrice(
          productId: 'milk',
          storeName: 'Lidl',
          price: 1.29,
          updatedAt: DateTime(2026, 10, 13),
          source: MarketPriceSource.prospect,
          kind: PriceObservationKind.regular,
        ),
        MarketPrice(
          productId: 'coffee',
          storeName: 'Lidl',
          price: 3.99,
          updatedAt: DateTime(2026, 10, 13),
          source: MarketPriceSource.prospect,
          // Legacy rows may omit kind but retain the discounted marker.
          discounted: true,
        ),
        MarketPrice(
          productId: 'bread',
          storeName: 'ALDI Süd',
          price: 1.49,
          updatedAt: DateTime(2026, 8, 1),
          source: MarketPriceSource.prospect,
          kind: PriceObservationKind.regular,
        ),
      ],
      openPricesMaxAgeDays: 60,
      now: DateTime(2026, 10, 13),
    );

    expect(quality.total, 3);
    expect(quality.current, 1);
    expect(quality.notRouteReady, 2);
    expect(quality.currentProspectRegular, 1);
    expect(quality.prospectOfferEvidence, 1);
    expect(quality.currentByStore['Lidl'], 1);
  });

  test('excludes branchless prospect regular observations from current ledger', () {
    final now = DateTime(2026, 10, 15, 12);
    final branchless = PriceObservation(
      id: 'branchless-ledger',
      productId: 'milk',
      storeName: 'Lidl',
      price: 1.99,
      observedAt: now,
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.regular,
      validFrom: DateTime(2026, 10, 13),
      validUntil: DateTime(2026, 10, 19),
      proofRef: 'https://example.test/branchless',
    );

    expect(
      currentProspectRegularPriceObservations(
        observations: [branchless],
        now: now,
      ),
      isEmpty,
    );
  });

  test(
    'excludes superseded prospect regular observations from current ledger',
    () {
      final now = DateTime(2026, 10, 15, 12);
      final superseded = PriceObservation(
        id: 'superseded-ledger',
        productId: 'milk',
        storeName: 'Lidl',
        locationId: 'lidl-branch-1',
        price: 1.99,
        observedAt: now,
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.regular,
        validFrom: DateTime(2026, 10, 13),
        validUntil: DateTime(2026, 10, 19),
        proofRef: 'https://example.test/superseded',
        isCurrent: false,
      );

      expect(
        currentProspectRegularPriceObservations(
          observations: [superseded],
          now: now,
        ),
        isEmpty,
      );
    },
  );

  testWidgets('zeigt Preisquellen und veraltete Belege im Preise-Reiter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Prospektpreise',
            marketPrices: [
              MarketPrice(
                productId: 'milk',
                storeName: 'Lidl',
                price: 1.29,
                updatedAt: DateTime(2026, 10, 13),
                source: MarketPriceSource.prospect,
                kind: PriceObservationKind.regular,
              ),
              MarketPrice(
                productId: 'coffee',
                storeName: 'ALDI Süd',
                price: 3.99,
                updatedAt: DateTime(2026, 8, 1),
                source: MarketPriceSource.prospect,
                kind: PriceObservationKind.regular,
              ),
            ],
            now: DateTime(2026, 10, 13),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('price-data-quality-card')), findsOneWidget);
    expect(find.text('1 von 2 Belegen sind aktuell und für die Routenplanung zugelassen.'), findsOneWidget);
    expect(find.text('Prospekt-Normalpreise 1'), findsOneWidget);
    expect(find.text('1 nicht routenfähig'), findsOneWidget);
    expect(find.textContaining('Lidl: 1'), findsOneWidget);
  });

  testWidgets('zeigt unklassifizierte Prospektpreise als Datenlücke', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Prospektpreise',
            marketPrices: [
              MarketPrice(
                productId: 'unknown-prospect-milk',
                storeName: 'Lidl',
                price: 1.29,
                updatedAt: DateTime(2026, 10, 15),
                source: MarketPriceSource.prospect,
              ),
            ],
            now: DateTime(2026, 10, 15),
          ),
        ),
      ),
    );

    expect(
      find.text('Prospektpreise ohne Preisrolle 1'),
      findsOneWidget,
    );
  });

  testWidgets('zeigt bestätigte automatische Normalpreisspeicherung', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Prospektpreise',
            prospectFeedGeneratedAt: DateTime(2026, 10, 15, 8, 30),
            prospectRegularPriceCount: 2,
            prospectRegularPriceCountsByStore: const {
              'Lidl · Zellingen': 1,
              'ALDI Süd · Würzburg': 1,
            },
            prospectRegularPricePersistenceStatus:
                ProspectRegularPricePersistenceStatus.succeeded,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('prospect-regular-price-database-card')),
      findsOneWidget,
    );
    expect(find.text('Automatische Prospekt-Normalpreise'), findsOneWidget);
    expect(
      find.text('2 reguläre Normalpreise als Preisbasis gespeichert.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Feed-Stand 15.10.2026 · 08:30 Uhr'),
      findsOneWidget,
    );
    expect(find.textContaining('Lidl · Zellingen: 1'), findsOneWidget);
  });

  testWidgets('bestätigt ohne Shell-Status keine lokale Speicherung', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Prospektpreise',
            prospectFeedGeneratedAt: DateTime(2026, 10, 15, 8, 30),
            prospectRegularPriceCount: 1,
          ),
        ),
      ),
    );

    expect(
      find.text(
        '1 regulärer Normalpreis im Feed erkannt; lokale Speicherung nicht bestätigt.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Aktionspreise bleiben getrennt.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'zeigt aktuelle gespeicherte Normalpreise mit Filialnachweis',
    (tester) async {
      const product = Product(
        id: 'ledger-coffee',
        name: 'Jacobs Kaffee Crema 500 g',
        unit: '500 g',
        group: 'Kaffee',
      );
      final now = DateTime(2026, 10, 15, 12);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PricesHubScreen(
              onOpenCatalog: () {},
              onOpenSettings: () {},
              summary: 'Prospektpreise',
              catalogProducts: const [product],
              historicalPriceObservations: [
                PriceObservation(
                  id: 'ledger-regular',
                  productId: product.id,
                  storeName: 'Lidl',
                  price: 7.99,
                  observedAt: now,
                  source: PriceObservationSource.leaflet,
                  sourceAdapter: 'kaufda',
                  regularPriceSource: 'oldPrice',
                  kind: PriceObservationKind.regular,
                  evidenceConfidence: EvidenceConfidence.manuallyConfirmed,
                  validFrom: DateTime(2026, 10, 13),
                  validUntil: DateTime(2026, 10, 19),
                  locationId: 'lidl-zellingen',
                  proofRef: 'https://example.test/ledger',
                ),
                PriceObservation(
                  id: 'ledger-offer',
                  productId: product.id,
                  storeName: 'Lidl',
                  price: 4.99,
                  observedAt: now,
                  source: PriceObservationSource.leaflet,
                  sourceAdapter: 'kaufda',
                  kind: PriceObservationKind.offer,
                  validFrom: DateTime(2026, 10, 13),
                  validUntil: DateTime(2026, 10, 19),
                  locationId: 'lidl-zellingen',
                  proofRef: 'https://example.test/ledger',
                ),
                PriceObservation(
                  id: 'ledger-expired',
                  productId: product.id,
                  storeName: 'Lidl',
                  price: 6.99,
                  observedAt: DateTime(2026, 10, 1),
                  source: PriceObservationSource.leaflet,
                  kind: PriceObservationKind.regular,
                  validFrom: DateTime(2026, 9, 28),
                  validUntil: DateTime(2026, 10, 5),
                  locationId: 'lidl-zellingen',
                  proofRef: 'https://example.test/expired',
                ),
              ],
              now: now,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('prospect-regular-price-ledger-card')),
        findsOneWidget,
      );
      expect(
        find.text('1 gespeicherter regulärer Preis mit Filialnachweis'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('prospect-regular-price-ledger-card')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jacobs Kaffee Crema 500 g'), findsOneWidget);
      expect(find.text('7,99 €'), findsOneWidget);
      expect(find.textContaining('Filiale lidl-zellingen'), findsOneWidget);
      expect(find.textContaining('Erfasst 15.10.2026'), findsOneWidget);
       expect(find.textContaining('Normalpreisfeld oldPrice'), findsOneWidget);
      expect(find.textContaining('Nachweis vorhanden'), findsOneWidget);
      expect(find.textContaining('Evidenz MANUELL BESTÄTIGT'), findsOneWidget);
      expect(find.text('4,99 €'), findsNothing);
      expect(find.text('6,99 €'), findsNothing);
    },
  );

  testWidgets(
    'verwendet den Katalog für generische Prospektangebote im Preise-Reiter',
    (tester) async {
      const genericMilk = Product(
        id: 'price-hub-generic-milk',
        name: 'Milch',
        unit: '1 l',
        group: 'Milch',
      );
      const specificMilk = Product(
        id: 'price-hub-specific-milk',
        name: 'Milch 1,5 % 1 l',
        unit: '1 l',
        group: 'Milch',
        packageAmount: 1,
        packageUnit: 'l',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PricesHubScreen(
              onOpenCatalog: () {},
              onOpenSettings: () {},
              summary: 'Prospektpreise',
              shoppingList: [ListItem(product: genericMilk)],
              catalogProducts: const [specificMilk],
              offers: [
                Offer(
                  id: 'price-hub-generic-prospect-offer',
                  productId: specificMilk.id,
                  storeName: 'Lidl',
                  originalPrice: 1.49,
                  offerPrice: 0.99,
                  validFrom: DateTime(2026, 10, 13),
                  validUntil: DateTime(2026, 10, 19),
                  source: 'retailerWebsite',
                  proofRef: 'https://example.test/prospect/milk',
                  locationId: 'lidl_zellingen',
                  packageAmount: 1,
                  packageUnit: 'l',
                ),
              ],
              enabledStoreNames: const ['Lidl'],
              now: DateTime(2026, 10, 15),
            ),
          ),
        ),
      );

      expect(
        find.text('1 von 1 Positionen mit aktuellem Marktpreis'),
        findsOneWidget,
      );
      final card = find.byKey(
        const ValueKey('price-comparison-price-hub-generic-milk'),
      );
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.text('1/1 Märkte aktuell'), findsOneWidget);
      expect(find.textContaining('Angebot bis 19.10.2026'), findsOneWidget);
      expect(find.text('0,99 €'), findsNWidgets(2));
    },
  );

  testWidgets('sortiert aktuelle Preis-Hinweise nach dem günstigsten Wert', (
    tester,
  ) async {
    const expensive = Product(
      id: 'price-hub-sort-expensive',
      name: 'Teures Produkt',
      unit: '1 Stück',
      group: 'Test',
    );
    const cheap = Product(
      id: 'price-hub-sort-cheap',
      name: 'Günstiges Produkt',
      unit: '1 Stück',
      group: 'Test',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Testpreise',
            shoppingList: [
              ListItem(product: expensive),
              ListItem(product: cheap),
            ],
            marketPrices: [
              MarketPrice(
                productId: expensive.id,
                storeName: 'Lidl',
                price: 9.99,
                updatedAt: DateTime(2026, 10, 15),
                source: MarketPriceSource.manual,
              ),
              MarketPrice(
                productId: cheap.id,
                storeName: 'Lidl',
                price: 1.49,
                updatedAt: DateTime(2026, 10, 15),
                source: MarketPriceSource.manual,
              ),
            ],
            enabledStoreNames: const ['Lidl'],
            now: DateTime(2026, 10, 15),
          ),
        ),
      ),
    );

    final cheapTile = find.byKey(
      const ValueKey('price-snapshot-price-hub-sort-cheap'),
    );
    final expensiveTile = find.byKey(
      const ValueKey('price-snapshot-price-hub-sort-expensive'),
    );
    expect(cheapTile, findsOneWidget);
    expect(expensiveTile, findsOneWidget);
    expect(
      tester.getTopLeft(cheapTile).dy,
      lessThan(tester.getTopLeft(expensiveTile).dy),
    );
  });


  testWidgets('aktualisiert den Preis-Hinweis nach neuem Preisstand', (
    tester,
  ) async {
    const product = Product(
      id: 'price-hub-refresh-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );

    Widget app(double price) => MaterialApp(
          home: Scaffold(
            body: PricesHubScreen(
              onOpenCatalog: () {},
              onOpenSettings: () {},
              summary: 'Preisrefresh',
              shoppingList: [ListItem(product: product)],
              marketPrices: [
                MarketPrice(
                  productId: product.id,
                  storeName: 'Lidl',
                  price: price,
                  updatedAt: DateTime(2026, 10, 17),
                  source: MarketPriceSource.manual,
                ),
              ],
              enabledStoreNames: const ['Lidl'],
              now: DateTime(2026, 10, 17),
            ),
          ),
        );

    await tester.pumpWidget(app(2.99));
    final tile = find.byKey(
      const ValueKey('price-snapshot-price-hub-refresh-milk'),
    );
    expect(
      find.descendant(of: tile, matching: find.text('2,99 €')),
      findsOneWidget,
    );

    await tester.pumpWidget(app(1.49));
    await tester.pump();

    expect(
      find.descendant(of: tile, matching: find.text('1,49 €')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.text('2,99 €')),
      findsNothing,
    );
  });


  testWidgets(
    'aktualisiert Marktprovenienz im Quote-Snapshot',
    (tester) async {
      const product = Product(
        id: 'price-hub-provenance-milk',
        name: 'Milch',
        unit: '1 l',
        group: 'Milch',
      );

      Widget app(String branchName) => MaterialApp(
            home: Scaffold(
              body: PricesHubScreen(
                onOpenCatalog: () {},
                onOpenSettings: () {},
                summary: 'Provenienz',
                shoppingList: [ListItem(product: product)],
                marketPrices: [
                  MarketPrice(
                    productId: product.id,
                    storeName: 'Lidl',
                    price: 1.19,
                    updatedAt: DateTime(2026, 10, 17),
                    source: MarketPriceSource.manual,
                    sourceLocationId: 'lidl_zellingen',
                    sourceLocationName: branchName,
                  ),
                ],
                enabledStoreNames: const ['Lidl'],
                now: DateTime(2026, 10, 17),
              ),
            ),
          );

      await tester.pumpWidget(app('Zellingen'));
      final card = find.byKey(
        const ValueKey('price-comparison-price-hub-provenance-milk'),
      );
      await tester.tap(card);
      await tester.pump();
      expect(find.textContaining('Filiale Zellingen'), findsOneWidget);

      await tester.pumpWidget(app('Würzburg'));
      await tester.pump();
      expect(find.textContaining('Filiale Würzburg'), findsOneWidget);
      expect(find.textContaining('Filiale Zellingen'), findsNothing);
    },
  );

  testWidgets('aktualisiert Prospekt-Normalpreise direkt aus dem Preise-Reiter', (
    tester,
  ) async {
    var refreshes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Prospektpreise',
            prospectFeedGeneratedAt: DateTime(2026, 10, 17, 8, 30),
            prospectRegularPriceCount: 1,
            prospectRegularPricePersistenceStatus:
                ProspectRegularPricePersistenceStatus.succeeded,
            onRefreshProspects: () async {
              refreshes++;
            },
          ),
        ),
      ),
    );

    final refresh = find.byKey(
      const ValueKey('prospect-regular-price-refresh'),
    );
    expect(refresh, findsOneWidget);
    await tester.tap(refresh);
    await tester.pump();

    expect(refreshes, 1);
    expect(
      find.textContaining(
        'Der Abruf speichert danach nur ausdrücklich ausgewiesene',
      ),
      findsOneWidget,
    );
  });


  testWidgets('trennt aktuelle Angebotspreise ohne Normalpreis sichtbar ab', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Prospektpreise',
            offers: [
              Offer(
                id: 'import|leaflet|offer-only|milk',
                productId: 'offer-only-milk',
                storeName: 'EDEKA',
                originalPrice: 0.99,
                originalPriceVerified: false,
                offerPrice: 0.99,
                validFrom: DateTime(2026, 10, 17),
                validUntil: DateTime(2026, 10, 17),
                source: 'retailerWebsite',
                proofRef: 'https://example.test/edeka/milk',
              ),
            ],
            prospectFeedGeneratedAt: DateTime(2026, 10, 17, 8),
            prospectRegularPriceCount: 1,
            prospectRegularPricePersistenceStatus:
                ProspectRegularPricePersistenceStatus.succeeded,
            now: DateTime(2026, 10, 17, 12),
          ),
        ),
      ),
    );

    expect(
      find.textContaining(
        '1 aktueller Angebotspreis ohne belegten Normalpreis bleiben getrennt',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('nicht als Preisbasis gespeichert'),
      findsOneWidget,
    );
  });

  testWidgets('erklärt Preisdatenlücken und exakte Filiale', (tester) async {
    final now = DateTime(2026, 10, 17);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Preisqualität',
            marketPrices: [
              MarketPrice(
                productId: 'current',
                storeName: 'Lidl',
                price: 1.19,
                updatedAt: now,
                source: MarketPriceSource.manual,
                sourceLocationId: 'LIDL-THUENGERSHEIM',
              ),
              MarketPrice(
                productId: 'future',
                storeName: 'Lidl',
                price: 1.29,
                updatedAt: DateTime(2026, 10, 18),
                source: MarketPriceSource.receipt,
              ),
              MarketPrice(
                productId: 'stale',
                storeName: 'Lidl',
                price: 1.39,
                updatedAt: DateTime(2026, 8, 1),
                source: MarketPriceSource.openPrices,
              ),
              MarketPrice(
                productId: 'uncertain',
                storeName: 'Lidl',
                price: 1.49,
                updatedAt: now,
                source: MarketPriceSource.openPrices,
                identityConfidence: 0.5,
              ),
              MarketPrice(
                productId: 'incomparable',
                storeName: 'Lidl',
                price: 1.59,
                updatedAt: now,
                source: MarketPriceSource.openPrices,
                quantity: 1000,
              ),
              MarketPrice(
                productId: 'low-confidence',
                storeName: 'Lidl',
                price: 1.79,
                updatedAt: now,
                source: MarketPriceSource.manual,
                evidenceConfidence: EvidenceConfidence.uncertain,
              ),
            ],
            now: now,
          ),
        ),
      ),
    );

    expect(find.text('1 von 6 Belegen sind aktuell und für die Routenplanung zugelassen.'), findsOneWidget);
    expect(find.text('1 zukünftig'), findsOneWidget);
    expect(find.text('1 veraltet'), findsOneWidget);
    expect(find.text('1 Identität unklar'), findsOneWidget);
    expect(find.text('1 Mengenbasis fehlt'), findsOneWidget);
    expect(find.text('1 unsichere Belege'), findsOneWidget);
    expect(find.text('Aktuell je Markt/Filiale'), findsOneWidget);
    expect(find.textContaining('Lidl · LIDL-THUENGERSHEIM: 1'), findsOneWidget);
  });

  testWidgets('Preise-Reiter erklärt fehlenden aktuellen Marktpreis', (
    tester,
  ) async {
    const product = Product(
      id: 'gap-hub-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Preisqualität',
            shoppingList: [ListItem(product: product)],
            marketPrices: [
              MarketPrice(
                productId: product.id,
                storeName: 'Lidl',
                price: 1.09,
                updatedAt: DateTime(2020, 1, 1),
                source: MarketPriceSource.openPrices,
              ),
            ],
            enabledStoreNames: const ['Lidl'],
            now: DateTime(2026, 9, 24),
          ),
        ),
      ),
    );

    final card = find.byKey(
      const ValueKey('price-comparison-gap-hub-milk'),
    );
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('Beleg veraltet oder abgelaufen'), findsOneWidget);
  });

}
