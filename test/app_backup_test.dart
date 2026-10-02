import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/named_shopping_list.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/price_point.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_alias.dart';
import 'package:sparzamapp/models/receipt_observation.dart';
import 'package:sparzamapp/models/recent_purchase.dart';
import 'package:sparzamapp/models/road_route_matrix.dart';
import 'package:sparzamapp/services/app_backup.dart';

void main() {
  const milk = Product(
    id: 'milk',
    name: 'Milch 1,5 %',
    unit: '1 l',
    group: 'milch',
    packageAmount: 1,
    packageUnit: 'l',
  );

  AppBackup backup() => AppBackup(
    createdAt: DateTime(2026, 10, 2, 12),
    budget: const BudgetPlan(
      monthlyBudget: 250,
      foodBudget: 180,
      foodSpent: 42,
    ),
    mobility: const MobilitySettings(
      startAddress: 'Zellingen',
      timeValuePerHour: 12,
      enabledStoreNames: ['Lidl', 'PENNY'],
    ),
    priceDataSettings: const PriceDataSettings(
      openPricesEnabled: false,
      openPricesMaxAgeDays: 45,
    ),
    activeShoppingListId: 'default',
    shoppingList: [ListItem(product: milk, quantity: 2, note: 'Bio prüfen')],
    namedLists: [
      NamedShoppingList(
        id: 'default',
        name: 'Woche',
        items: [ListItem(product: milk)],
      ),
    ],
    offers: [
      Offer(
        id: 'offer-1',
        productId: milk.id,
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.89,
        validUntil: DateTime(2026, 10, 5),
        source: 'retailerWebsite',
        proofRef: 'https://example.test/milk',
      ),
    ],
    marketPrices: [
      MarketPrice(
        productId: milk.id,
        storeName: 'PENNY',
        price: 0.99,
        updatedAt: DateTime(2026, 10, 1),
        source: MarketPriceSource.receipt,
      ),
    ],
    customProducts: [milk],
    priceHistory: [
      PricePoint(
        productId: milk.id,
        storeName: 'PENNY',
        price: 0.99,
        date: DateTime(2026, 10, 1),
        source: PricePointSource.receipt,
      ),
    ],
    recentPurchases: [RecentPurchase.fromProduct(milk)],
    purchaseHistory: const [],
    preferredProductByGroup: const {'milch': 'milk'},
    receiptObservations: [
      ReceiptObservation(
        id: 'receipt-row',
        receiptFingerprint: 'receipt',
        rowLine: 4,
        rawLabel: 'Milch 1,5',
        familyKey: 'milch',
        storeName: 'PENNY',
        observedAt: DateTime(2026, 10, 1),
        totalPrice: 0.99,
        quantity: 1,
        quantityUnit: 'l',
        unitPrice: 0.99,
        discounted: false,
        productId: milk.id,
        identityConfirmed: true,
      ),
    ],
    priceObservations: [
      PriceObservation(
        id: 'price-row',
        productId: milk.id,
        storeName: 'PENNY',
        price: 0.99,
        observedAt: DateTime(2026, 10, 1),
        source: PriceObservationSource.receipt,
        quantity: 1,
        unit: 'l',
        proofRef: 'receipt:receipt',
        identityConfidence: 1,
      ),
    ],
    receiptAliases: [
      ReceiptAlias(
        storeName: 'PENNY',
        normalizedLabel: 'milch 1 5',
        productId: milk.id,
        confirmations: 2,
        updatedAt: DateTime(2026, 10, 1),
      ),
    ],
    roadDistances: const {'Lidl': 1.2},
    roadMatrix: const RoadRouteMatrix(
      originAddress: 'Zellingen',
      distancesKm: {'@origin|Lidl': 1.2, 'Lidl|@origin': 1.2},
      fetchedAt: null,
    ),
    knownItems: [RecentPurchase.fromProduct(milk)],
    aisleOrder: const ['milch', 'brot'],
    tileView: false,
  );

  test('round-trips all user data and provenance fields', () {
    final decoded = AppBackup.decode(backup().encode());

    expect(decoded.createdAt, DateTime(2026, 10, 2, 12));
    expect(decoded.budget.foodBudget, 180);
    expect(decoded.mobility.timeValuePerHour, 12);
    expect(decoded.activeShoppingListId, 'default');
    expect(decoded.shoppingList.single.product.id, milk.id);
    expect(decoded.namedLists.single.name, 'Woche');
    expect(decoded.offers.single.proofRef, 'https://example.test/milk');
    expect(decoded.marketPrices.single.source, MarketPriceSource.receipt);
    expect(decoded.priceHistory.single.source, PricePointSource.receipt);
    expect(decoded.receiptObservations.single.identityConfirmed, isTrue);
    expect(decoded.priceObservations.single.proofRef, 'receipt:receipt');
    expect(decoded.receiptAliases.single.confirmations, 2);
    expect(decoded.roadMatrix?.distancesKm['@origin|Lidl'], 1.2);
    expect(decoded.knownItems.single.id, milk.id);
    expect(decoded.aisleOrder, ['milch', 'brot']);
    expect(decoded.tileView, isFalse);
  });

  test('rejects unsupported versions before applying any state', () {
    final json = jsonDecode(backup().encode()) as Map<String, dynamic>;
    json['schemaVersion'] = AppBackup.schemaVersion + 1;

    expect(
      () => AppBackup.decode(jsonEncode(json)),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects malformed numeric backup fields', () {
    final json = jsonDecode(backup().encode()) as Map<String, dynamic>;
    (json['budget'] as Map<String, dynamic>)['foodBudget'] = -1;

    expect(
      () => AppBackup.decode(jsonEncode(json)),
      throwsA(isA<FormatException>()),
    );
  });
}
