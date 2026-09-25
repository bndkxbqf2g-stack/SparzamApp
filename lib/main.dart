import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/budget_store.dart';
import 'services/offer_store.dart';
import 'services/mobility_settings_store.dart';
import 'services/market_price_store.dart';
import 'services/product_catalog_store.dart';
import 'services/price_history_store.dart';
import 'services/price_data_settings_store.dart';
import 'services/recent_purchase_store.dart';
import 'services/purchase_store.dart';
import 'services/shopping_list_store.dart';
import 'services/diagnostic_log_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final diagnosticLogService = DiagnosticLogService();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    diagnosticLogService.record(
      category: 'Flutter',
      message: details.exceptionAsString(),
      details: details.stack?.toString(),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    diagnosticLogService.record(
      category: 'Async',
      message: error.toString(),
      details: stack.toString(),
    );
    return false;
  };

  final budgetStore = BudgetStore();
  final offerStore = OfferStore();
  final mobilityStore = MobilitySettingsStore();
  final marketPriceStore = MarketPriceStore();
  final productCatalogStore = ProductCatalogStore();
  final priceHistoryStore = PriceHistoryStore();
  final priceDataSettingsStore = PriceDataSettingsStore();
  final recentPurchaseStore = RecentPurchaseStore();
  final purchaseStore = PurchaseStore();
  final shoppingListStore = ShoppingListStore();

  runApp(
    SparzamApp(
      budgetStore: budgetStore,
      offerStore: offerStore,
      mobilityStore: mobilityStore,
      marketPriceStore: marketPriceStore,
      productCatalogStore: productCatalogStore,
      priceDataSettingsStore: priceDataSettingsStore,
      priceHistoryStore: priceHistoryStore,
      recentPurchaseStore: recentPurchaseStore,
      purchaseStore: purchaseStore,
      shoppingListStore: shoppingListStore,
      diagnosticLogService: diagnosticLogService,
      initialBudget: await budgetStore.load(),
      initialOffers: await offerStore.load(),
      initialMobility: await mobilityStore.load(),
      initialMarketPrices: await marketPriceStore.load(),
      initialCustomProducts: await productCatalogStore.load(),
      initialPriceHistory: await priceHistoryStore.load(),
      initialPriceDataSettings: await priceDataSettingsStore.load(),
      initialRecentPurchases: await recentPurchaseStore.load(),
      initialPurchaseHistory: await purchaseStore.load(),
      initialShoppingList: await shoppingListStore.load(),
      initialPreferredProductByGroup:
          await shoppingListStore.loadPreferredProducts(),
    ),
  );
}
