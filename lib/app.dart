import 'package:flutter/material.dart';

import 'features/shell/app_shell.dart';
import 'models/budget_plan.dart';
import 'models/list_item.dart';
import 'models/market_price.dart';
import 'models/mobility_settings.dart';
import 'models/offer.dart';
import 'models/price_point.dart';
import 'models/price_data_settings.dart';
import 'models/product.dart';
import 'models/recent_purchase.dart';
import 'models/purchase_record.dart';
import 'services/budget_store.dart';
import 'services/offer_store.dart';
import 'services/mobility_settings_store.dart';
import 'services/market_price_store.dart';
import 'services/product_catalog_store.dart';
import 'services/price_data_settings_store.dart';
import 'services/price_history_store.dart';
import 'services/recent_purchase_store.dart';
import 'services/purchase_store.dart';
import 'services/shopping_list_store.dart';
import 'services/diagnostic_log_service.dart';

class SparzamApp extends StatelessWidget {
  const SparzamApp({
    super.key,
    required this.budgetStore,
    required this.offerStore,
    required this.mobilityStore,
    required this.marketPriceStore,
    required this.productCatalogStore,
    required this.priceDataSettingsStore,
    required this.priceHistoryStore,
    required this.recentPurchaseStore,
    required this.purchaseStore,
    required this.shoppingListStore,
    required this.initialBudget,
    required this.initialOffers,
    required this.initialMobility,
    required this.initialMarketPrices,
    required this.initialCustomProducts,
    required this.initialPriceHistory,
    required this.initialPriceDataSettings,
    required this.initialRecentPurchases,
    required this.initialPurchaseHistory,
    required this.initialShoppingList,
    required this.initialPreferredProductByGroup,
    required this.diagnosticLogService,
  });

  final BudgetStore budgetStore;
  final OfferStore offerStore;
  final MobilitySettingsStore mobilityStore;
  final MarketPriceStore marketPriceStore;
  final ProductCatalogStore productCatalogStore;
  final PriceDataSettingsStore priceDataSettingsStore;
  final PriceHistoryStore priceHistoryStore;
  final RecentPurchaseStore recentPurchaseStore;
  final PurchaseStore purchaseStore;
  final ShoppingListStore shoppingListStore;
  final BudgetPlan initialBudget;
  final List<Offer> initialOffers;
  final MobilitySettings initialMobility;
  final List<MarketPrice> initialMarketPrices;
  final List<Product> initialCustomProducts;
  final List<PricePoint> initialPriceHistory;
  final PriceDataSettings initialPriceDataSettings;
  final List<RecentPurchase> initialRecentPurchases;
  final List<PurchaseRecord> initialPurchaseHistory;
  final List<ListItem> initialShoppingList;
  final Map<String, String> initialPreferredProductByGroup;
  final DiagnosticLogService diagnosticLogService;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF155EEF);

    return MaterialApp(
      title: 'sparzamApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
      home: AppShell(
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
        initialBudget: initialBudget,
        initialOffers: initialOffers,
        initialMobility: initialMobility,
        initialMarketPrices: initialMarketPrices,
        initialCustomProducts: initialCustomProducts,
        initialPriceHistory: initialPriceHistory,
        initialPriceDataSettings: initialPriceDataSettings,
        initialRecentPurchases: initialRecentPurchases,
        initialPurchaseHistory: initialPurchaseHistory,
        initialShoppingList: initialShoppingList,
        initialPreferredProductByGroup: initialPreferredProductByGroup,
        diagnosticLogService: diagnosticLogService,
      ),
    );
  }
}
