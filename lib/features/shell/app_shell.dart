import 'package:flutter/material.dart';

import '../../models/budget_plan.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/named_shopping_list.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import '../../models/price_point.dart';
import '../../models/price_data_settings.dart';
import '../../models/price_sync_result.dart';
import '../../models/recent_purchase.dart';
import '../../models/replenishment_suggestion.dart';
import '../../models/road_route_matrix.dart';
import '../../models/purchase_record.dart';
import '../../services/budget_store.dart';
import '../../services/offer_store.dart';
import '../../services/mobility_settings_store.dart';
import '../../services/market_price_store.dart';
import '../../services/product_catalog_store.dart';
import '../../services/price_data_settings_store.dart';
import '../../services/price_history_store.dart';
import '../../services/recent_purchase_store.dart';
import '../../services/purchase_store.dart';
import '../../services/road_distance_store.dart';
import '../../services/road_route_matrix_store.dart';
import '../../services/shopping_list_store.dart';
import '../../services/sequential_write_queue.dart';
import '../../services/diagnostic_log_service.dart';
import '../budget/budget_screen.dart';
import '../catalog/product_catalog_screen.dart';
import '../home/dashboard_data.dart';
import '../profile/mobility_settings_screen.dart';
import '../profile/price_data_settings_screen.dart';
import '../profile/store_selection_screen.dart';
import '../profile/diagnostic_log_screen.dart';
import '../route/route_optimizer.dart';
import '../scanner/scanner_screen.dart';
import '../shopping_list/replenishment_analyzer.dart';
import '../shopping_list/shopping_list_updates.dart';
import 'shell_catalog.dart';
import 'shell_catalog_coordinator.dart';
import 'shell_routing.dart';
import 'shell_dashboard.dart';
import 'shell_navigation.dart';
import 'shell_pages.dart';
import 'shell_pricing.dart';
import 'shell_purchase_coordinator.dart';
import 'shell_price_coordinator.dart';

