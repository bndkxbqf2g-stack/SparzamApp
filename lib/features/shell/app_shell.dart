import 'package:flutter/material.dart';

import '../../models/budget_plan.dart';
import '../../models/list_item.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import '../../models/price_point.dart';
import '../../models/recent_purchase.dart';
import '../../models/purchase_record.dart';
import '../../services/budget_store.dart';
import '../../services/offer_store.dart';
import '../../services/mobility_settings_store.dart';
import '../../services/recent_purchase_store.dart';
import '../../services/purchase_store.dart';
import '../../services/road_distance_store.dart';
import '../../services/shopping_list_store.dart';
import '../budget/budget_calculator.dart';
import '../budget/budget_screen.dart';
import '../home/dashboard_data.dart';
import '../home/home_screen.dart';
import '../offers/offers_screen.dart';
import '../profile/mobility_settings_screen.dart';
import '../profile/profile_screen.dart';
import '../receipt/receipt_screen.dart';
import '../receipt/purchase_summary.dart';
import '../route/route_optimizer.dart';
import '../route/route_screen.dart';
import '../scanner/scanner_screen.dart';
import '../shopping_list/shopping_list_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.budgetStore,
    required this.offerStore,
    required this.mobilityStore,
    required this.recentPurchaseStore,
    required this.purchaseStore,
    required this.shoppingListStore,
    required this.initialBudget,
    required this.initialOffers,
    required this.initialMobility,
    required this.initialPriceHistory,
    required this.initialRecentPurchases,
    required this.initialPurchaseHistory,
    required this.initialShoppingList,
    required this.initialPreferredProductByGroup,
  });

  final BudgetStore budgetStore;
  final OfferStore offerStore;
  final MobilitySettingsStore mobilityStore;
  final RecentPurchaseStore recentPurchaseStore;
  final PurchaseStore purchaseStore;
  final ShoppingListStore shoppingListStore;
  final BudgetPlan initialBudget;
  final List<Offer> initialOffers;
  final MobilitySettings initialMobility;
  final List<PricePoint> initialPriceHistory;
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
  Map<String, double> roadDistances = <String, double>{};
  final roadDistanceStore = RoadDistanceStore();
  late final Map<String, String> preferredProductByGroup;

  @override
  void initState() {
    super.initState();
    budget = widget.initialBudget;
    mobility = widget.initialMobility;
    shoppingList = [...widget.initialShoppingList];
    offers = [...widget.initialOffers];
    recentPurchases = [...widget.initialRecentPurchases];
    purchaseHistory = [...widget.initialPurchaseHistory];
    preferredProductByGroup = {...widget.initialPreferredProductByGroup};
    _loadRoadDistances();
  }

  Future<void> _loadRoadDistances() async {
    final loaded = await roadDistanceStore.load(mobility.startAddress);
    if (!mounted) return;
    setState(() => roadDistances = loaded);
  }

  Future<void> persistShoppingList() =>
      widget.shoppingListStore.save(shoppingList);

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
  }

  Future<void> openScanner() async {
    final learned = await widget.shoppingListStore.loadKnownItems();
    if (!mounted) return;
    final product = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => ScannerScreen(
          learnedProducts: learned.map((item) => item.toProduct()).toList(),
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
          euroPerKm: mobility.euroPerKm,
        );

  RouteOptimizer? get regularOptimizer => shoppingList.isEmpty
      ? null
      : RouteOptimizer(
          shoppingList,
          const <Offer>[],
          roadDistances: roadDistances,
          euroPerKm: mobility.euroPerKm,
        );

  DashboardData dashboardData() {
    final best = currentOptimizer?.bestPlan();
    final baseline = regularOptimizer?.bestSingleStorePlan();
    final savings = best == null || baseline == null ? 0.0 : baseline.total - best.total;
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
    if (!mounted) return;
    setState(() {
      mobility = result;
      roadDistances = loaded;
    });
  }

  void openBudget() {
    final best = shoppingList.isEmpty
        ? null
        : RouteOptimizer(
            shoppingList,
            offers,
            roadDistances: roadDistances,
            euroPerKm: mobility.euroPerKm,
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
      ),
      RouteScreen(
        items: shoppingList,
        offers: offers,
        mobility: mobility,
        onRoadDistancesChanged: (value) =>
            setState(() => roadDistances = value),
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
