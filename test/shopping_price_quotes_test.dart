import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/offers.dart';
import 'package:sparzamapp/features/shopping_list/shopping_price_quotes.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/features/offers/prospect_price_statistics.dart';

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


  test('quote snapshot resolves a generic prospect item through the catalog', () {
    const generic = Product(
      id: 'custom_milk_request',
      name: 'Milch',
      unit: 'Artikel',
      group: 'milch',
    );
    const variant = Product(
      id: 'milk_15_catalog',
      name: 'Milch 1,5 %',
      unit: '1 l',
      group: 'milch',
      packageAmount: 1,
      packageUnit: 'l',
    );
    final offer = Offer(
      id: 'catalog_backed_milk_offer',
      productId: variant.id,
      storeName: 'Lidl',
      originalPrice: 1.49,
      originalPriceVerified: true,
      offerPrice: 0.99,
      validFrom: DateTime(2026, 9, 1),
      validUntil: DateTime(2026, 10, 1),
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      proofRef: 'https://example.test/prospect/milk',
      locationId: 'lidl_zellingen',
      packageAmount: 1,
      packageUnit: 'l',
      unitPrice: 0.99,
    );

    final item = ListItem(product: generic);
    final snapshot = shoppingPriceQuoteSnapshot(
      [item],
      prices: const [],
      offers: [offer],
      catalogProducts: const [variant],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    );

    final quote = snapshot.quotesFor(item).single;
    expect(quote.storeName, 'Lidl');
    expect(quote.unitPrice, 0.99);
    expect(quote.kind, ShoppingQuoteKind.offer);
  });

  test('shopping quotes retain package and base-unit price', () {
    const basisProduct = Product(
      id: 'basis-milk',
      name: 'Milch',
      unit: '500 g',
      group: 'milch',
      packageAmount: 500,
      packageUnit: 'g',
    );
    final quote = shoppingQuotes(
      ListItem(product: basisProduct),
      prices: [
        MarketPrice(
          productId: basisProduct.id,
          storeName: 'Lidl',
          price: 2.49,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.openPrices,
          quantity: 500,
          unit: 'g',
          unitPrice: 4.98,
        ),
      ],
      offers: const [],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(quote.packageLabel, '500 g');
    expect(quote.baseUnitPriceLabel, 'Grundpreis 4,98 €/kg');
  });
  test('kennzeichnet einen gespeicherten regulären Prospektpreis', () {
    final quote = shoppingQuotes(
      item,
      prices: [
        MarketPrice(
          productId: milk.id,
          storeName: 'Lidl',
          price: 1.29,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.prospect,
          kind: PriceObservationKind.regular,
        ),
      ],
      offers: const [],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(quote.isRegularProspectPrice, isTrue);
    expect(quote.displayPrefix, 'Prospektpreis · Normalpreis');
    expect(
      quote.sourceLabel,
      'Prospektpreis vom 24.09.2026 · regulärer Normalpreis',
    );
  });

  test('older receipts remain dated observations alongside current offers', () {
    final quotes = shoppingQuotes(
      item,
      prices: [receipt],
      offers: [offer],
      now: DateTime(2026, 9, 24),
    );
    expect(quotes, hasLength(2));
    expect(quotes.first.kind, ShoppingQuoteKind.offer);
    expect(quotes.first.unitPrice, 0.80);
    expect(quotes.first.savings, 0.49);
    expect(quotes.first.savingsLabel, 'Ersparnis 0,49 €');
    expect(quotes.first.sourceLabel, 'Angebot, effektiv bis 30.09.2026');
    expect(quotes.last.sourceLabel, 'Historischer Bonpreis vom 14.07.2026');
    expect(quotes.last.unitPrice, 1.05);
    expect(quotes.last.isHistorical, isTrue);
  });

  test('offer evidence keeps source and proof state visible', () {
    final sourcedOffer = Offer(
      id: 'sourced_offer',
      productId: milk.id,
      storeName: 'Kaufland',
      originalPrice: 1.29,
      offerPrice: 0.89,
      source: 'retailerWebsite',
      proofRef: 'https://example.test/offer',
      validUntil: DateTime(2026, 9, 30),
    );

    final quote = shoppingQuotes(
      item,
      prices: const [],
      offers: [sourcedOffer],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(
      quote.evidenceLabel,
      'Händler-Website · Nachweis vorhanden · Angebot bis 30.09.2026',
    );
  });

  test('shopping evidence names KaufDA when the adapter is present', () {
    final sourcedOffer = Offer(
      id: 'kaufda_offer',
      productId: milk.id,
      storeName: 'Lidl',
      originalPrice: 1.29,
      offerPrice: 0.89,
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      capturedAt: DateTime(2026, 9, 23, 6, 45),
      proofRef: 'https://www.kaufda.de/example',
      locationId: 'lidl_zellingen',
      validUntil: DateTime(2026, 9, 30),
    );

    final quote = shoppingQuotes(
      item,
      prices: const [],
      offers: [sourcedOffer],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(
      quote.evidenceLabel,
      'KaufDA · Nachweis vorhanden · Angebot bis 30.09.2026 · erfasst 23.09.2026 06:45 Uhr',
    );
  });

  test('missing offer proof remains explicit', () {
    final quote = shoppingQuotes(
      item,
      prices: const [],
      offers: [offer],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(quote.evidenceLabel, startsWith('Manuell · Nachweis fehlt · '));
  });

  test('unproven external offers stay out of current price quotes', () {
    final unproven = Offer(
      id: 'unproven-leaflet',
      productId: milk.id,
      storeName: 'Lidl',
      originalPrice: 1.29,
      offerPrice: 0.59,
      source: 'leaflet',
      validUntil: DateTime(2026, 9, 30),
    );

    expect(
      shoppingQuotes(
        item,
        prices: const [],
        offers: [unproven],
        now: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
  });

  test('offers with an incompatible explicit package stay out of quotes', () {
    final wrongPackage = Offer(
      id: 'wrong-package-offer',
      productId: milk.id,
      storeName: 'Lidl',
      originalPrice: 1.29,
      offerPrice: 0.59,
      source: 'retailerWebsite',
      proofRef: 'https://example.test/wrong-package',
      validUntil: DateTime(2026, 9, 30),
      packageAmount: 500,
      packageUnit: 'ml',
      unitPrice: 1.18,
    );

    expect(
      shoppingQuotes(
        item,
        prices: const [],
        offers: [wrongPackage],
        now: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
  });

  test('legacy regional KaufDA offers stay out of current quotes', () {
    final regional = Offer(
      id: 'legacy-regional-kaufda',
      productId: milk.id,
      storeName: 'Lidl',
      originalPrice: 1.29,
      offerPrice: 0.59,
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Milch',
      validUntil: DateTime(2026, 9, 30),
    );

    expect(
      shoppingQuotes(
        item,
        prices: const [],
        offers: [regional],
        now: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
  });

  test('cashback is shown as the effective shopping-list price', () {
    final cashbackOffer = Offer(
      id: 'cashback_offer',
      productId: 'milch_35',
      storeName: 'ALDI Süd',
      originalPrice: 1.29,
      offerPrice: 0.99,
      cashbackAmount: 0.20,
      validUntil: DateTime(2026, 9, 30),
    );

    final quote = shoppingQuotes(
      item,
      prices: const [],
      offers: [cashbackOffer],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(quote.unitPrice, 0.79);
    expect(quote.savings, 0.50);
    expect(quote.savingsLabel, 'Ersparnis 0,50 €');
    expect(quote.sourceLabel, 'Angebot, effektiv bis 30.09.2026');
  });

  test('unverified normal prices never become a displayed saving', () {
    final offer = Offer(
      id: 'unverified_offer',
      productId: milk.id,
      storeName: 'Netto',
      originalPrice: 8,
      originalPriceVerified: false,
      offerPrice: 5,
      validUntil: DateTime(2026, 9, 30),
    );

    final quote = shoppingQuotes(
      item,
      prices: const [],
      offers: [offer],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(quote.savings, isNull);
    expect(quote.savingsLabel, isNull);
  });

  test('demo offers and unlike products are not used, Open Prices stay visible', () {
    final quotes = shoppingQuotes(
      item,
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
      now: DateTime(2026, 9, 24),
    );
    expect(quotes, hasLength(1));
    expect(quotes.single.kind, ShoppingQuoteKind.openPrices);
    expect(quotes.single.displayPrefix, 'Open Prices');
  });

  test('stale Open Prices data stays out of current shopping quotes', () {
    final stale = MarketPrice(
      productId: milk.id,
      storeName: 'Lidl',
      price: 0.81,
      updatedAt: DateTime(2026, 1, 1),
      source: MarketPriceSource.openPrices,
    );

    expect(
      shoppingQuotes(
        item,
        prices: [stale],
        offers: const [],
        now: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
  });

  test('uncertain market prices stay out of exact shopping quotes', () {
    final uncertain = MarketPrice(
      productId: milk.id,
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 9, 24),
      source: MarketPriceSource.receipt,
      identityConfidence: 0.8,
    );

    expect(
      shoppingQuotes(
        item,
        prices: [uncertain],
        offers: const [],
        now: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
  });

  test('invalid explicit market package basis stays out of quotes', () {
    final invalidBasis = MarketPrice(
      productId: milk.id,
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 9, 24),
      source: MarketPriceSource.manual,
      quantity: 0,
      unit: 'l',
      unitPrice: 0,
    );

    expect(
      shoppingQuotes(
        item,
        prices: [invalidBasis],
        offers: const [],
        now: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
  });

  test('shopping quotes ignore prices from another configured branch', () {
    final wrongBranch = MarketPrice(
      productId: milk.id,
      storeName: 'Lidl',
      price: 0.49,
      updatedAt: DateTime(2026, 9, 24),
      sourceLocationId: 'lidl-wuerzburg',
    );
    final exactBranch = MarketPrice(
      productId: milk.id,
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 9, 24),
      sourceLocationId: 'lidl_zellingen',
    );

    expect(
      shoppingQuotes(
        item,
        prices: [wrongBranch],
        offers: const [],
        enabledStores: const ['Lidl'],
        now: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
    expect(
      shoppingQuotes(
        item,
        prices: [exactBranch],
        offers: const [],
        enabledStores: const ['Lidl'],
        now: DateTime(2026, 9, 24),
      ).single.unitPrice,
      0.79,
    );
  });

  test('store preference and offer expiry are respected', () {
    expect(
      shoppingQuotes(
        item,
        prices: [receipt],
        offers: [offer],
        enabledStores: ['Beispielmarkt'],
        now: DateTime(2026, 9, 24),
      ),
      hasLength(1),
    );
    expect(
      shoppingQuotes(
        item,
        prices: [],
        offers: [offer],
        now: DateTime(2026, 10, 1),
      ),
      isEmpty,
    );
  });

  test('future offers are hidden before their validFrom date', () {
    final future = Offer(
      id: 'future_offer',
      productId: 'milch_35',
      storeName: 'Lidl',
      originalPrice: 1.29,
      offerPrice: 0.79,
      validFrom: DateTime(2026, 9, 28),
      validUntil: DateTime(2026, 10, 2),
    );

    expect(
      shoppingQuotes(
        item,
        prices: const [],
        offers: [future],
        now: DateTime(2026, 9, 27),
      ),
      isEmpty,
    );
    expect(
      shoppingQuotes(
        item,
        prices: const [],
        offers: [future],
        now: DateTime(2026, 9, 28),
      ),
      hasLength(1),
    );
  });

  test('future receipt observations are hidden from current shopping quotes', () {
    final futureReceipt = MarketPrice(
      productId: milk.id,
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 9, 25),
      source: MarketPriceSource.receipt,
    );

    expect(
      shoppingQuotes(
        item,
        prices: [futureReceipt],
        offers: const [],
        now: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
  });

  test('future manual prices are hidden from current shopping quotes', () {
    final futureManual = MarketPrice(
      productId: milk.id,
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 9, 25),
    );

    expect(
      shoppingQuotes(
        item,
        prices: [futureManual],
        offers: const [],
        now: DateTime(2026, 9, 24),
      ),
      isEmpty,
    );
  });

  test('price matrix keeps missing enabled markets visible', () {
    final matrix = shoppingPriceMatrix(
      item,
      prices: [receipt],
      offers: [offer],
      enabledStores: const ['Lidl', 'Beispielmarkt', 'PENNY'],
      now: DateTime(2026, 9, 24),
    );

    expect(matrix.map((entry) => entry.storeName), [
      'Lidl',
      'Beispielmarkt',
      'PENNY',
    ]);
    expect(matrix[0].quote?.kind, ShoppingQuoteKind.offer);
    expect(matrix[1].quote?.kind, ShoppingQuoteKind.receipt);
    expect(matrix[2].quote, isNull);
  });

  test(
    'stale receipt remains visible as history, not current market coverage',
    () {
      final matrix = shoppingPriceMatrix(
        item,
        prices: [receipt],
        offers: const [],
        enabledStores: const ['Beispielmarkt'],
        now: DateTime(2026, 9, 24),
      );

      expect(matrix.single.quote?.displayPrefix, 'Historischer Bonpreis');
      expect(matrix.single.hasCurrentQuote, isFalse);
      expect(matrix.single.hasHistoricalQuote, isTrue);
    },
  );

  test('without store filter the matrix covers the six configured markets', () {
    final matrix = shoppingPriceMatrix(
      item,
      prices: const [],
      offers: const [],
      now: DateTime(2026, 9, 24),
    );

    expect(matrix, hasLength(6));
    expect(matrix.every((entry) => entry.quote == null), isTrue);
  });

  test('historical prospect median fills a market without a current quote', () {
    final matrix = shoppingPriceMatrix(
      item,
      prices: const [],
      offers: const [],
      prospectPriceHistory: {
        milk.id: ProspectPriceHistorySummary(
          productId: milk.id,
          storeName: 'ALDI Süd',
          medianPrice: 0.95,
          latestValidUntil: DateTime(2026, 9, 20),
          kind: PriceObservationKind.offer,
          observationCount: 2,
        ),
      },
      enabledStores: const ['ALDI Süd', 'PENNY'],
      now: DateTime(2026, 9, 24),
    );

    expect(matrix[0].storeName, 'ALDI Süd');
    expect(matrix[0].quote?.kind, ShoppingQuoteKind.prospectHistory);
    expect(
      matrix[0].quote?.sourceLabel,
      'Prospekt-Median (historisch, bis 20.09.2026)',
    );
    expect(matrix[0].hasCurrentQuote, isFalse);
    expect(matrix[0].hasHistoricalQuote, isTrue);
    expect(matrix[1].quote, isNull);
  });

  test('current quote takes precedence over historical prospect context', () {
    final matrix = shoppingPriceMatrix(
      item,
      prices: [
        MarketPrice(
          productId: milk.id,
          storeName: 'ALDI Süd',
          price: 1.09,
          updatedAt: DateTime(2026, 9, 24),
        ),
      ],
      offers: const [],
      prospectPriceHistory: {
        milk.id: ProspectPriceHistorySummary(
          productId: milk.id,
          storeName: 'ALDI Süd',
          medianPrice: 0.95,
          latestValidUntil: DateTime(2026, 9, 20),
          kind: PriceObservationKind.offer,
          observationCount: 2,
        ),
      },
      enabledStores: const ['ALDI Süd'],
      now: DateTime(2026, 9, 24),
    );

    expect(matrix.single.quote?.kind, ShoppingQuoteKind.ownPrice);
    expect(matrix.single.quote?.unitPrice, 1.09);
  });

  test('current Open Prices beat a newer but stale receipt in the matrix', () {
    final matrix = shoppingPriceMatrix(
      item,
      prices: [
        MarketPrice(
          productId: milk.id,
          storeName: 'ALDI Süd',
          price: 0.53,
          updatedAt: DateTime(2026, 7, 30),
          source: MarketPriceSource.openPrices,
        ),
        MarketPrice(
          productId: milk.id,
          storeName: 'ALDI Süd',
          price: 0.50,
          updatedAt: DateTime(2026, 8, 20),
          source: MarketPriceSource.receipt,
        ),
      ],
      offers: const [],
      enabledStores: const ['ALDI Süd'],
      now: DateTime(2026, 9, 24),
    );

    expect(matrix.single.quote?.kind, ShoppingQuoteKind.openPrices);
    expect(matrix.single.quote?.isHistorical, isFalse);
  });

  test('matrix uses the quality-adjusted current price within a market', () {
    final matrix = shoppingPriceMatrix(
      item,
      prices: [
        MarketPrice(
          productId: milk.id,
          storeName: 'ALDI Süd',
          price: 0.50,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.receipt,
          discounted: true,
        ),
        MarketPrice(
          productId: milk.id,
          storeName: 'ALDI Süd',
          price: 0.53,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.openPrices,
        ),
      ],
      offers: const [],
      enabledStores: const ['ALDI Süd'],
      now: DateTime(2026, 9, 24),
    );

    expect(matrix.single.quote?.kind, ShoppingQuoteKind.openPrices);
    expect(matrix.single.quote?.unitPrice, 0.53);
  });
  test('matrix chooses a prospect offer only when its effective price is lower', () {
    final current = MarketPrice(
      productId: milk.id,
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 9, 24),
      source: MarketPriceSource.receipt,
    );
    final expensiveOffer = Offer(
      id: 'expensive_offer',
      productId: milk.id,
      storeName: 'Lidl',
      originalPrice: 1.29,
      offerPrice: 0.99,
      validUntil: DateTime(2026, 9, 30),
    );
    final cheapOffer = Offer(
      id: 'cheap_offer',
      productId: milk.id,
      storeName: 'Lidl',
      originalPrice: 1.29,
      offerPrice: 0.69,
      validUntil: DateTime(2026, 9, 30),
    );

    final expensiveMatrix = shoppingPriceMatrix(
      item,
      prices: [current],
      offers: [expensiveOffer],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    );
    expect(expensiveMatrix.single.quote?.kind, ShoppingQuoteKind.receipt);
    expect(expensiveMatrix.single.quote?.unitPrice, 0.79);

    final cheapMatrix = shoppingPriceMatrix(
      item,
      prices: [current],
      offers: [cheapOffer],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    );
    expect(cheapMatrix.single.quote?.kind, ShoppingQuoteKind.offer);
    expect(cheapMatrix.single.quote?.unitPrice, 0.69);
  });



  test('kennzeichnet explizite und fehlende Mengenbasis', () {
    const basisProduct = Product(
      id: 'basis-comparability',
      name: 'Milch',
      unit: '500 g',
      group: 'milch',
      packageAmount: 500,
      packageUnit: 'g',
    );
    final explicit = shoppingQuotes(
      ListItem(product: basisProduct),
      prices: [
        MarketPrice(
          productId: basisProduct.id,
          storeName: 'Lidl',
          price: 2.49,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.openPrices,
          quantity: 500,
          unit: 'g',
          unitPrice: 4.98,
        ),
      ],
      offers: const [],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    ).single;
    expect(
      explicit.comparabilityLabel,
      'Vergleichbarkeit: Packungsbasis belegt',
    );

    const legacyProduct = Product(
      id: 'legacy-comparability',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    final legacy = shoppingQuotes(
      ListItem(product: legacyProduct),
      prices: [
        MarketPrice(
          productId: legacyProduct.id,
          storeName: 'Lidl',
          price: 1.09,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.receipt,
        ),
      ],
      offers: const [],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    ).single;
    expect(
      legacy.comparabilityLabel,
      'Vergleichbarkeit: Mengenbasis nicht dokumentiert',
    );
  });
  test('zeigt das Alter der Preisbeobachtung transparent an', () {
    final quote = shoppingQuotes(
      item,
      prices: [
        MarketPrice(
          productId: milk.id,
          storeName: 'Lidl',
          price: 1.09,
          updatedAt: DateTime(2026, 9, 22),
          source: MarketPriceSource.openPrices,
        ),
      ],
      offers: const [],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(
      quote.freshnessLabel(now: DateTime(2026, 9, 24)),
      'Preisalter: vor 2 Tagen',
    );

    final historical = ShoppingQuote(
      storeName: 'Lidl',
      unitPrice: 0.95,
      kind: ShoppingQuoteKind.prospectHistory,
      observedAt: DateTime(2026, 9, 20),
      historical: true,
    );
    expect(
      historical.freshnessLabel(now: DateTime(2026, 9, 24)),
      'Preisalter: historisch',
    );

    final offerQuote = shoppingQuotes(
      item,
      prices: const [],
      offers: [
        Offer(
          id: 'captured-offer',
          productId: milk.id,
          storeName: 'Lidl',
          originalPrice: 1.29,
          offerPrice: 0.89,
          validUntil: DateTime(2026, 9, 30),
          capturedAt: DateTime(2026, 9, 23),
        ),
      ],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    ).single;
    expect(
      offerQuote.freshnessLabel(now: DateTime(2026, 9, 24)),
      'Preisalter: vor 1 Tag',
    );
  });

  test('matrix can reuse the already resolved quote snapshot', () {
    final quotes = shoppingQuotes(
      item,
      prices: const [],
      offers: [offer],
      enabledStores: const ['Lidl', 'ALDI Süd'],
      now: DateTime(2026, 9, 24),
    );
    final direct = shoppingPriceMatrix(
      item,
      prices: const [],
      offers: [offer],
      enabledStores: const ['Lidl', 'ALDI Süd'],
      now: DateTime(2026, 9, 24),
    );
    final reused = shoppingPriceMatrixFromQuotes(
      quotes,
      enabledStores: const ['Lidl', 'ALDI Süd'],
    );

    expect(
      reused.map((entry) => entry.storeName),
      direct.map((entry) => entry.storeName),
    );
    expect(
      reused.map((entry) => entry.quote?.unitPrice),
      direct.map((entry) => entry.quote?.unitPrice),
    );
  });

  test('snapshot resolves each product once and matches direct matrix values', () {
    const secondProduct = Product(
      id: 'butter-250',
      name: 'Butter 250 g',
      unit: '250 g',
      group: 'butter',
      packageAmount: 250,
      packageUnit: 'g',
    );
    final snapshot = shoppingPriceQuoteSnapshot(
      [item, ListItem(product: milk), ListItem(product: secondProduct)],
      prices: [
        MarketPrice(
          productId: milk.id,
          storeName: 'Lidl',
          price: 1.09,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.prospect,
        ),
        MarketPrice(
          productId: secondProduct.id,
          storeName: 'PENNY',
          price: 1.79,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.prospect,
          quantity: 250,
          unit: 'g',
          unitPrice: 7.16,
        ),
      ],
      offers: const [],
      enabledStores: const ['Lidl', 'PENNY'],
      now: DateTime(2026, 9, 24),
    );

    expect(snapshot.quotesFor(item), hasLength(1));
    expect(snapshot.quotesFor(item).single.unitPrice, 1.09);
    expect(snapshot.matrixFor(item), hasLength(2));
    expect(snapshot.matrixFor(item)[0].quote?.unitPrice, 1.09);
    expect(snapshot.matrixFor(ListItem(product: secondProduct))[1].quote?.unitPrice, 1.79);
  });


  test('shopping quotes retain the exact configured branch', () {
    final quote = shoppingQuotes(
      item,
      prices: [
        MarketPrice(
          productId: milk.id,
          storeName: 'Lidl',
          price: 1.19,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.prospect,
          sourceLocationId: 'lidl_zellingen',
          sourceLocationName: 'Zellingen',
        ),
      ],
      offers: const [],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(quote.locationId, 'lidl_zellingen');
    expect(quote.branchLabel, 'Zellingen');
  });

  test('offer quotes retain regional and address metadata', () {
    final quote = shoppingQuotes(
      item,
      prices: const [],
      offers: [
        Offer(
          id: 'branch-offer',
          productId: milk.id,
          storeName: 'Lidl',
          originalPrice: 1.29,
          offerPrice: 0.89,
          source: 'retailerWebsite',
          proofRef: 'https://example.test/branch-offer',
          locationId: 'lidl_zellingen',
          region: 'Zellingen',
          address: 'Am Güßgraben 2',
          validUntil: DateTime(2026, 9, 30),
        ),
      ],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    ).single;

    expect(quote.locationId, 'lidl_zellingen');
    expect(quote.branchLabel, 'Zellingen · Am Güßgraben 2');
  });

  test('matrix branch tie-breaker is deterministic', () {
    final quotes = [
      ShoppingQuote(
        storeName: 'Lidl',
        unitPrice: 1.09,
        kind: ShoppingQuoteKind.prospect,
        observedAt: DateTime(2026, 9, 24),
        locationId: 'lidl_zellingen_b',
      ),
      ShoppingQuote(
        storeName: 'Lidl',
        unitPrice: 1.09,
        kind: ShoppingQuoteKind.prospect,
        observedAt: DateTime(2026, 9, 24),
        locationId: 'lidl_zellingen_a',
      ),
    ];

    final matrix = shoppingPriceMatrixFromQuotes(
      quotes,
      enabledStores: const ['Lidl'],
    );

    expect(matrix.single.quote?.locationId, 'lidl_zellingen_a');
  });

  test('generic item shows a current matching prospect offer by market', () {
    const genericMilk = Product(
      id: 'milch',
      name: 'Milch',
      unit: 'Packung',
      group: 'milch',
    );
    final quote = shoppingQuotes(
      ListItem(product: genericMilk),
      prices: const [],
      offers: [
        Offer(
          id: 'current-milk-offer',
          productId: milk.id,
          storeName: 'Lidl',
          originalPrice: 1.29,
          offerPrice: 0.89,
          validUntil: DateTime(2026, 9, 30),
          packageAmount: 1,
          packageUnit: 'l',
        ),
      ],
      catalogProducts: const [milk],
      enabledStores: const ['Lidl'],
      now: DateTime(2026, 9, 24),
    );

    expect(quote, hasLength(1));
    expect(quote.single.kind, ShoppingQuoteKind.offer);
    expect(quote.single.unitPrice, 0.89);
  });

  test('matrix uses shared source precedence for equal adjusted values', () {
    final matrix = shoppingPriceMatrix(
      item,
      prices: [
        MarketPrice(
          productId: milk.id,
          storeName: 'Beispielmarkt',
          price: 1.00,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.openPrices,
        ),
        MarketPrice(
          productId: milk.id,
          storeName: 'Beispielmarkt',
          price: 1.00,
          updatedAt: DateTime(2026, 9, 24),
          source: MarketPriceSource.receipt,
        ),
      ],
      offers: const [],
      enabledStores: const ['Beispielmarkt'],
      now: DateTime(2026, 9, 24),
    );

    expect(matrix.single.quote?.kind, ShoppingQuoteKind.receipt);
  });
}