class AppShell extends StatefulWidget {
  const AppShell({
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
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // The primary task is adding items. Open the app on the list, like Bring.
  int selectedIndex = 1;
  late BudgetPlan budget;
  late MobilitySettings mobility;
  late List<ListItem> shoppingList;
  late List<NamedShoppingList> namedShoppingLists;
  String activeShoppingListId = 'default';
  late List<Offer> offers;
  late List<RecentPurchase> recentPurchases;
  late List<PurchaseRecord> purchaseHistory;
  late List<Product> customProducts;
  late List<MarketPrice> marketPrices;
  late PriceDataSettings priceDataSettings;
  late List<PricePoint> priceHistory;
  Map<String, double> roadDistances = <String, double>{};
  final roadDistanceStore = RoadDistanceStore();
  final roadRouteMatrixStore = RoadRouteMatrixStore();
  RoadRouteMatrix? roadMatrix;
  late Map<String, String> preferredProductByGroup;
  final _shoppingListSaves = SequentialWriteQueue();
  bool _purchaseInProgress = false;

  Product? _catalogProduct(String id) {
    return catalogProductById(id, customProducts);
  }

  @override
  void initState() {
    super.initState();
    budget = widget.initialBudget;
    mobility = widget.initialMobility;
    customProducts = [...widget.initialCustomProducts];
    marketPrices = [...widget.initialMarketPrices];
    priceDataSettings = widget.initialPriceDataSettings;
    priceHistory = [...widget.initialPriceHistory];
    shoppingList = widget.initialShoppingList
        .map(
          (item) => ListItem(
            product: _catalogProduct(item.product.id) ?? item.product,
            quantity: item.quantity,
          ),
        )
        .toList();
    namedShoppingLists = [
      NamedShoppingList(
        id: activeShoppingListId,
        name: 'Einkauf',
        items: _copyItems(shoppingList),
      ),
    ];
    offers = [...widget.initialOffers];
    recentPurchases = [...widget.initialRecentPurchases];
    purchaseHistory = [...widget.initialPurchaseHistory];
    preferredProductByGroup = {...widget.initialPreferredProductByGroup};
    _loadRoadDistances();
    _loadNamedShoppingLists();
  }

  List<ListItem> _copyItems(List<ListItem> items) => items
      .map((item) => ListItem(product: item.product, quantity: item.quantity))
      .toList();

  Future<void> _loadNamedShoppingLists() async {
    final loaded = await widget.shoppingListStore.loadNamedLists();
    if (!mounted) return;
    if (loaded.isEmpty) {
      await widget.shoppingListStore.saveNamedLists(namedShoppingLists);
      return;
    }
    setState(() {
      namedShoppingLists = loaded;
      activeShoppingListId = loaded.first.id;
      shoppingList = _copyItems(loaded.first.items);
    });
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

  List<Product> get catalogProducts => buildCatalogProducts(customProducts);

  bool isBaseProduct(String id) => isBaseCatalogProduct(id);

  List<MarketPrice> get activeMarketPrices =>
      activePrices(marketPrices, priceDataSettings);

  List<ReplenishmentSuggestion> get replenishmentSuggestions =>
      buildReplenishmentSuggestions(
        history: purchaseHistory,
        catalogProducts: catalogProducts,
        currentListProductIds:
            shoppingList.map((item) => item.product.id).toSet(),
      );

  Future<void> persistShoppingList() {
    final snapshot = [
      for (final item in shoppingList)
        ListItem(product: item.product, quantity: item.quantity),
    ];
    final lists = namedShoppingLists
        .map((list) => list.id == activeShoppingListId
            ? NamedShoppingList(
                id: list.id,
                name: list.name,
                items: _copyItems(snapshot),
              )
            : list)
        .toList();
    namedShoppingLists = lists;
    return _shoppingListSaves.add(() async {
      await widget.shoppingListStore.save(snapshot);
      await widget.shoppingListStore.saveNamedLists(lists);
    });
  }

  Future<void> selectShoppingList(String id) async {
    if (id == activeShoppingListId) return;
    await persistShoppingList();
    final matches = namedShoppingLists.where((list) => list.id == id);
    final selected = matches.isEmpty ? null : matches.first;
    if (!mounted || selected == null) return;
    setState(() {
      activeShoppingListId = selected.id;
      shoppingList = _copyItems(selected.items);
    });
    await widget.shoppingListStore.save(shoppingList);
    widget.diagnosticLogService.record(
      category: 'Einkaufsliste',
      message: 'Liste gewechselt.',
      details: selected.name,
    );
  }

  Future<void> createShoppingList(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await persistShoppingList();
    final created = NamedShoppingList(
      id: 'list_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      items: <ListItem>[],
    );
    if (!mounted) return;
    setState(() {
      namedShoppingLists = [...namedShoppingLists, created];
      activeShoppingListId = created.id;
      shoppingList = <ListItem>[];
    });
    await widget.shoppingListStore.saveNamedLists(namedShoppingLists);
    await widget.shoppingListStore.save(shoppingList);
    widget.diagnosticLogService.record(
      category: 'Einkaufsliste',
      message: 'Neue Liste erstellt.',
      details: trimmed,
    );
  }

  void persistShoppingListWithFeedback() {
    persistShoppingList().catchError((Object error) {
      widget.diagnosticLogService.record(
        category: 'Einkaufsliste',
        message: 'Einkaufsliste konnte nicht gespeichert werden.',
        details: error.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Einkaufsliste konnte nicht gespeichert werden.')),
        );
      }
    });
  }

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
    setState(() => shoppingList = addShoppingProduct(shoppingList, product));
    persistShoppingListWithFeedback();
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
    if (mounted && product != null) addProduct(product);
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
    persistShoppingListWithFeedback();
  }

  void clearPurchasedItems(Set<String> productIds) {
    if (productIds.isEmpty) return;
    setState(() => shoppingList.removeWhere((item) => productIds.contains(item.product.id)));
    persistShoppingListWithFeedback();
  }

  ShellRouting get routing => ShellRouting(
        items: shoppingList,
        offers: offers,
        mobility: mobility,
        marketPrices: activeMarketPrices,
        roadDistances: roadDistances,
        roadMatrix: roadMatrix,
      );

  RouteOptimizer? get currentOptimizer => routing.current;

  RouteOptimizer? get regularOptimizer => routing.regular;

  ShellPurchaseCoordinator get purchaseCoordinator =>
      ShellPurchaseCoordinator(
        budgetStore: widget.budgetStore,
        purchaseStore: widget.purchaseStore,
        shoppingListStore: widget.shoppingListStore,
      );

  ShellPriceCoordinator get priceCoordinator => ShellPriceCoordinator(
        marketPriceStore: widget.marketPriceStore,
        priceHistoryStore: widget.priceHistoryStore,
      );

  ShellCatalogCoordinator get catalogCoordinator => ShellCatalogCoordinator(
        productCatalogStore: widget.productCatalogStore,
        shoppingListStore: widget.shoppingListStore,
        marketPriceStore: widget.marketPriceStore,
        priceHistoryStore: widget.priceHistoryStore,
        offerStore: widget.offerStore,
      );

  DashboardData dashboardData() => buildShellDashboard(
        shoppingList: shoppingList,
        offers: offers,
        mobility: mobility,
        roadDistances: roadDistances,
        roadMatrix: roadMatrix,
        routing: routing,
        budget: budget,
        purchaseHistory: purchaseHistory,
        replenishment: replenishmentSuggestions,
      );

  Future<void> completePurchase() async {
    if (_purchaseInProgress) return;
    final plan = currentOptimizer?.bestPlan();
    final baseline = regularOptimizer?.bestSingleStorePlan();
    if (plan == null || baseline == null || shoppingList.isEmpty) return;
    _purchaseInProgress = true;
    try {
      await _shoppingListSaves.pending;
      final result = await purchaseCoordinator.complete(
        plan: plan,
        baselineTotal: baseline.total,
        items: shoppingList,
        history: purchaseHistory,
        budget: budget,
      );

      if (!mounted) return;
      setState(() {
        purchaseHistory = result.history;
        budget = result.budget;
        shoppingList.clear();
      });
      await persistShoppingList();
    } finally {
      _purchaseInProgress = false;
    }
  }

  Future<void> updatePurchase(PurchaseRecord record) async {
    final result = await purchaseCoordinator.update(
      record: record,
      history: purchaseHistory,
      budget: budget,
    );
    if (!mounted) return;
    setState(() {
      purchaseHistory = result.history;
      budget = result.budget;
    });
  }

  Future<void> deletePurchase(PurchaseRecord record) async {
    final result = await purchaseCoordinator.delete(
      record: record,
      history: purchaseHistory,
      budget: budget,
    );

    if (!mounted) return;
    setState(() {
      purchaseHistory = result.history;
      budget = result.budget;
    });
  }

  Future<List<Product>> saveCatalogProduct(Product product) async {
    final result = await catalogCoordinator.save(
      product: product,
      products: customProducts,
      shoppingList: shoppingList,
    );
    if (mounted) {
      setState(() {
        customProducts = result.products;
        shoppingList = result.shoppingList;
      });
    }
    return result.products;
  }

  Future<List<Product>> deleteCatalogProduct(Product product) async {
    final result = await catalogCoordinator.delete(
      product: product,
      products: customProducts,
      prices: marketPrices,
      priceHistory: priceHistory,
      offers: offers,
      shoppingList: shoppingList,
      preferredProductByGroup: preferredProductByGroup,
    );
    if (mounted) {
      setState(() {
        customProducts = result.products;
        marketPrices = result.prices;
        priceHistory = result.priceHistory;
        offers = result.offers;
        shoppingList = result.shoppingList;
        preferredProductByGroup = result.preferredProductByGroup;
      });
    }
    return result.products;
  }

  Future<List<MarketPrice>> saveMarketPrice(MarketPrice price) async {
    final result = await priceCoordinator.save(
      price: price,
      prices: marketPrices,
      history: priceHistory,
    );
    if (mounted) {
      setState(() {
        marketPrices = result.prices;
        priceHistory = result.history;
      });
    }
    widget.diagnosticLogService.record(
      category: 'Preisdaten',
      message: price.source == MarketPriceSource.receipt
          ? 'Kassenbonpreis gespeichert.'
          : 'Preis gespeichert.',
      details: '${price.storeName} · ${price.productId} · ${price.price.toStringAsFixed(2)} €',
    );
    return result.prices;
  }

  Future<List<MarketPrice>> deleteMarketPrice(
    String productId,
    String storeName,
  ) async {
    final next = await priceCoordinator.delete(
      productId: productId,
      storeName: storeName,
      prices: marketPrices,
    );
    if (mounted) setState(() => marketPrices = next);
    return next;
  }

  Future<PriceSyncResult> syncOpenPrices({
    void Function(int processed, int total)? onProgress,
    bool Function()? shouldCancel,
    List<String>? retryProductIds,
  }) async {
    if (!priceDataSettings.openPricesEnabled) {
      return PriceSyncResult(
        prices: marketPrices,
        history: priceHistory,
        productsChecked: 0,
        productsWithEan: 0,
        pricesFound: 0,
        productsProcessed: 0,
        cancelled: false,
      );
    }

    final retryIds = retryProductIds?.toSet();
    late PriceSyncResult result;
    try {
      result = await priceCoordinator.syncOpenPrices(
        products: retryIds == null
            ? catalogProducts
            : catalogProducts
                .where((product) => retryIds.contains(product.id))
                .toList(),
        maxAgeDays: priceDataSettings.openPricesMaxAgeDays,
        prices: marketPrices,
        history: priceHistory,
        onProgress: onProgress,
        shouldCancel: shouldCancel,
      );
    } catch (error) {
      widget.diagnosticLogService.record(
        category: 'Open Prices',
        message: 'Preisabgleich fehlgeschlagen.',
        details: error.toString(),
      );
      rethrow;
    }

    if (mounted) {
      setState(() {
        marketPrices = result.prices;
        priceHistory = result.history;
      });
    }
    widget.diagnosticLogService.record(
      category: 'Open Prices',
      message: result.cancelled
          ? 'Preisabgleich abgebrochen.'
          : 'Preisabgleich abgeschlossen.',
      details: '${result.productsProcessed}/${result.productsWithEan} Produkte · '
          '${result.pricesFound} Preise · '
          '${result.failedProductIds.length} Fehler',
    );
    return result;
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

  void openDiagnostics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiagnosticLogScreen(service: widget.diagnosticLogService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = buildShellPages(
      dashboard: dashboardData(),
      onOpenList: () => setState(() => selectedIndex = 1),
      onOpenRoute: () => setState(() => selectedIndex = 3),
      onOpenOffers: () => setState(() => selectedIndex = 2),
      onOpenBudget: openBudget,
      onOpenScanner: openScanner,
      shoppingList: shoppingList,
      shoppingLists: namedShoppingLists,
      activeShoppingListId: activeShoppingListId,
      onSelectShoppingList: selectShoppingList,
      onCreateShoppingList: createShoppingList,
      onAddProduct: addProduct,
      onChangeQuantity: changeQuantity,
      preferredProductByGroup: preferredProductByGroup,
      recentPurchases: recentPurchases,
      onPurchased: markPurchased,
      onClearPurchased: clearPurchasedItems,
      shoppingListStore: widget.shoppingListStore,
      offers: offers,
      priceHistory: priceHistory,
      mobility: mobility,
      catalogProducts: catalogProducts,
      marketPrices: activeMarketPrices,
      replenishmentSuggestions: replenishmentSuggestions,
      onRoadDistancesChanged: (value) => setState(() => roadDistances = value),
      onRoadMatrixChanged: (value) => setState(() => roadMatrix = value),
      currentPlan: currentOptimizer?.bestPlan(),
      baselineTotal: regularOptimizer?.bestSingleStorePlan()?.total ?? 0,
      purchaseHistory: purchaseHistory,
      onCompletePurchase: completePurchase,
      onUpdatePurchase: updatePurchase,
      onDeletePurchase: deletePurchase,
      onEditMobility: openMobilitySettings,
      onEditStores: openStoreSettings,
      storeCount: mobility.enabledStoreNames.isEmpty
          ? 7
          : mobility.enabledStoreNames.length,
      onOpenCatalog: openCatalog,
      onEditPriceData: openPriceDataSettings,
      onSavePrice: saveMarketPrice,
      onSaveOffer: saveOffer,
      onDeleteOffer: deleteOffer,
      priceDataSummary: priceDataSettings.openPricesEnabled
          ? 'Open Prices · max. ${priceDataSettings.openPricesMaxAgeDays} Tage'
          : 'Nur eigene Preise',
      onOpenDiagnostics: openDiagnostics,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('sparzamApp')),
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: shellDestinations,
      ),
    );
  }
}
