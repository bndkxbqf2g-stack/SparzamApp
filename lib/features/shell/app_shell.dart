import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/stores.dart';
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
import '../../models/price_observation.dart';
import '../../models/recent_purchase.dart';
import '../../models/replenishment_suggestion.dart';
import '../../models/receipt_observation.dart';
import '../../models/road_route_matrix.dart';
import '../../models/purchase_record.dart';
import '../../services/budget_store.dart';
import '../../services/offer_store.dart';
import '../../services/mobility_settings_store.dart';
import '../../services/market_price_store.dart';
import '../../services/product_catalog_store.dart';
import '../../services/price_data_settings_store.dart';
import '../../services/price_history_store.dart';
import '../../services/price_observation_store.dart';
import '../../services/price_observation_adapters.dart';
import '../../services/prospect_feed_service.dart';
import '../../services/prospect_refresh_policy.dart';
import '../../services/prospect_import_module.dart';
import '../offers/offer_import.dart';
import '../offers/prospect_offer_products.dart';
import '../../services/prospect_feed_fingerprint.dart';
import '../offers/prospect_regular_price_persistence.dart';
import '../offers/prospect_price_statistics.dart';
import '../prospects/prospect_feed_status.dart';
import 'price_observation_merge.dart';
import '../../services/market_price_observation_adapter.dart';
import '../../services/recent_purchase_store.dart';
import '../../services/receipt_observation_store.dart';
import '../../services/receipt_alias_store.dart';
import '../../services/app_backup.dart';
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
import '../price_gaps/price_gap_priority.dart';
import '../route/route_optimizer.dart';
import '../route/route_screen.dart';
import '../catalog/market_price_editor_screen.dart';
import '../scanner/scanner_screen.dart';
import '../receipt/receipt_observation_migration.dart';
import '../shopping_list/replenishment_analyzer.dart';
import '../shopping_list/receipt_family_market_prices.dart';
import '../shopping_list/shopping_candidate_selector.dart';
import 'price_gap_resolution.dart';
import '../receipt/receipt_price_statistics.dart';
import '../shopping_list/planning_market_prices.dart' as planning_prices;
import '../shopping_list/shopping_list_updates.dart';
import 'shell_catalog.dart';
import 'shell_catalog_coordinator.dart';
import 'shell_routing.dart';
import 'shell_dashboard.dart';
import 'shell_navigation.dart';
import 'shell_pages.dart';
import 'active_store_count.dart';
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
    this.prospectImportModule,
    this.priceObservationStore,
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
  final ProspectImportModule? prospectImportModule;
  /// Injectable only for deterministic local-storage tests; production uses
  /// the default local preference-backed store.
  final PriceObservationStore? priceObservationStore;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  // The primary task is adding items. Open the app on the list, like Bring.
  int selectedIndex = 1;
  // Keep visited tabs mounted so scrolling state and controllers survive tab switches.
  final Set<int> _visitedTabs = <int>{1};
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
  List<ReceiptObservation> receiptObservations = const <ReceiptObservation>[];
  List<PriceObservation> historicalPriceObservations =
      const <PriceObservation>[];
  List<OfferImportRecord> prospectRecords = const <OfferImportRecord>[];
  List<ProspectIssue> prospectIssues = const <ProspectIssue>[];
  bool prospectFeedFromCache = false;
  DateTime? prospectFeedGeneratedAt;
  List<Product> prospectProducts = const <Product>[];
  bool _prospectFeedRefreshing = false;
  Timer? _prospectRefreshTimer;
  bool _appIsResumed = true;
  DateTime? _lastProspectResumeRefreshAt;
  String? _prospectFeedFingerprint;
  int prospectRegularPriceCount = 0;
  Map<String, int> prospectRegularPriceCountsByStore = const <String, int>{};
  ProspectRegularPricePersistenceStatus prospectRegularPricePersistenceStatus =
      ProspectRegularPricePersistenceStatus.standalone;
  final _defaultPriceObservationStore = PriceObservationStore();
  PriceObservationStore get priceObservationStore =>
      widget.priceObservationStore ?? _defaultPriceObservationStore;
  final receiptAliasStore = ReceiptAliasStore();
  late PriceDataSettings priceDataSettings;
  late List<PricePoint> priceHistory;
  Map<String, double> roadDistances = <String, double>{};
  final roadDistanceStore = RoadDistanceStore();
  final roadRouteMatrixStore = RoadRouteMatrixStore();
  RoadRouteMatrix? roadMatrix;
  late Map<String, String> preferredProductByGroup;
  int backupRevision = 0;
  // Prevent a delayed named-list startup read from replacing a list that the
  // user has already changed in the visible shell.
  int _shoppingListMutationRevision = 0;
  // Invalidates asynchronous startup/refresh work while a local backup is
  // being applied. The visible backup revision advances only after all
  // persistent writes and the in-memory snapshot have completed.
  int _dataRevision = 0;
  // All mutations that can be part of a backup snapshot share one queue.
  // Separate queue names keep the call sites readable while preventing a
  // backup, offer refresh, list save, and price sync from interleaving writes
  // to the same local preference store.
  final _persistenceSaves = SequentialWriteQueue();
  // Interactive list writes must not wait behind a slow startup migration or
  // a feed refresh. The list store serializes its own writes, while backup
  // import remains on the coordinated persistence queue above.
  final _shoppingListPersistence = SequentialWriteQueue();
  // User-reviewed offers have the same responsiveness requirement as list
  // additions. Feed refreshes remain serialized within this queue, but do not
  // block list or receipt persistence.
  final _offerPersistence = SequentialWriteQueue();
  // Receipt reinterpretation is a startup migration over separate receipt
  // and price-observation keys. Keep it off the interactive list/offer queue
  // so a slow local migration cannot delay a user's first add action.
  final _backgroundSaves = SequentialWriteQueue();
  SequentialWriteQueue get _shoppingListSaves => _shoppingListPersistence;
  SequentialWriteQueue get _offerSaves => _offerPersistence;
  SequentialWriteQueue get _priceSaves => _persistenceSaves;
  bool _purchaseInProgress = false;
  final _routingSnapshotCache = ShellRoutingSnapshotCache();
  final _shellPageCache = ShellPageCache();
  // PageView lays out only the active tab. IndexedStack laid out every
  // mounted prospect and price card on each navigation rebuild.
  final _shellPageController = PageController(initialPage: 1);

  List<Product>? _catalogProductsCache;
  List<Product>? _catalogProductsCustomSource;
  List<Product>? _catalogProductsProspectSource;

  List<MarketPrice>? _activeMarketPricesCache;
  List<MarketPrice>? _activeMarketPricesSource;
  PriceDataSettings? _activeMarketPricesSettings;
  DateTime? _activeMarketPricesDay;

  List<MarketPrice>? _historicalMarketPricesCache;
  List<PriceObservation>? _historicalMarketPricesSource;
  List<Product>? _historicalMarketPricesCatalogSource;
  PriceDataSettings? _historicalMarketPricesSettings;
  DateTime? _historicalMarketPricesDay;

  List<MarketPrice>? _receiptFamilyPricesCache;
  List<ReceiptObservation>? _receiptFamilyPricesObservationsSource;
  int? _receiptFamilyPricesItemSignature;
  DateTime? _receiptFamilyPricesDay;

  List<MarketPrice>? _planningMarketPricesCache;
  List<MarketPrice>? _planningMarketPricesActiveSource;
  List<MarketPrice>? _planningMarketPricesHistoricalSource;
  List<MarketPrice>? _planningMarketPricesFamilySource;
  int? _planningMarketPricesMaxAgeDays;
  DateTime? _planningMarketPricesDay;

  List<ReplenishmentSuggestion>? _replenishmentSuggestionsCache;
  List<PurchaseRecord>? _replenishmentSuggestionsHistorySource;
  List<Product>? _replenishmentSuggestionsCatalogSource;
  List<ReceiptObservation>? _replenishmentSuggestionsReceiptSource;
  int? _replenishmentSuggestionsItemSignature;
  DateTime? _replenishmentSuggestionsDay;

  Map<String, ProspectPriceHistorySummary>? _prospectPriceHistoryCache;
  List<PriceObservation>? _prospectPriceHistorySource;
  int? _prospectPriceHistoryStoreSignature;
  DateTime? _prospectPriceHistoryDay;

  void _selectTab(int index) {
    if (selectedIndex == index && _visitedTabs.contains(index)) return;
    setState(() {
      _visitedTabs.add(index);
      selectedIndex = index;
    });
    _showTabPage(index);
  }

  void _showTabPage(int index) {
    if (_shellPageController.hasClients) {
      _shellPageController.jumpToPage(index);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          selectedIndex != index ||
          !_shellPageController.hasClients) {
        return;
      }
      _shellPageController.jumpToPage(index);
    });
  }

  Product? _catalogProduct(String id) {
    return catalogProductById(id, customProducts);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleProspectRefreshTimer();
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
            note: item.note,
            checked: item.checked,
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
    // Imported offers are rebuilt from the current verified feed. Stored
    // manual offers retain their separate planning/history behavior.
    offers = widget.initialOffers
        .where((offer) => !offer.id.startsWith('import|'))
        .toList();
    recentPurchases = [...widget.initialRecentPurchases];
    purchaseHistory = [...widget.initialPurchaseHistory];
    preferredProductByGroup = {...widget.initialPreferredProductByGroup};
    _loadRoadDistances();
    _loadNamedShoppingLists();
    _loadReceiptObservations();
    _loadPriceObservations();
    _loadProspectOffers(preferCached: true);
  }

  void _scheduleProspectRefreshTimer() {
    _prospectRefreshTimer?.cancel();
    if (!mounted || !_appIsResumed) return;
    _prospectRefreshTimer = Timer(prospectResumeRefreshInterval, () {
      _prospectRefreshTimer = null;
      if (!mounted || !_appIsResumed) return;
      final now = DateTime.now();
      if (shouldRefreshProspectsOnResume(
        generatedAt: prospectFeedGeneratedAt,
        now: now,
      )) {
        _lastProspectResumeRefreshAt = now;
        // Keep the active app fresh without blocking the current tab.
        unawaited(_loadProspectOffers(preferCached: true));
      }
      _scheduleProspectRefreshTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsResumed = state == AppLifecycleState.resumed;
    if (!_appIsResumed) {
      _prospectRefreshTimer?.cancel();
      _prospectRefreshTimer = null;
      return;
    }
    _scheduleProspectRefreshTimer();
    if (!mounted) return;
    final now = DateTime.now();
    final lastAttempt = _lastProspectResumeRefreshAt;
    if (lastAttempt != null &&
        now.isBefore(lastAttempt.add(const Duration(minutes: 1)))) {
      return;
    }
    if (!shouldRefreshProspectsOnResume(
      generatedAt: prospectFeedGeneratedAt,
      now: now,
    )) {
      return;
    }
    _lastProspectResumeRefreshAt = now;
    // Refresh in the background so returning to the app never blocks the
    // current list, route, or prospect scroll position.
    unawaited(_loadProspectOffers(preferCached: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prospectRefreshTimer?.cancel();
    _prospectRefreshTimer = null;
    _shellPageController.dispose();
    // Invalidate startup/refresh callbacks before the state is torn down.
    _dataRevision++;
    super.dispose();
  }

  List<ListItem> _copyItems(List<ListItem> items) => items
      .map(
        (item) => ListItem(
          product: item.product,
          quantity: item.quantity,
          note: item.note,
          checked: item.checked,
        ),
      )
      .toList();

  void _refreshShoppingListProducts() {
    final refreshed = refreshShoppingListProducts(
      items: shoppingList,
      catalogProducts: catalogProducts,
    );
    if (identical(refreshed, shoppingList) || !mounted) return;
    setState(() => shoppingList = refreshed);
    persistShoppingListWithFeedback();
  }

  Future<void> _loadNamedShoppingLists() async {
    final revision = _dataRevision;
    final listMutationRevision = _shoppingListMutationRevision;
    final loaded = await widget.shoppingListStore.loadNamedLists();
    if (!_isCurrentDataRevision(revision) ||
        listMutationRevision != _shoppingListMutationRevision) {
      return;
    }
    if (loaded.isEmpty) {
      await _shoppingListSaves.add(() async {
        if (!_isCurrentDataRevision(revision) ||
            listMutationRevision != _shoppingListMutationRevision) {
          return;
        }
        await widget.shoppingListStore.saveNamedLists(namedShoppingLists);
      });
      return;
    }

    // During migration from the legacy single-list key, a write can leave the
    // named list briefly empty while the legacy snapshot already has items.
    // Keep that snapshot instead of replacing a visible list with empty data.
    if (loaded.first.items.isEmpty && shoppingList.isNotEmpty) {
      final migrated = loaded
          .map(
            (list) => list.id == loaded.first.id
                ? NamedShoppingList(
                    id: list.id,
                    name: list.name,
                    items: _copyItems(shoppingList),
                  )
                : list,
          )
          .toList(growable: false);
      namedShoppingLists = migrated;
      await _shoppingListSaves.add(() async {
        if (!_isCurrentDataRevision(revision) ||
            listMutationRevision != _shoppingListMutationRevision) {
          return;
        }
        await widget.shoppingListStore.saveNamedLists(migrated);
      });
      return;
    }

    setState(() {
      namedShoppingLists = loaded;
      activeShoppingListId = loaded.first.id;
      shoppingList = _copyItems(loaded.first.items);
    });
    _refreshShoppingListProducts();
  }

  Future<void> _loadRoadDistances() async {
    final revision = _dataRevision;
    Map<String, double> loaded = <String, double>{};
    RoadRouteMatrix? matrix;
    try {
      loaded = await roadDistanceStore.load(mobility.startAddress);
      matrix = await roadRouteMatrixStore.load(mobility.startAddress);
    } catch (_) {
      // Local route data is an optional optimization. A malformed or
      // unavailable cache must not prevent the shell from starting.
    }
    if (!_isCurrentDataRevision(revision)) return;
    setState(() {
      roadDistances = loaded;
      roadMatrix = matrix;
    });
  }

  List<Product> get catalogProducts {
    final cached = _catalogProductsCache;
    if (cached != null &&
        identical(_catalogProductsCustomSource, customProducts) &&
        identical(_catalogProductsProspectSource, prospectProducts)) {
      return cached;
    }
    final seen = <String>{};
    final next = buildCatalogProducts([...customProducts, ...prospectProducts])
        .where((product) => seen.add(product.id))
        .toList(growable: false);
    _catalogProductsCache = next;
    _catalogProductsCustomSource = customProducts;
    _catalogProductsProspectSource = prospectProducts;
    return next;
  }

  bool isBaseProduct(String id) => isBaseCatalogProduct(id);

  List<MarketPrice> get activeMarketPrices {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final cached = _activeMarketPricesCache;
    if (cached != null &&
        identical(_activeMarketPricesSource, marketPrices) &&
        identical(_activeMarketPricesSettings, priceDataSettings) &&
        _activeMarketPricesDay == day) {
      return cached;
    }
    final next = activePrices(marketPrices, priceDataSettings);
    _activeMarketPricesCache = next;
    _activeMarketPricesSource = marketPrices;
    _activeMarketPricesSettings = priceDataSettings;
    _activeMarketPricesDay = day;
    return next;
  }

  List<MarketPrice> get historicalMarketPrices {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final catalog = catalogProducts;
    final cached = _historicalMarketPricesCache;
    if (cached != null &&
        identical(_historicalMarketPricesSource, historicalPriceObservations) &&
        identical(_historicalMarketPricesCatalogSource, catalog) &&
        identical(_historicalMarketPricesSettings, priceDataSettings) &&
        _historicalMarketPricesDay == day) {
      return cached;
    }
    final next = marketPricesFromObservations(
      historicalPriceObservations,
      products: catalog,
      settings: priceDataSettings,
    );
    _historicalMarketPricesCache = next;
    _historicalMarketPricesSource = historicalPriceObservations;
    _historicalMarketPricesCatalogSource = catalog;
    _historicalMarketPricesSettings = priceDataSettings;
    _historicalMarketPricesDay = day;
    return next;
  }

  List<MarketPrice> get receiptFamilyPrices {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final itemSignature = _shoppingListSignature(includeQuantity: false);
    final cached = _receiptFamilyPricesCache;
    if (cached != null &&
        identical(
          _receiptFamilyPricesObservationsSource,
          receiptObservations,
        ) &&
        _receiptFamilyPricesItemSignature == itemSignature &&
        _receiptFamilyPricesDay == day) {
      return cached;
    }
    final next = receiptFamilyMarketPrices(
      items: shoppingList,
      observations: receiptObservations,
    );
    _receiptFamilyPricesCache = next;
    _receiptFamilyPricesObservationsSource = receiptObservations;
    _receiptFamilyPricesItemSignature = itemSignature;
    _receiptFamilyPricesDay = day;
    return next;
  }

  List<MarketPrice> get planningMarketPrices {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final active = activeMarketPrices;
    final historical = historicalMarketPrices;
    final family = receiptFamilyPrices;
    final cached = _planningMarketPricesCache;
    if (cached != null &&
        identical(_planningMarketPricesActiveSource, active) &&
        identical(_planningMarketPricesHistoricalSource, historical) &&
        identical(_planningMarketPricesFamilySource, family) &&
        _planningMarketPricesMaxAgeDays ==
            priceDataSettings.openPricesMaxAgeDays &&
        _planningMarketPricesDay == day) {
      return cached;
    }
    final next = planning_prices.planningMarketPrices(
      exactPrices: [...active, ...historical],
      familyPrices: family,
      openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
    );
    _planningMarketPricesCache = next;
    _planningMarketPricesActiveSource = active;
    _planningMarketPricesHistoricalSource = historical;
    _planningMarketPricesFamilySource = family;
    _planningMarketPricesMaxAgeDays = priceDataSettings.openPricesMaxAgeDays;
    _planningMarketPricesDay = day;
    return next;
  }

  int _shoppingListSignature({required bool includeQuantity}) => Object.hashAll(
    shoppingList.map(
      (item) => Object.hash(
        item.product.id,
        item.product.name,
        item.product.packageAmount,
        item.product.packageUnit,
        includeQuantity ? item.quantity : null,
      ),
    ),
  );

  Future<void> _loadPriceObservations() async {
    final revision = _dataRevision;
    final loaded =
        await purgeLegacyAutomaticProspectOfferObservations(
          store: priceObservationStore,
        );
    if (!_isCurrentDataRevision(revision)) return;
    setState(() {
      historicalPriceObservations = mergePriceObservations(
        historicalPriceObservations,
        loaded,
      );
    });
  }

  Future<void> _loadProspectOffers({
    bool preferCached = false,
    bool force = false,
  }) async {
    if (_prospectFeedRefreshing) return;
    final revision = _dataRevision;
    _prospectFeedRefreshing = true;
    final prospectImportModule =
        widget.prospectImportModule ?? ProspectImportModule();
    final ownsProspectImportModule = widget.prospectImportModule == null;
    if (mounted) setState(() {});

    // A failed live refresh must not leave the persistence card in a
    // perpetual pending state when no cached feed could be shown.
    var feedWasShown = false;
    try {
      // Start the local snapshot and the normal refresh together. A slow
      // asset/cache read must never delay the first live result.
      var networkFeedShown = false;
      if (preferCached) {
        unawaited(() async {
          try {
            final cached = await prospectImportModule.executeCached(
              startAddress: mobility.startAddress,
            );
            if (!networkFeedShown &&
                _isCurrentDataRevision(revision) &&
                cached != null) {
              _showProspectFeed(cached);
              feedWasShown = true;
              // A cached/bundled feed is already validated and may be the
              // only available stand during an offline launch. Persist its
              // explicitly stated regular prices as well; the live refresh
              // below remains responsible for rebuilding the visible offer
              // snapshot and can safely upsert the same observation IDs.
              unawaited(
                _persistCachedProspectPrices(
                  cached,
                  revision,
                  isSuperseded: () => networkFeedShown,
                ),
              );
            }
          } catch (_) {
            // The normal refresh below remains the source of truth.
          }
        }());
      }

      final feed = await prospectImportModule.execute(
        startAddress: mobility.startAddress,
      );
      networkFeedShown = true;
      if (!_isCurrentDataRevision(revision)) return;
      _showProspectFeed(feed);
      feedWasShown = true;
      final refreshNow = DateTime.now();
      final feedFingerprint = prospectFeedFingerprintFor(
        feed,
        now: refreshNow,
      );
      if (!shouldProcessProspectFeed(
        previousFingerprint: _prospectFeedFingerprint,
        currentFingerprint: feedFingerprint,
        force: force,
      )) {
        // The visible feed may be unchanged while local price evidence was
        // cleared or a previous write failed. Reconcile regular prices
        // idempotently without rebuilding the offer snapshot.
        await _persistCachedProspectPrices(
          feed,
          revision,
          isSuperseded: () => false,
        );
        return;
      }
      // A new feed starts with no confirmed count until its observations are
      // written successfully; a failed write must remain retryable.
      if (mounted) {
        setState(() {
          prospectRegularPriceCount = 0;
          prospectRegularPriceCountsByStore = const <String, int>{};
          prospectRegularPricePersistenceStatus =
              ProspectRegularPricePersistenceStatus.pending;
        });
      }

      final currentRecords = currentFoodProspectRecords(
        feed.records,
        now: refreshNow,
      );
      final baseCatalogForProspectPrices = buildCatalogProducts(customProducts);
      final offerBackedProducts = prospectOfferProducts(
        records: currentRecords,
        catalogProducts: baseCatalogForProspectPrices,
        now: refreshNow,
      );
      // Persist prices against the same exact-label products that back the
      // visible offer cards. Unknown verified items therefore retain full
      // identity confidence immediately instead of waiting for a later
      // manual list selection to make their regular price routeable.
      final catalogForProspectPrices = catalogProductsWithProspectOffers(
        catalogProducts: baseCatalogForProspectPrices,
        offerProducts: offerBackedProducts,
      );
      // A verified offer with an unknown local catalog identity remains tied
      // to its exact retailer label. Keeping that offer routeable lets the
      // user select the concrete prospect item without transferring its
      // price to a different family or variant.
      final resolved = offersFromProspectProducts(offerBackedProducts);

      if (!_isCurrentDataRevision(revision)) return;

      final retained = offers
          .where((offer) => !offer.id.startsWith('import|'))
          .toList(growable: false);
      // Imported offers are rebuilt from the validated feed on every
      // startup. Persist only manual/user-reviewed offers here; storing the
      // whole automatic feed makes local preferences grow until browser
      // storage rejects the next refresh with QuotaExceededError.
      var persistedOffers = retained;
      String? offerPersistenceWarning;
      try {
        await _offerSaves.add(() async {
          if (!_isCurrentDataRevision(revision)) {
            persistedOffers = [...offers];
            return;
          }
          // Feed refresh and user-reviewed page claims share one preference key.
          // Read inside the queue so an in-flight manual save cannot be lost.
          final stored = await widget.offerStore.load();
          final retainedById = <String, Offer>{
            for (final offer in retained) offer.id: offer,
            for (final offer in stored)
              if (!offer.id.startsWith('import|')) offer.id: offer,
          };
          persistedOffers = retainedById.values.toList(growable: false);
          await widget.offerStore.save(persistedOffers);
        });
      } catch (error) {
        // A full browser store must not hide the live in-memory feed or stop
        // the independent regular-price persistence pass.
        offerPersistenceWarning = error.toString();
      }
      if (!_isCurrentDataRevision(revision)) return;
      final offersByKey = <String, Offer>{
        for (final offer in persistedOffers)
          prospectOfferSnapshotKey(offer): offer,
        for (final entry in offerBackedProducts)
          prospectOfferSnapshotKey(entry.offer): entry.offer,
      };

      ProspectRegularPricePersistenceResult? persistence;
      String? pricePersistenceWarning;
      try {
        await _priceSaves.add(() async {
          if (!_isCurrentDataRevision(revision)) return;
          persistence = await persistCurrentProspectRegularPrices(
            store: priceObservationStore,
            records: feed.records,
            catalogProducts: catalogForProspectPrices,
            observedAt: feed.generatedAt ?? feed.capturedAt,
            now: refreshNow,
            refreshedStores: feed.refreshedStores,

            refreshedStoreScopes: feed.refreshedStoreScopes,
          );
        });
      } catch (error) {
        // PriceObservationStore already compacts quota-exhausted data, but
        // other storage failures must still leave the current feed visible.
        pricePersistenceWarning = error.toString();
      }
      if (!_isCurrentDataRevision(revision)) return;
      final learnedPrices = persistence?.learned ?? const <PriceObservation>[];
      final historical =
          persistence?.stored ?? historicalPriceObservations;
      final persistedSummary = pricePersistenceWarning == null
          ? summarizePersistedProspectRegularPrices(
              learned: learnedPrices,
              stored: historical,
            )
          : const ProspectRegularPricePersistenceSummary(
              count: 0,
              countsByBranch: <String, int>{},
            );
      final persistedRegularPriceCount = persistedSummary.count;
      final persistedRegularPriceCountsByStore =
          persistedSummary.countsByBranch;
      setState(() {
        prospectRegularPriceCount = pricePersistenceWarning == null
            ? persistedRegularPriceCount
            : 0;
        prospectRegularPriceCountsByStore =
            pricePersistenceWarning == null
                ? Map.unmodifiable(persistedRegularPriceCountsByStore)
                : const <String, int>{};
        prospectRegularPricePersistenceStatus = pricePersistenceWarning == null
            ? ProspectRegularPricePersistenceStatus.succeeded
            : ProspectRegularPricePersistenceStatus.failed;
        offers = offersByKey.values.toList(growable: false);
        prospectProducts = offerBackedProducts
            .map((entry) => entry.product)
            .toList(growable: false);
        historicalPriceObservations = mergePriceObservations(
          historicalPriceObservations,
          historical,
        );
      });
      // Do not suppress the next refresh after a failed price write.
      if (pricePersistenceWarning == null) {
        _prospectFeedFingerprint = feedFingerprint;
      }
      final persistenceWarnings = <String>[
        if (offerPersistenceWarning != null)
          'Nutzerangebote lokal nicht gespeichert: $offerPersistenceWarning',
        if (pricePersistenceWarning != null)
          'Preisbeobachtungen lokal nicht gespeichert: $pricePersistenceWarning',
      ];
      widget.diagnosticLogService.record(
        category: 'Prospekte',
        message: persistenceWarnings.isEmpty
            ? 'Prospektdatenbank aktualisiert.'
            : 'Prospektdatenbank aktualisiert; lokale Speicherung teilweise fehlgeschlagen.',
        details:
            '${feed.records.length} Rohangebote · '
            '${resolved.length} importiert · '
            '${learnedPrices.length} datierte Preise gelernt'
            '${persistenceWarnings.isEmpty ? '' : ' · ${persistenceWarnings.join(' · ')}'}',
      );
    } catch (error) {
      if (_isCurrentDataRevision(revision) && !feedWasShown && mounted) {
        setState(() {
          prospectRegularPriceCount = 0;
          prospectRegularPriceCountsByStore = const <String, int>{};
          prospectRegularPricePersistenceStatus =
              ProspectRegularPricePersistenceStatus.failed;
        });
      }
      widget.diagnosticLogService.record(
        category: 'Prospekte',
        message: 'Automatischer Prospektabruf fehlgeschlagen.',
        details: error.toString(),
      );
    } finally {
      if (ownsProspectImportModule) prospectImportModule.close();
      _prospectFeedRefreshing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _persistCachedProspectPrices(
    ProspectFeedLoadResult feed,
    int revision, {
    required bool Function() isSuperseded,
  }) async {
    // Cached feeds are shown before their regular-price projection finishes.
    // Reset the previous confirmation while this write is pending so the
    // status card never presents an older feed's count as confirmed for the
    // newly visible snapshot. A live refresh may supersede this pass before
    // the queued write completes.
    if (_isCurrentDataRevision(revision) &&
        !isSuperseded() &&
        mounted) {
      setState(() {
        prospectRegularPriceCount = 0;
        prospectRegularPriceCountsByStore = const <String, int>{};
        prospectRegularPricePersistenceStatus =
            ProspectRegularPricePersistenceStatus.pending;
      });
    }
    ProspectRegularPricePersistenceResult? persistence;
    try {
      await _priceSaves.add(() async {
        if (!_isCurrentDataRevision(revision) || isSuperseded()) return;
        final refreshNow = DateTime.now();
        final currentRecords = currentFoodProspectRecords(
          feed.records,
          now: refreshNow,
        );
        final baseCatalog = buildCatalogProducts(customProducts);
        final offerBackedProducts = prospectOfferProducts(
          records: currentRecords,
          catalogProducts: baseCatalog,
          now: refreshNow,
        );
        final catalogForProspectPrices = catalogProductsWithProspectOffers(
          catalogProducts: baseCatalog,
          offerProducts: offerBackedProducts,
        );
        persistence = await persistCurrentProspectRegularPrices(
          store: priceObservationStore,
          records: feed.records,
          catalogProducts: catalogForProspectPrices,
          observedAt: feed.generatedAt ?? feed.capturedAt,
          now: refreshNow,
          refreshedStores: feed.refreshedStores,

          refreshedStoreScopes: feed.refreshedStoreScopes,
        );
      });
    } catch (error) {
      if (_isCurrentDataRevision(revision) &&
          !isSuperseded() &&
          mounted) {
        setState(() {
          prospectRegularPriceCount = 0;
          prospectRegularPriceCountsByStore = const <String, int>{};
          prospectRegularPricePersistenceStatus =
              ProspectRegularPricePersistenceStatus.failed;
        });
      }
      widget.diagnosticLogService.record(
        category: 'Prospekte',
        message: 'Lokaler Prospektpreisstand konnte nicht gespeichert werden.',
        details: error.toString(),
      );
      return;
    }
    if (!_isCurrentDataRevision(revision) || isSuperseded()) return;

    final learned = persistence?.learned ?? const <PriceObservation>[];
    final stored = persistence?.stored ?? const <PriceObservation>[];
    final persistedSummary = summarizePersistedProspectRegularPrices(
      learned: learned,
      stored: stored,
    );
    if (!mounted || isSuperseded()) return;
    setState(() {
      prospectRegularPriceCount = persistedSummary.count;
      prospectRegularPriceCountsByStore = persistedSummary.countsByBranch;
      prospectRegularPricePersistenceStatus =
          ProspectRegularPricePersistenceStatus.succeeded;
      historicalPriceObservations = mergePriceObservations(
        historicalPriceObservations,
        stored,
      );
    });
  }

  void _showProspectFeed(ProspectFeedLoadResult feed) {
    if (!mounted) return;
    final now = DateTime.now();
    final currentRecords = currentFoodProspectRecords(feed.records, now: now);
    final baseCatalog = buildCatalogProducts(customProducts);
    final offerBackedProducts = prospectOfferProducts(
      records: currentRecords,
      catalogProducts: baseCatalog,
      now: now,
    );
    // Apply the validated feed to the in-memory offer snapshot immediately.
    // This makes a cached/offline launch useful for list quotes and route
    // hints without persisting automatic offer prices into the user store.
    final offersById = mergeTransientProspectOffers(
      existingOffers: offers,
      importedOffers: offerBackedProducts,
    );
    setState(() {
      // The visible offer area only receives currently valid prospect records;
      // the feed remains the source of truth for provenance and cache status.
      // Historical observations stay in the price store.
      prospectRecords = currentRecords;
      // Keep cached/offline prospect identities in the shell catalog too. A
      // regular price persisted from that same feed must remain routeable
      // before a network refresh becomes available.
      prospectProducts = offerBackedProducts
          .map((entry) => entry.product)
          .toList(growable: false);
      offers = offersById;
      prospectIssues = feed.prospects;
      prospectFeedFromCache = feed.fromCache;
      prospectFeedGeneratedAt = feed.generatedAt ?? feed.capturedAt;
    });
    _refreshShoppingListProducts();
  }

  Future<void> _loadReceiptObservations() async {
    final revision = _dataRevision;
    final store = ReceiptObservationStore();
    final loaded = await store.load();
    if (!_isCurrentDataRevision(revision)) return;
    final reinterpreted = reinterpretReceiptObservations(loaded);
    await _backgroundSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      await store.addMany(reinterpreted);
      if (!_isCurrentDataRevision(revision)) return;
      await priceObservationStore.upsertById(
        reinterpreted.map(observationFromReceipt),
      );
    });
    if (!_isCurrentDataRevision(revision)) return;
    final historical = await priceObservationStore.load();
    if (!_isCurrentDataRevision(revision)) return;
    setState(() {
      receiptObservations = reinterpreted;
      historicalPriceObservations = mergePriceObservations(
        historicalPriceObservations,
        historical,
      );
    });
  }

  bool _isCurrentDataRevision(int revision) =>
      mounted && revision == _dataRevision;

  List<ReplenishmentSuggestion> get replenishmentSuggestions {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final itemSignature = _shoppingListSignature(includeQuantity: false);
    final catalog = catalogProducts;
    final cached = _replenishmentSuggestionsCache;
    if (cached != null &&
        identical(_replenishmentSuggestionsHistorySource, purchaseHistory) &&
        identical(_replenishmentSuggestionsCatalogSource, catalog) &&
        identical(_replenishmentSuggestionsReceiptSource, receiptObservations) &&
        _replenishmentSuggestionsItemSignature == itemSignature &&
        _replenishmentSuggestionsDay == day) {
      return cached;
    }
    final next = buildReplenishmentSuggestions(
      history: purchaseHistory,
      catalogProducts: catalog,
      currentListProductIds: shoppingList
          .map((item) => item.product.id)
          .toSet(),
      receiptObservations: receiptObservations,
    );
    _replenishmentSuggestionsCache = next;
    _replenishmentSuggestionsHistorySource = purchaseHistory;
    _replenishmentSuggestionsCatalogSource = catalog;
    _replenishmentSuggestionsReceiptSource = receiptObservations;
    _replenishmentSuggestionsItemSignature = itemSignature;
    _replenishmentSuggestionsDay = day;
    return next;
  }

  Map<String, ProspectPriceHistorySummary> get prospectPriceHistory {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final storeNames = [...mobility.enabledStoreNames]..sort();
    final storeSignature = Object.hashAll(storeNames);
    final cached = _prospectPriceHistoryCache;
    if (cached != null &&
        identical(_prospectPriceHistorySource, historicalPriceObservations) &&
        _prospectPriceHistoryStoreSignature == storeSignature &&
        _prospectPriceHistoryDay == day) {
      return cached;
    }
    final next = prospectPriceHistorySummaries(
      historicalPriceObservations,
      enabledStores: mobility.enabledStoreNames,
    );
    _prospectPriceHistoryCache = next;
    _prospectPriceHistorySource = historicalPriceObservations;
    _prospectPriceHistoryStoreSignature = storeSignature;
    _prospectPriceHistoryDay = day;
    return next;
  }

  Future<void> persistShoppingList() {
    _shoppingListMutationRevision++;
    final snapshot = [
      for (final item in shoppingList)
        ListItem(
          product: item.product,
          quantity: item.quantity,
          note: item.note,
          checked: item.checked,
        ),
    ];
    final lists = namedShoppingLists
        .map(
          (list) => list.id == activeShoppingListId
              ? NamedShoppingList(
                  id: list.id,
                  name: list.name,
                  items: _copyItems(snapshot),
                )
              : list,
        )
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
    final selectedItems = _copyItems(shoppingList);
    await _shoppingListSaves.add(
      () => widget.shoppingListStore.save(selectedItems),
    );
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
    final savedLists = namedShoppingLists
        .map(
          (list) => NamedShoppingList(
            id: list.id,
            name: list.name,
            items: _copyItems(list.items),
          ),
        )
        .toList(growable: false);
    final savedItems = _copyItems(shoppingList);
    await _shoppingListSaves.add(() async {
      await widget.shoppingListStore.saveNamedLists(savedLists);
      await widget.shoppingListStore.save(savedItems);
    });
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
          const SnackBar(
            content: Text('Einkaufsliste konnte nicht gespeichert werden.'),
          ),
        );
      }
    });
  }

  Future<void> ensureCatalogProduct(Product product) async {
    if (isBaseProduct(product.id) ||
        customProducts.any((item) => item.id == product.id)) {
      return;
    }
    final revision = _dataRevision;
    List<Product>? next;
    await _persistenceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      next = await widget.productCatalogStore.upsert(product, customProducts);
      if (_isCurrentDataRevision(revision) && next != null) {
        // Keep the next queued catalog mutation from using a stale list while
        // the caller is waiting to schedule its rebuild.
        customProducts = next!;
      }
    });
    if (!_isCurrentDataRevision(revision) || next == null) return;
    setState(() => customProducts = next!);
  }

  void _saveKnownItem(Product product) {
    unawaited(
      _persistenceSaves.add(
        () => widget.shoppingListStore.saveKnownItem(product),
      ),
    );
  }

  void addProduct(Product product) {
    setState(() => shoppingList = addShoppingProduct(shoppingList, product));
    persistShoppingListWithFeedback();
    _saveKnownItem(product);
    ensureCatalogProduct(product);
    widget.diagnosticLogService.record(
      category: 'Einkaufsliste',
      message: 'Artikel hinzugefügt.',
      details: product.name,
    );
  }

  Future<void> selectShoppingFamily(ListItem item) async {
    final selected = await showShoppingCandidateSelector(
      context: context,
      request: item.product.name,
      catalogProducts: catalogProducts,
      offers: offers,
      marketPrices: [...activeMarketPrices, ...historicalMarketPrices],
      receiptPriceStats: buildReceiptPriceStats(
        receiptObservations,
        maxAgeDays: 60,
      ),
      prospectPriceHistory: prospectPriceHistory,
      enabledStores: mobility.enabledStoreNames,
      openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    final index = shoppingList.indexWhere(
      (candidate) => candidate.product.id == item.product.id,
    );
    if (index < 0) return;
    setState(() {
      shoppingList.removeAt(index);
      shoppingList.insertAll(
        index,
        selected.map(
          (product) => ListItem(
            product: product,
            quantity: item.quantity,
            note: 'Auswahl aus „${item.product.name}“',
          ),
        ),
      );
    });
    persistShoppingListWithFeedback();
    for (final product in selected) {
      _saveKnownItem(product);
      ensureCatalogProduct(product);
    }
    widget.diagnosticLogService.record(
      category: 'Einkaufsliste',
      message: 'Generische Anfrage konkretisiert.',
      details:
          '${item.product.name}: ${selected.map((product) => product.name).join(', ')}',
    );
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
        builder: (_) => ScannerScreen(learnedProducts: scannerProducts),
      ),
    );
    if (mounted && product != null) addProduct(product);
  }

  Future<void> markPurchased(Product product, int quantity) async {
    final revision = _dataRevision;
    List<RecentPurchase>? next;
    await _persistenceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      next = await widget.recentPurchaseStore.add(
        product,
        quantity,
        recentPurchases,
      );
      await widget.shoppingListStore.savePreferredProduct(
        product.group,
        product.id,
      );
      if (_isCurrentDataRevision(revision) && next != null) {
        recentPurchases = next!;
      }
    });
    if (!_isCurrentDataRevision(revision) || next == null) return;
    setState(() {
      preferredProductByGroup[product.group] = product.id;
      recentPurchases = next!;
    });
  }

  void changeQuantity(String productId, int delta) {
    setState(() {
      final index = shoppingList.indexWhere(
        (item) => item.product.id == productId,
      );
      if (index < 0) return;
      shoppingList[index].quantity += delta;
      if (shoppingList[index].quantity <= 0) shoppingList.removeAt(index);
    });
    persistShoppingListWithFeedback();
  }

  void updateItemNote(String productId, String note) {
    final index = shoppingList.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index < 0) return;
    setState(() => shoppingList[index].note = note.trim());
    persistShoppingListWithFeedback();
  }

  void updateItemChecked(String productId, bool checked) {
    final index = shoppingList.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index < 0) return;
    setState(() => shoppingList[index].checked = checked);
    persistShoppingListWithFeedback();
  }

  void clearPurchasedItems(Set<String> productIds) {
    if (productIds.isEmpty) return;
    setState(
      () => shoppingList.removeWhere(
        (item) => productIds.contains(item.product.id),
      ),
    );
    persistShoppingListWithFeedback();
  }

  ShellRouting get routing => _routingSnapshotCache.resolve(
    items: shoppingList,
    offers: offers,
    mobility: mobility,
    marketPrices: planningMarketPrices,
    openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
    roadDistances: roadDistances,
    roadMatrix: roadMatrix,
  );

  RouteOptimizer? get currentOptimizer => routing.current;

  RouteOptimizer? get regularOptimizer => routing.regular;

  ShellPurchaseCoordinator get purchaseCoordinator => ShellPurchaseCoordinator(
    budgetStore: widget.budgetStore,
    purchaseStore: widget.purchaseStore,
    shoppingListStore: widget.shoppingListStore,
  );

  ShellPriceCoordinator get priceCoordinator => ShellPriceCoordinator(
    marketPriceStore: widget.marketPriceStore,
    priceHistoryStore: widget.priceHistoryStore,
    observationStore: priceObservationStore,
  );

  ShellCatalogCoordinator get catalogCoordinator => ShellCatalogCoordinator(
    productCatalogStore: widget.productCatalogStore,
    shoppingListStore: widget.shoppingListStore,
    marketPriceStore: widget.marketPriceStore,
    priceHistoryStore: widget.priceHistoryStore,
    offerStore: widget.offerStore,
  );

  DashboardData dashboardData([
    ShellRouting? routeSnapshot,
    List<ReplenishmentSuggestion>? replenishmentSnapshot,
  ]) => buildShellDashboard(
    shoppingList: shoppingList,
    offers: offers,
    mobility: mobility,
    roadDistances: roadDistances,
    roadMatrix: roadMatrix,
    routing: routeSnapshot ?? routing,
    budget: budget,
    purchaseHistory: purchaseHistory,
    replenishment: replenishmentSnapshot ?? replenishmentSuggestions,
  );

  Future<void> completePurchase() async {
    if (_purchaseInProgress) return;
    final plan = currentOptimizer?.bestPlan();
    final baseline = regularOptimizer?.bestSingleStorePlan();
    if (plan == null ||
        baseline == null ||
        plan.hasDataGaps ||
        shoppingList.isEmpty) {
      return;
    }
    final purchasedItemCount = shoppingList.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final revision = _dataRevision;
    final items = _copyItems(shoppingList);
    final history = [...purchaseHistory];
    final currentBudget = budget;
    _purchaseInProgress = true;
    try {
      PurchaseMutationResult? result;
      await _persistenceSaves.add(() async {
        if (!_isCurrentDataRevision(revision)) return;
        result = await purchaseCoordinator.complete(
          plan: plan,
          baselineTotal: baseline.total,
          items: items,
          history: history,
          budget: currentBudget,
        );
      });

      if (!_isCurrentDataRevision(revision) || result == null) return;
      final applied = result!;
      setState(() {
        purchaseHistory = applied.history;
        budget = applied.budget;
        shoppingList.clear();
      });
      await persistShoppingList();
      widget.diagnosticLogService.record(
        category: 'Einkauf',
        message: 'Einkauf abgeschlossen.',
        details: '$purchasedItemCount Artikel',
      );
    } finally {
      _purchaseInProgress = false;
    }
  }

  Future<void> updatePurchase(PurchaseRecord record) async {
    final revision = _dataRevision;
    PurchaseMutationResult? result;
    await _persistenceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      result = await purchaseCoordinator.update(
        record: record,
        history: purchaseHistory,
        budget: budget,
      );
      if (_isCurrentDataRevision(revision)) {
        purchaseHistory = result!.history;
        budget = result!.budget;
      }
    });
    if (!_isCurrentDataRevision(revision) || result == null) return;
    final applied = result!;
    setState(() {
      purchaseHistory = applied.history;
      budget = applied.budget;
    });
  }

  Future<void> deletePurchase(PurchaseRecord record) async {
    final revision = _dataRevision;
    PurchaseMutationResult? result;
    await _persistenceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      result = await purchaseCoordinator.delete(
        record: record,
        history: purchaseHistory,
        budget: budget,
      );
      if (_isCurrentDataRevision(revision)) {
        purchaseHistory = result!.history;
        budget = result!.budget;
      }
    });

    if (!_isCurrentDataRevision(revision) || result == null) return;
    final applied = result!;
    setState(() {
      purchaseHistory = applied.history;
      budget = applied.budget;
    });
  }

  Future<List<Product>> saveCatalogProduct(Product product) async {
    final revision = _dataRevision;
    CatalogSaveResult? result;
    await _persistenceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      result = await catalogCoordinator.save(
        product: product,
        products: customProducts,
        shoppingList: _copyItems(shoppingList),
      );
      if (_isCurrentDataRevision(revision)) {
        customProducts = result!.products;
        shoppingList = result!.shoppingList;
      }
    });
    if (!_isCurrentDataRevision(revision) || result == null) {
      return customProducts;
    }
    final applied = result!;
    setState(() {
      customProducts = applied.products;
      shoppingList = applied.shoppingList;
    });
    return applied.products;
  }

  Future<List<Product>> deleteCatalogProduct(Product product) async {
    final revision = _dataRevision;
    CatalogDeleteResult? result;
    await _persistenceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      result = await catalogCoordinator.delete(
        product: product,
        products: customProducts,
        prices: marketPrices,
        priceHistory: priceHistory,
        offers: offers,
        shoppingList: _copyItems(shoppingList),
        preferredProductByGroup: preferredProductByGroup,
      );
      if (_isCurrentDataRevision(revision)) {
        customProducts = result!.products;
        marketPrices = result!.prices;
        priceHistory = result!.priceHistory;
        offers = result!.offers;
        shoppingList = result!.shoppingList;
        preferredProductByGroup = result!.preferredProductByGroup;
      }
    });
    if (!_isCurrentDataRevision(revision) || result == null) {
      return customProducts;
    }
    final applied = result!;
    setState(() {
      customProducts = applied.products;
      marketPrices = applied.prices;
      priceHistory = applied.priceHistory;
      offers = applied.offers;
      shoppingList = applied.shoppingList;
      preferredProductByGroup = applied.preferredProductByGroup;
    });
    return applied.products;
  }

  Future<List<MarketPrice>> saveMarketPrice(MarketPrice price) async {
    final revision = _dataRevision;
    PriceMutationResult? result;
    await _priceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      result = await priceCoordinator.save(
        price: price,
        prices: marketPrices,
        history: priceHistory,
      );
      if (_isCurrentDataRevision(revision)) {
        marketPrices = result!.prices;
        priceHistory = result!.history;
        historicalPriceObservations = result!.observations;
      }
    });
    if (!_isCurrentDataRevision(revision) || result == null) {
      return marketPrices;
    }
    final applied = result!;
    setState(() {
      marketPrices = applied.prices;
      priceHistory = applied.history;
      historicalPriceObservations = applied.observations;
    });
    widget.diagnosticLogService.record(
      category: 'Preisdaten',
      message: price.source == MarketPriceSource.receipt
          ? 'Kassenbonpreis gespeichert.'
          : 'Preis gespeichert.',
      details:
          '${price.storeName} · ${price.productId} · ${price.price.toStringAsFixed(2)} €',
    );
    return applied.prices;
  }

  /// Applies receipt-review batches as one visible price snapshot.
  ///
  /// The individual price editor still uses [saveMarketPrice]. Batch imports
  /// use this path so list, price history and route inputs advance together.
  Future<void> saveMarketPrices(Iterable<MarketPrice> prices) async {
    final incoming = prices.toList(growable: false);
    if (incoming.isEmpty) return;
    final revision = _dataRevision;
    PriceMutationResult? result;
    await _priceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      result = await priceCoordinator.saveMany(
        prices: incoming,
        currentPrices: marketPrices,
        history: priceHistory,
      );
      if (_isCurrentDataRevision(revision)) {
        marketPrices = result!.prices;
        priceHistory = result!.history;
        historicalPriceObservations = result!.observations;
      }
    });
    if (!_isCurrentDataRevision(revision) || result == null) return;
    final applied = result!;
    setState(() {
      marketPrices = applied.prices;
      priceHistory = applied.history;
      historicalPriceObservations = applied.observations;
    });
    widget.diagnosticLogService.record(
      category: 'Preisdaten',
      message: '${incoming.length} Preisbelege gemeinsam gespeichert.',
      details: incoming
          .map(
            (price) =>
                '${price.storeName} · ${price.productId} · '
                '${price.price.toStringAsFixed(2)} €',
          )
          .join(' | '),
    );
  }

  Future<List<MarketPrice>> deleteMarketPrice(
    String productId,
    String storeName,
  ) async {
    final revision = _dataRevision;
    List<MarketPrice>? next;
    await _priceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      next = await priceCoordinator.delete(
        productId: productId,
        storeName: storeName,
        prices: marketPrices,
      );
      if (_isCurrentDataRevision(revision)) marketPrices = next!;
    });
    if (!_isCurrentDataRevision(revision) || next == null) return marketPrices;
    final applied = next!;
    setState(() => marketPrices = applied);
    return applied;
  }

  List<Product> _openPricesDemandProducts() {
    final wantedIds = shoppingList.map((item) => item.product.id).toSet();
    return catalogProducts
        .where((product) => wantedIds.contains(product.id))
        .toList(growable: false);
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
    final revision = _dataRevision;
    final progressCallback = onProgress;
    final cancelCallback = shouldCancel;
    PriceSyncResult? result;
    try {
      await _priceSaves.add(() async {
        if (!_isCurrentDataRevision(revision)) return;
        result = await priceCoordinator.syncOpenPrices(
          products: retryIds == null
              ? _openPricesDemandProducts()
              : catalogProducts
                    .where((product) => retryIds.contains(product.id))
                    .toList(),
          maxAgeDays: priceDataSettings.openPricesMaxAgeDays,
          prices: marketPrices,
          history: priceHistory,
          onProgress: progressCallback == null
              ? null
              : (processed, total) {
                  if (_isCurrentDataRevision(revision)) {
                    progressCallback(processed, total);
                  }
                },
          shouldCancel: () =>
              !_isCurrentDataRevision(revision) ||
              (cancelCallback?.call() ?? false),
        );
        if (_isCurrentDataRevision(revision)) {
          marketPrices = result!.prices;
          priceHistory = result!.history;
          historicalPriceObservations = result!.observations;
        }
      });
    } catch (error) {
      widget.diagnosticLogService.record(
        category: 'Open Prices',
        message: 'Preisabgleich fehlgeschlagen.',
        details: error.toString(),
      );
      rethrow;
    }

    if (!_isCurrentDataRevision(revision) || result == null) {
      return PriceSyncResult(
        prices: marketPrices,
        history: priceHistory,
        productsChecked: 0,
        productsWithEan: 0,
        pricesFound: 0,
        productsProcessed: 0,
        cancelled: true,
      );
    }
    final applied = result!;
    if (mounted) {
      setState(() {
        marketPrices = applied.prices;
        priceHistory = applied.history;
        historicalPriceObservations = applied.observations;
      });
    }
    widget.diagnosticLogService.record(
      category: 'Open Prices',
      message: applied.cancelled
          ? 'Preisabgleich abgebrochen.'
          : 'Preisabgleich abgeschlossen.',
      details:
          '${applied.productsProcessed}/${applied.productsWithEan} Produkte · '
          '${applied.pricesFound} Preise · '
          '${applied.failedProductIds.length} Fehler',
    );
    return applied;
  }

  Future<void> openPriceDataSettings() async {
    final result = await Navigator.of(context).push<PriceDataSettings>(
      MaterialPageRoute(
        builder: (_) =>
            PriceDataSettingsScreen(initialSettings: priceDataSettings),
      ),
    );
    if (result == null) return;

    final nextSettings = result;
    final revision = _dataRevision;
    await _persistenceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      await widget.priceDataSettingsStore.save(nextSettings);
    });
    if (!_isCurrentDataRevision(revision)) return;
    setState(() => priceDataSettings = nextSettings);
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

  Future<void> openPriceGapEditor(PriceGapPriority gap) async {
    if (shouldResolvePriceGapByProductSelection(gap.item.product)) {
      final selected = await showShoppingCandidateSelector(
        context: context,
        request: gap.item.product.name,
        catalogProducts: catalogProducts,
        offers: offers,
        marketPrices: [...activeMarketPrices, ...historicalMarketPrices],
        receiptPriceStats: buildReceiptPriceStats(
          receiptObservations,
          maxAgeDays: 60,
        ),
        prospectPriceHistory: prospectPriceHistory,
        enabledStores: mobility.enabledStoreNames,
        openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
      );
      if (!mounted || selected == null || selected.isEmpty) return;

      final next = replacePriceGapItem(
        items: shoppingList,
        sourceProductId: gap.item.product.id,
        selectedProducts: selected,
      );
      if (next == null) return;
      setState(() => shoppingList = next);
      persistShoppingListWithFeedback();
      for (final product in selected) {
        _saveKnownItem(product);
        ensureCatalogProduct(product);
      }
      widget.diagnosticLogService.record(
        category: 'Einkaufsliste',
        message: 'Datenlücke durch Produktauswahl konkretisiert.',
        details:
            '${gap.item.product.name}: '
            '${selected.map((product) => product.name).join(', ')}',
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MarketPriceEditorScreen(
          product: gap.item.product,
          prices: marketPrices,
          onSave: saveMarketPrice,
          onDelete: deleteMarketPrice,
          openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
        ),
      ),
    );
  }

  Future<List<Offer>> saveOffer(Offer offer) async {
    final revision = _dataRevision;
    List<Offer>? next;
    await _offerSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      final stored = await widget.offerStore.load();
      final updated = await widget.offerStore.upsert(offer, stored);
      if (_isCurrentDataRevision(revision)) next = updated;
    });
    if (!_isCurrentDataRevision(revision) || next == null) return offers;
    final applied = next!;
    setState(() => offers = applied);
    unawaited(_recordOfferHistory(offer));
    return applied;
  }
  Future<void> saveProspectRegularPriceObservation(
    PriceObservation observation,
  ) async {
    final revision = _dataRevision;
    List<PriceObservation>? next;
    await _priceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      next = await priceObservationStore.upsertById([observation]);
    });
    if (!_isCurrentDataRevision(revision) || next == null) return;
    final applied = next!;
    setState(() {
      historicalPriceObservations = mergePriceObservations(
        historicalPriceObservations,
        applied,
      );
    });
    widget.diagnosticLogService.record(
      category: 'Preisdaten',
      message: 'Geprüfter Prospekt-Normalpreis gespeichert.',
      details:
          '${observation.storeName} · ${observation.price.toStringAsFixed(2)} €',
    );
  }

  Future<void> _recordOfferHistory(Offer offer) async {
    final revision = _dataRevision;
    try {
      await _priceSaves.add(() async {
        if (!_isCurrentDataRevision(revision)) return;
        await priceObservationStore.append(
          observationsFromOffer(
            offer,
            observedAt: observedAtForOffer(offer, fallback: DateTime.now()),
          ),
        );
      });
      if (!_isCurrentDataRevision(revision)) return;
      await _loadPriceObservations();
    } catch (error) {
      widget.diagnosticLogService.record(
        category: 'Angebote',
        message: 'Preisbeobachtung konnte nicht gespeichert werden.',
        details: error.toString(),
      );
    }
  }

  Future<List<Offer>> deleteOffer(Offer offer) async {
    final revision = _dataRevision;
    List<Offer>? next;
    await _offerSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      final stored = await widget.offerStore.load();
      final updated = await widget.offerStore.remove(offer.id, stored);
      if (_isCurrentDataRevision(revision)) next = updated;
    });
    if (!_isCurrentDataRevision(revision) || next == null) return offers;
    final applied = next!;
    setState(() => offers = applied);
    return applied;
  }

  Future<void> openMobilitySettings() async {
    final result = await Navigator.of(context).push<MobilitySettings>(
      MaterialPageRoute(
        builder: (_) => MobilitySettingsScreen(initialSettings: mobility),
      ),
    );
    if (result == null) return;

    final nextMobility = result;
    final revision = _dataRevision;
    await _persistenceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      await widget.mobilityStore.save(nextMobility);
    });
    if (!_isCurrentDataRevision(revision)) return;
    Map<String, double> loaded = <String, double>{};
    RoadRouteMatrix? matrix;
    try {
      loaded = await roadDistanceStore.load(nextMobility.startAddress);
      matrix = await roadRouteMatrixStore.load(nextMobility.startAddress);
    } catch (_) {
      // A broken local route cache must not block saving otherwise valid
      // mobility settings; the route screen keeps its configured fallbacks.
    }
    if (!_isCurrentDataRevision(revision)) return;
    setState(() {
      mobility = nextMobility;
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

    final nextMobility = result;
    final revision = _dataRevision;
    await _persistenceSaves.add(() async {
      if (!_isCurrentDataRevision(revision)) return;
      await widget.mobilityStore.save(nextMobility);
    });
    if (!_isCurrentDataRevision(revision)) return;
    setState(() => mobility = nextMobility);
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
            additionalStoreCost: mobility.additionalStoreCost,
            timeValuePerHour: mobility.timeValuePerHour,
            travelMinutesPerKm: 60 / mobility.mode.averageSpeedKmh,
            enabledStoreNames: mobility.enabledStoreNames,
            marketPrices: planningMarketPrices,
            openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
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
        builder: (_) =>
            DiagnosticLogScreen(service: widget.diagnosticLogService),
      ),
    );
  }

  Future<AppBackup> _createBackup() async {
    return AppBackup(
      createdAt: DateTime.now(),
      budget: budget,
      mobility: mobility,
      priceDataSettings: priceDataSettings,
      activeShoppingListId: activeShoppingListId,
      shoppingList: _copyItems(shoppingList),
      namedLists: namedShoppingLists
          .map(
            (list) => NamedShoppingList(
              id: list.id,
              name: list.name,
              items: _copyItems(list.items),
            ),
          )
          .toList(growable: false),
      offers: [...offers],
      marketPrices: [...marketPrices],
      customProducts: [...customProducts],
      priceHistory: [...priceHistory],
      recentPurchases: [...recentPurchases],
      purchaseHistory: [...purchaseHistory],
      preferredProductByGroup: {...preferredProductByGroup},
      receiptObservations: [...receiptObservations],
      priceObservations: await priceObservationStore.load(),
      receiptAliases: await receiptAliasStore.load(),
      roadDistances: {...roadDistances},
      roadMatrix: roadMatrix,
      knownItems: await widget.shoppingListStore.loadKnownItems(),
      aisleOrder: await widget.shoppingListStore.loadAisleOrder(),
      tileView: await widget.shoppingListStore.loadTileView(),
    );
  }

  Future<void> exportBackup() async {
    try {
      final backup = await _createBackup();
      final bytes = Uint8List.fromList(utf8.encode(backup.encode()));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Sparzam-Backup speichern',
        fileName: 'sparzam-backup-${_backupDate(backup.createdAt)}.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Backup wurde zum Download bereitgestellt.'
                : 'Backup gespeichert.',
          ),
        ),
      );
    } catch (error) {
      widget.diagnosticLogService.record(
        category: 'Backup',
        message: 'Backup konnte nicht exportiert werden.',
        details: error.toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup konnte nicht erstellt werden.')),
      );
    }
  }

  Future<void> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Sparzam-Backup auswählen',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      final bytes = result?.files.single.bytes;
      if (bytes == null) return;
      final backup = AppBackup.decode(utf8.decode(bytes));
      await _applyBackup(backup);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup vom ${_backupDate(backup.createdAt)} wurde importiert.',
          ),
        ),
      );
    } on FormatException catch (error) {
      widget.diagnosticLogService.record(
        category: 'Backup',
        message: 'Backup ist nicht kompatibel.',
        details: error.message,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup ist ungültig oder nicht kompatibel.'),
        ),
      );
    } catch (error) {
      widget.diagnosticLogService.record(
        category: 'Backup',
        message: 'Backup konnte nicht importiert werden.',
        details: error.toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup konnte nicht importiert werden.')),
      );
    }
  }

  Future<void> _applyBackup(AppBackup backup) async {
    // Invalidate startup and refresh callbacks before the first await. Their
    // stores are then either ordered behind the backup write queue or ignored
    // before they can project stale data into the UI again.
    final revision = ++_dataRevision;
    final lists = backup.namedLists.isEmpty
        ? [
            NamedShoppingList(
              id: backup.activeShoppingListId,
              name: 'Einkauf',
              items: _copyItems(backup.shoppingList),
            ),
          ]
        : backup.namedLists;
    final activeId = lists.any((list) => list.id == backup.activeShoppingListId)
        ? backup.activeShoppingListId
        : lists.first.id;

    await _persistenceSaves.add(() async {
      // A second import may have superseded this snapshot while it waited in
      // the queue. Do not let an older backup overwrite the newer one.
      if (!_isCurrentDataRevision(revision)) return;
      await Future.wait([
        widget.budgetStore.save(backup.budget),
        widget.mobilityStore.save(backup.mobility),
        widget.priceDataSettingsStore.save(backup.priceDataSettings),
        widget.offerStore.save(backup.offers),
        widget.marketPriceStore.save(backup.marketPrices),
        widget.productCatalogStore.save(backup.customProducts),
        widget.priceHistoryStore.save(backup.priceHistory),
        widget.recentPurchaseStore.save(backup.recentPurchases),
        widget.purchaseStore.save(backup.purchaseHistory),
        widget.shoppingListStore.save(backup.shoppingList),
        widget.shoppingListStore.saveNamedLists(lists),
        widget.shoppingListStore.saveKnownItems(backup.knownItems),
        widget.shoppingListStore.savePreferredProducts(
          backup.preferredProductByGroup,
        ),
        widget.shoppingListStore.saveAisleOrder(backup.aisleOrder),
        widget.shoppingListStore.saveTileView(backup.tileView),
        ReceiptObservationStore().replaceAll(backup.receiptObservations),
        priceObservationStore.replaceAll(backup.priceObservations),
        receiptAliasStore.save(backup.receiptAliases),
        roadDistanceStore.save(
          backup.mobility.startAddress,
          backup.roadDistances,
        ),
        if (backup.roadMatrix != null)
          roadRouteMatrixStore.save(backup.roadMatrix!),
        if (backup.roadMatrix == null) roadRouteMatrixStore.clear(),
      ]);
    });

    if (!_isCurrentDataRevision(revision)) return;
    _prospectFeedFingerprint = null;
    setState(() {
      budget = backup.budget;
      mobility = backup.mobility;
      priceDataSettings = backup.priceDataSettings;
      activeShoppingListId = activeId;
      shoppingList = _copyItems(
        lists.firstWhere((list) => list.id == activeId).items,
      );
      namedShoppingLists = lists
          .map(
            (list) => NamedShoppingList(
              id: list.id,
              name: list.name,
              items: _copyItems(list.items),
            ),
          )
          .toList(growable: false);
      offers = [...backup.offers];
      marketPrices = [...backup.marketPrices];
      customProducts = [...backup.customProducts];
      priceHistory = [...backup.priceHistory];
      recentPurchases = [...backup.recentPurchases];
      purchaseHistory = [...backup.purchaseHistory];
      preferredProductByGroup = {...backup.preferredProductByGroup};
      receiptObservations = [...backup.receiptObservations];
      historicalPriceObservations = [...backup.priceObservations];
      roadDistances = {...backup.roadDistances};
      roadMatrix = backup.roadMatrix;
      backupRevision++;
    });
  }

  String _backupDate(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}-'
      '${value.hour.toString().padLeft(2, '0')}'
      '${value.minute.toString().padLeft(2, '0')}';

  void openRoute() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatefulBuilder(
          builder: (routeContext, refreshRoute) => Scaffold(
            appBar: AppBar(title: const Text('Einkaufsroute')),
            body: SafeArea(
              child: RouteScreen(
                items: shoppingList,
                offers: offers,
                mobility: mobility,
                marketPrices: planningMarketPrices,
                storeCatalog: stores,
                openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
                recentPurchases: recentPurchases,
                historicalPriceObservations: historicalPriceObservations,
                onResolvePriceGap: (gap) async {
                  await openPriceGapEditor(gap);
                  if (mounted) refreshRoute(() {});
                },
                onRoadDistancesChanged: (value) {
                  setState(() => roadDistances = value);
                  refreshRoute(() {});
                },
                onRoadMatrixChanged: (value) {
                  setState(() => roadMatrix = value);
                  refreshRoute(() {});
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _shellItemSignature(ListItem item) => Object.hash(
        item.product.id,
        item.product.name,
        item.product.packageAmount,
        item.product.packageUnit,
        item.quantity,
        item.note,
        item.checked,
      );

  int _shellPageSignature() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final itemSignature = Object.hashAll(
      shoppingList.map(_shellItemSignature),
    );
    final namedListSignature = Object.hashAll(
      namedShoppingLists.map(
        (list) => Object.hash(
          list.id,
          list.name,
          Object.hashAll(list.items.map(_shellItemSignature)),
        ),
      ),
    );
    return Object.hashAll(<Object?>[
      backupRevision,
      day,
      itemSignature,
      namedListSignature,
      activeShoppingListId,
      budget,
      mobility,
      customProducts,
      marketPrices,
      priceHistory,
      historicalPriceObservations,
      recentPurchases,
      purchaseHistory,
      preferredProductByGroup,
      offers,
      prospectRecords,
      prospectIssues,
      prospectProducts,
      prospectFeedFromCache,
      prospectFeedGeneratedAt,
      prospectRegularPriceCount,
      prospectRegularPriceCountsByStore,
      prospectRegularPricePersistenceStatus,
      _prospectFeedRefreshing,
      roadDistances,
      roadMatrix,
      priceDataSettings,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pageSignature = _shellPageSignature();
    final pages = _shellPageCache.resolve(
      signature: pageSignature,
      builder: () {
    final catalog = catalogProducts;
    final plannedPrices = planningMarketPrices;
    final routeSnapshot = _routingSnapshotCache.resolve(
      items: shoppingList,
      offers: offers,
      mobility: mobility,
      marketPrices: plannedPrices,
      storeCatalog: stores,
      openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
      roadDistances: roadDistances,
      roadMatrix: roadMatrix,
    );
    final currentRouteOptimizer = routeSnapshot.current;
    final regularRouteOptimizer = routeSnapshot.regular;
    final currentPlan = currentRouteOptimizer?.bestPlan();
    final regularPlan = regularRouteOptimizer?.bestSingleStorePlan();
    final replenishment = replenishmentSuggestions;
    final prospectHistory = prospectPriceHistory;
    return buildShellPages(
      dashboard: dashboardData(routeSnapshot, replenishment),
      onOpenList: () => _selectTab(1),
      onOpenRoute: openRoute,
      onOpenOffers: () => _selectTab(2),
      onOpenBudget: openBudget,
      onOpenScanner: openScanner,
      shoppingList: shoppingList,
      shoppingLists: namedShoppingLists,
      activeShoppingListId: activeShoppingListId,
      onSelectShoppingList: selectShoppingList,
      onCreateShoppingList: createShoppingList,
      onAddProduct: addProduct,
      onChangeQuantity: changeQuantity,
      onSelectFamily: selectShoppingFamily,
      onUpdateItemNote: updateItemNote,
      onUpdateItemChecked: updateItemChecked,
      preferredProductByGroup: preferredProductByGroup,
      recentPurchases: recentPurchases,
      onPurchased: markPurchased,
      onClearPurchased: clearPurchasedItems,
      shoppingListStore: widget.shoppingListStore,
      offers: offers,
      prospectRecords: prospectRecords,
      prospectIssues: prospectIssues,
      prospectFeedFromCache: prospectFeedFromCache,
      prospectRegularPriceCount: prospectRegularPriceCount,
      prospectRegularPriceCountsByStore: prospectRegularPriceCountsByStore,
      prospectRegularPricePersistenceStatus:
          prospectRegularPricePersistenceStatus,
      prospectFeedGeneratedAt: prospectFeedGeneratedAt,
      onRefreshProspects: () => _loadProspectOffers(
        preferCached: false,
        force: true,
      ),
      prospectsRefreshing: _prospectFeedRefreshing,
      priceHistory: priceHistory,
      mobility: mobility,
      catalogProducts: catalog,
      marketPrices: plannedPrices,
      storeCatalog: stores,
      openPricesMaxAgeDays: priceDataSettings.openPricesMaxAgeDays,
      priceObservations: plannedPrices,
      historicalPriceObservations: historicalPriceObservations,
      prospectPriceHistory: prospectHistory,
      replenishmentSuggestions: replenishment,
      onRoadDistancesChanged: (value) => setState(() => roadDistances = value),
      onRoadMatrixChanged: (value) => setState(() => roadMatrix = value),
      currentPlan: currentPlan,
      baselineTotal: regularPlan?.total ?? 0,
      baselineHasDataGaps: regularPlan?.hasDataGaps ?? false,
      purchaseHistory: purchaseHistory,
      onCompletePurchase: completePurchase,
      onUpdatePurchase: updatePurchase,
      onDeletePurchase: deletePurchase,
      onEditMobility: openMobilitySettings,
      onEditStores: openStoreSettings,
      storeCount: activeStoreCount(mobility.enabledStoreNames),
      onOpenCatalog: openCatalog,
      onResolvePriceGap: openPriceGapEditor,
      onEditPriceData: openPriceDataSettings,
      onSavePrice: saveMarketPrice,
      onSavePrices: saveMarketPrices,
      onSaveProduct: saveCatalogProduct,
      onReceiptObservationsChanged: _loadReceiptObservations,
      onSaveOffer: saveOffer,
      onSaveProspectRegularPrice: saveProspectRegularPriceObservation,
      onDeleteOffer: deleteOffer,
      priceDataSummary: priceDataSettings.openPricesEnabled
          ? 'Open Prices · max. ${priceDataSettings.openPricesMaxAgeDays} Tage'
          : 'Nur eigene Preise',
      onOpenDiagnostics: openDiagnostics,
      onExportBackup: exportBackup,
      onImportBackup: importBackup,
      dataRevision: backupRevision,
    );

      },
    );

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _shellPageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (selectedIndex == index) return;
            setState(() {
              _visitedTabs.add(index);
              selectedIndex = index;
            });
          },
          children: [
            for (var index = 0; index < pages.length; index++)
              _visitedTabs.contains(index)
                  ? pages[index]
                  : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: shellDestinations,
      ),
    );
  }
}

