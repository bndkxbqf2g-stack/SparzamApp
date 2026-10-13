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

  // These stores use independent keys. Start all initial reads before the
  // first await so a slow local backend (or a repaired legacy entry) does not
  // serialize the whole app startup. The futures are still awaited below,
  // therefore the first frame receives one consistent initial snapshot.
  final initialBudgetFuture = budgetStore.load();
  final initialOffersFuture = offerStore.load();
  final initialMobilityFuture = mobilityStore.load();
  final initialMarketPricesFuture = marketPriceStore.load();
  final initialCustomProductsFuture = productCatalogStore.load();
  final initialPriceHistoryFuture = priceHistoryStore.load();
  final initialPriceDataSettingsFuture = priceDataSettingsStore.load();
  final initialRecentPurchasesFuture = recentPurchaseStore.load();
  final initialPurchaseHistoryFuture = purchaseStore.load();
  final initialShoppingListFuture = shoppingListStore.load();
  final initialPreferredProductsFuture =
      shoppingListStore.loadPreferredProducts();

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
      initialBudget: await initialBudgetFuture,
      initialOffers: await initialOffersFuture,
      initialMobility: await initialMobilityFuture,
      initialMarketPrices: await initialMarketPricesFuture,
      initialCustomProducts: await initialCustomProductsFuture,
      initialPriceHistory: await initialPriceHistoryFuture,
      initialPriceDataSettings: await initialPriceDataSettingsFuture,
      initialRecentPurchases: await initialRecentPurchasesFuture,
      initialPurchaseHistory: await initialPurchaseHistoryFuture,
      initialShoppingList: await initialShoppingListFuture,
      initialPreferredProductByGroup: await initialPreferredProductsFuture,
    ),
  );
}
