import 'package:flutter/material.dart';

import '../../data/products.dart' as base_catalog;
import '../../models/budget_plan.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import '../../models/price_point.dart';
import '../../models/price_data_settings.dart';
import '../../models/recent_purchase.dart';
import '../../models/road_route_matrix.dart';
import '../../models/purchase_record.dart';
import '../../services/budget_store.dart';
import '../../services/offer_store.dart';
import '../../services/mobility_settings_store.dart';
import '../../services/market_price_store.dart';
import '../../services/product_catalog_store.dart';
import '../../services/price_data_settings_store.dart';
import '../../services/open_prices_sync_service.dart';
import '../../services/recent_purchase_store.dart';
import '../../services/purchase_store.dart';
import '../../services/road_distance_store.dart';
import '../../services/road_route_matrix_store.dart';
import '../../services/shopping_list_store.dart';
import '../budget/budget_calculator.dart';
import '../budget/budget_screen.dart';
import '../catalog/product_catalog_screen.dart';
import '../catalog/market_price_freshness.dart';
import '../home/dashboard_data.dart';
import '../home/home_screen.dart';
import '../offers/offers_screen.dart';
import '../profile/mobility_settings_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/price_data_settings_screen.dart';
import '../profile/store_selection_screen.dart';
import '../receipt/receipt_screen.dart';
import '../receipt/purchase_summary.dart';
import '../route/route_optimizer.dart';
import '../route/route_screen.dart';
import '../route/travel_estimator.dart';
import '../scanner/scanner_screen.dart';
import '../shopping_list/shopping_list_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.budgetStore,
    required this.offerStore,
    required this.mobilityStore,
    required this.marketPriceStore,
    required this.productCatalogStore,
    required this.priceDataSettingsStore,
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
  });

  final BudgetStore budgetStore;
  final OfferStore offerStore;
  final MobilitySettingsStore mobilityStore;
  final MarketPriceStore marketPriceStore;
  final ProductCatalogStore productCatalogStore;
  final PriceDataSettingsStore priceDataSettingsStore;
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

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;
  late BudgetPlan budget;
  late MobilitySettings mobility;
  late List<ListItem> shoppingList;
  late List<Offer> offers;
  late List<RecentPurchase> recentPurchases;
  late List<PurchaseRecord> purchaseHistory;
  late List<Product> customProducts;
  late List<MarketPrice> marketPrices;
  late PriceDataSettings priceDataSettings;
  Map<String, double> roadDistances = <String, double>{};
  final roadDistanceStore = RoadDistanceStore();
  final roadRouteMatrixStore = RoadRouteMatrixStore();
  RoadRouteMatrix? roadMatrix;
  late final Map<String, String> preferredProductByGroup;

  Product? _catalogProduct(String id) {
    final matches = [
      ...base_catalog.products,
      ...customProducts,
    ].where((product) => product.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  void initState() {
    super.initState();
    budget = widget.initialBudget;
    mobility = widget.initialMobility;
    customProducts = [...widget.initialCustomProducts];
    marketPrices = [...widget.initialMarketPrices];
    priceDataSettings = widget.initialPriceDataSettings;
    shoppingList = widget.initialShoppingList
        .map(
          (item) => ListItem(
            product: _catalogProduct(item.product.id) ?? item.product,
            quantity: item.quantity,
          ),
        )
        .toList();
    offers = [...widget.initialOffers];
    recentPurchases = [...widget.initialRecentPurchases];
    purchaseHistory = [...widget.initialPurchaseHistory];
    preferredProductByGroup = {...widget.initialPreferredProductByGroup};
    _loadRoadDistances();
  }

  Future<void> _loadRoadDistances() async {
    final loaded = await roadDistanceStore.load(mobility.startAddress);
    final matrix = await roadRouteMatrixStore.load(mobility.startAddress);
    if (!mounted) return;
    setState(() {
      roadDistances = loaded;
      roadMatrix = matrix;
    });
  }

  List<Product> get catalogProducts => [
        ...base_catalog.products,
        ...customProducts,
      ];

  bool isBaseProduct(String id) =>
      base_catalog.products.any((product) => product.id == id);

  List<MarketPrice> get activeMarketPrices {
    if (!priceDataSettings.openPricesEnabled) {
      return marketPrices
          .where((price) => price.source == MarketPriceSource.manual)
          .toList(growable: false);
    }
    return usableMarketPrices(
      marketPrices,
      openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
    );
  }

  Future<void> persistShoppingList() =>
      widget.shoppingListStore.save(shoppingList);

  Future<void> ensureCatalogProduct(Product product) async {
    if (isBaseProduct(product.id) ||
        customProducts.any((item) => item.id == product.id)) {
      return;
    }
    final next = await widget.productCatalogStore.upsert(
      product,
      customProducts,
    );
    if (mounted) setState(() => customProducts = next);
  }

  void addProduct(Product product) {
    setState(() {
      for (final item in shoppingList) {
        if (item.product.id == product.id) {
          item.quantity++;
          return;
        }
      }
      shoppingList.add(ListItem(product: product));
    });
    persistShoppingList();
    widget.shoppingListStore.saveKnownItem(product);
    ensureCatalogProduct(product);
  }

  Future<void> openScanner() async {
    final learned = await widget.shoppingListStore.loadKnownItems();
    if (!mounted) return;

    final seen = <String>{};
    final scannerProducts = <Product>[
      ...catalogProducts,
      ...learned.map((item) => item.toProduct()),
    ].where((product) => seen.add(product.id)).toList();

    final product = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => ScannerScreen(
          learnedProducts: scannerProducts,
        ),
      ),
    );
    if (product != null) addProduct(product);
  }

  Future<void> markPurchased(Product product, int quantity) async {
    final next = await widget.recentPurchaseStore.add(product, quantity, recentPurchases);
    await widget.shoppingListStore.savePreferredProduct(product.group, product.id);
    setState(() {
      preferredProductByGroup[product.group] = product.id;
      recentPurchases = next;
    });
  }

  void changeQuantity(String productId, int delta) {
    setState(() {
      final index = shoppingList.indexWhere((item) => item.product.id == productId);
      if (index < 0) return;
      shoppingList[index].quantity += delta;
      if (shoppingList[index].quantity <= 0) shoppingList.removeAt(index);
    });
    persistShoppingList();
  }

  void clearPurchasedItems(Set<String> productIds) {
    if (productIds.isEmpty) return;
    setState(() => shoppingList.removeWhere((item) => productIds.contains(item.product.id)));
    persistShoppingList();
  }

  RouteOptimizer? get currentOptimizer => shoppingList.isEmpty
      ? null
      : RouteOptimizer(
          shoppingList,
          offers,
          roadDistances: roadDistances,
          euroPerKm: mobility.effectiveEuroPerKm,
          maxStores: mobility.maxStores,
          minExtraStoreSavings: mobility.minExtraStoreSavings,
          enabledStoreNames: mobility.enabledStoreNames,
          marketPrices: activeMarketPrices,
          roadMatrix: mobility.mode == MobilityMode.car ? roadMatrix : null,
        );

  RouteOptimizer? get regularOptimizer => shoppingList.isEmpty
      ? null
      : RouteOptimizer(
          shoppingList,
          const <Offer>[],
          roadDistances: roadDistances,
          euroPerKm: mobility.effectiveEuroPerKm,
          maxStores: mobility.maxStores,
          minExtraStoreSavings: mobility.minExtraStoreSavings,
          enabledStoreNames: mobility.enabledStoreNames,
          marketPrices: activeMarketPrices,
          roadMatrix: mobility.mode == MobilityMode.car ? roadMatrix : null,
        );

  DashboardData dashboardData() {
    final best = currentOptimizer?.bestPlan();
    final baseline = regularOptimizer?.bestSingleStorePlan();
    final savings = best == null || baseline == null ? 0.0 : baseline.total - best.total;
    final travel = best == null
        ? const TravelEstimate(distanceKm: 0, minutes: 0)
        : estimateRoundTrips(
            best.stores,
            mobility: mobility,
            roadDistances: roadDistances,
            roadMatrix: mobility.mode == MobilityMode.car ? roadMatrix : null,
          );
    final planned = best?.basket ?? 0;
    final snapshot = calculateBudget(budget, planned);
    final monthly = summarizeMonth(purchaseHistory);
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final activeOffers = offers.where((offer) => !offer.validUntil.isBefore(day)).length;

    return DashboardData(
      itemCount: shoppingList.length,
      activeOffers: activeOffers,
      routeNames: best == null ? 'Noch keine Route' : best.stores.map((store) => store.name).join(' + '),
      routeTotal: best?.total ?? 0,
      routeTravelMinutes: travel.minutes,
      mobilityLabel: mobility.mode.label,
      todaySavings: savings > 0 ? savings : 0,
      monthlySavings: monthly.savings,
      monthlyPurchases: monthly.purchases,
      budgetRemaining: snapshot.afterPlannedShop,
      budgetConfigured: budget.isConfigured,
    );
  }

  Future<void> completePurchase() async {
    final plan = currentOptimizer?.bestPlan();
    final baseline = regularOptimizer?.bestSingleStorePlan();
    if (plan == null || baseline == null || shoppingList.isEmpty) return;

    final record = PurchaseRecord.fromPlan(
      plan: plan,
      baselineTotal: baseline.total,
      items: shoppingList,
    );
    final nextHistory = await widget.purchaseStore.add(record, purchaseHistory);
    final nextBudget = budget.copyWith(foodSpent: budget.foodSpent + plan.basket);
    await widget.budgetStore.save(nextBudget);
    await widget.shoppingListStore.clear();

    if (!mounted) return;
    setState(() {
      purchaseHistory = nextHistory;
      budget = nextBudget;
      shoppingList.clear();
    });
  }

  Future<List<Product>> saveCatalogProduct(Product product) async {
    final next = await widget.productCatalogStore.upsert(
      product,
      customProducts,
    );

    final listIndex =
        shoppingList.indexWhere((item) => item.product.id == product.id);
    if (listIndex >= 0) {
      final quantity = shoppingList[listIndex].quantity;
      shoppingList[listIndex] = ListItem(
        product: product,
        quantity: quantity,
      );
      await persistShoppingList();
    }

    await widget.shoppingListStore.saveKnownItem(product);
    if (mounted) setState(() => customProducts = next);
    return next;
  }

  Future<List<Product>> deleteCatalogProduct(Product product) async {
    final next = await widget.productCatalogStore.remove(
      product.id,
      customProducts,
    );
    final nextPrices = await widget.marketPriceStore.removeProduct(
      product.id,
      marketPrices,
    );

    var nextOffers = offers;
    for (final offer
        in offers.where((item) => item.productId == product.id).toList()) {
      nextOffers = await widget.offerStore.remove(offer.id, nextOffers);
    }

    shoppingList.removeWhere((item) => item.product.id == product.id);
    preferredProductByGroup.removeWhere((_, id) => id == product.id);
    await persistShoppingList();
    await widget.shoppingListStore.removeKnownItem(product.id);
    await widget.shoppingListStore.removePreferredProduct(
      product.group,
      product.id,
    );

    if (mounted) {
      setState(() {
        customProducts = next;
        marketPrices = nextPrices;
        offers = nextOffers;
      });
    }
    return next;
  }

  Future<List<MarketPrice>> saveMarketPrice(MarketPrice price) async {
    final next = await widget.marketPriceStore.upsert(price, marketPrices);
    if (mounted) setState(() => marketPrices = next);
    return next;
  }

  Future<List<MarketPrice>> deleteMarketPrice(
    String productId,
    String storeName,
  ) async {
    final next = await widget.marketPriceStore.remove(
      productId,
      storeName,
      marketPrices,
    );
    if (mounted) setState(() => marketPrices = next);
    return next;
  }

  Future<List<MarketPrice>> syncOpenPrices() async {
    if (!priceDataSettings.openPricesEnabled) return marketPrices;

    final result = await const OpenPricesSyncService().sync(
      products: catalogProducts,
      maxAgeDays: priceDataSettings.openPricesMaxAgeDays,
    );

    var next = marketPrices;
    for (final price in result.prices) {
      next = await widget.marketPriceStore.upsert(price, next);
    }

    if (mounted) setState(() => marketPrices = next);
    return next;
  }

  Future<void> openPriceDataSettings() async {
    final result = await Navigator.of(context).push<PriceDataSettings>(
      MaterialPageRoute(
        builder: (_) => PriceDataSettingsScreen(
          initialSettings: priceDataSettings,
        ),
      ),
    );
    if (result == null) return;

    await widget.priceDataSettingsStore.save(result);
    if (!mounted) return;
    setState(() => priceDataSettings = result);
  }

  Future<void> openCatalog() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProductCatalogScreen(
          customProducts: customProducts,
          marketPrices: marketPrices,
          onSaveProduct: saveCatalogProduct,
          onDeleteProduct: deleteCatalogProduct,
          onSavePrice: saveMarketPrice,
          onDeletePrice: deleteMarketPrice,
          priceDataSettings: priceDataSettings,
          onSyncOpenPrices: syncOpenPrices,
        ),
      ),
    );
  }

  Future<List<Offer>> saveOffer(Offer offer) async {
    final next = await widget.offerStore.upsert(offer, offers);
    if (mounted) setState(() => offers = next);
    return next;
  }

  Future<List<Offer>> deleteOffer(Offer offer) async {
    final next = await widget.offerStore.remove(offer.id, offers);
    if (mounted) setState(() => offers = next);
    return next;
  }

  Future<void> openMobilitySettings() async {
    final result = await Navigator.of(context).push<MobilitySettings>(
      MaterialPageRoute(
        builder: (_) => MobilitySettingsScreen(initialSettings: mobility),
      ),
    );
    if (result == null) return;

    await widget.mobilityStore.save(result);
    final loaded = await roadDistanceStore.load(result.startAddress);
    final matrix = await roadRouteMatrixStore.load(result.startAddress);
    if (!mounted) return;
    setState(() {
      mobility = result;
      roadDistances = loaded;
      roadMatrix = matrix;
    });
  }

  Future<void> openStoreSettings() async {
    final result = await Navigator.of(context).push<MobilitySettings>(
      MaterialPageRoute(
        builder: (_) => StoreSelectionScreen(initialSettings: mobility),
      ),
    );
    if (result == null) return;

    await widget.mobilityStore.save(result);
    if (!mounted) return;
    setState(() => mobility = result);
  }

  void openBudget() {
    final best = shoppingList.isEmpty
        ? null
        : RouteOptimizer(
            shoppingList,
            offers,
            roadDistances: roadDistances,
            euroPerKm: mobility.effectiveEuroPerKm,
          maxStores: mobility.maxStores,
          minExtraStoreSavings: mobility.minExtraStoreSavings,
          enabledStoreNames: mobility.enabledStoreNames,
          marketPrices: activeMarketPrices,
          roadMatrix: mobility.mode == MobilityMode.car ? roadMatrix : null,
          ).bestPlan();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BudgetScreen(
          initialPlan: budget,
          store: widget.budgetStore,
          plannedShop: best?.basket ?? 0,
          onChanged: (value) => setState(() => budget = value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        data: dashboardData(),
        onOpenList: () => setState(() => selectedIndex = 1),
        onOpenRoute: () => setState(() => selectedIndex = 2),
        onOpenOffers: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OffersScreen(
              offers: offers,
              priceHistory: widget.initialPriceHistory,
              onSave: saveOffer,
              onDelete: deleteOffer,
              catalogProducts: catalogProducts,
            ),
          ),
        ),
        onOpenBudget: openBudget,
        onOpenScanner: openScanner,
      ),
      ShoppingListScreen(
        items: shoppingList,
        onAdd: addProduct,
        onChangeQuantity: changeQuantity,
        preferredProductByGroup: preferredProductByGroup,
        recentPurchases: recentPurchases,
        onPurchased: markPurchased,
        onClearPurchased: clearPurchasedItems,
        shoppingListStore: widget.shoppingListStore,
        onOpenScanner: openScanner,
        offers: offers,
        priceHistory: widget.initialPriceHistory,
        mobility: mobility,
        catalogProducts: catalogProducts,
        marketPrices: activeMarketPrices,
      ),
      RouteScreen(
        items: shoppingList,
        offers: offers,
        mobility: mobility,
        marketPrices: activeMarketPrices,
        onRoadDistancesChanged: (value) =>
            setState(() => roadDistances = value),
        onRoadMatrixChanged: (value) =>
            setState(() => roadMatrix = value),
      ),
      ReceiptScreen(
        plan: currentOptimizer?.bestPlan(),
        baselineTotal: regularOptimizer?.bestSingleStorePlan()?.total ?? 0,
        history: purchaseHistory,
        onComplete: completePurchase,
      ),
      ProfileScreen(
        mobility: mobility,
        onEditMobility: openMobilitySettings,
        onEditStores: openStoreSettings,
        storeCount: mobility.enabledStoreNames.isEmpty
            ? 7
            : mobility.enabledStoreNames.length,
        onOpenCatalog: openCatalog,
        productCount: catalogProducts.length,
        onEditPriceData: openPriceDataSettings,
        priceDataSummary: priceDataSettings.openPricesEnabled
            ? 'Open Prices · max. ${priceDataSettings.openPricesMaxAgeDays} Tage'
            : 'Nur eigene Preise',
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Liste'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Route'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Bon'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
