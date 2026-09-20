import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final recentPurchaseStore = RecentPurchaseStore();
  final shoppingListStore = ShoppingListStore();

  final recentPurchases = await recentPurchaseStore.load();
  final initialShoppingList = await shoppingListStore.load();
  final preferredProductByGroup =
      await shoppingListStore.loadPreferredProducts();

  runApp(
    SparzamApp(
      recentPurchaseStore: recentPurchaseStore,
      shoppingListStore: shoppingListStore,
      initialRecentPurchases: recentPurchases,
      initialShoppingList: initialShoppingList,
      initialPreferredProductByGroup: preferredProductByGroup,
    ),
  );
}

class RecentPurchase {
  const RecentPurchase({
    required this.id,
    required this.name,
    required this.unit,
    required this.group,
    this.purchaseCount = 1,
    this.totalQuantity = 1,
  });

  final String id;
  final String name;
  final String unit;
  final String group;
  final int purchaseCount;
  final int totalQuantity;

  double get averageQuantity => totalQuantity / purchaseCount;

  factory RecentPurchase.fromProduct(Product product) {
    return RecentPurchase(
      id: product.id,
      name: product.name,
      unit: product.unit,
      group: product.group,
    );
  }

  factory RecentPurchase.fromJson(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return RecentPurchase(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      group: json['group'] as String,
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 1,
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 1,
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'unit': unit,
      'group': group,
      'purchaseCount': purchaseCount,
      'totalQuantity': totalQuantity,
    });
  }

  Product toProduct() {
    final known = products.where((product) => product.id == id);
    if (known.isNotEmpty) {
      return known.first;
    }

    return Product(
      id: id,
      name: name,
      unit: unit,
      group: group,
    );
  }
}

class RecentPurchaseStore {
  static const _storageKey = 'recent_purchases';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<RecentPurchase>> load() async {
    final values = await _preferences.getStringList(_storageKey);

    if (values == null) {
      return <RecentPurchase>[];
    }

    final purchases = <RecentPurchase>[];

    for (final value in values) {
      try {
        purchases.add(RecentPurchase.fromJson(value));
      } catch (_) {
        // Beschädigte Einzel-Einträge werden ignoriert.
      }
    }

    return purchases.take(30).toList();
  }

  Future<List<RecentPurchase>> add(
    Product product,
    int quantity,
    List<RecentPurchase> current,
  ) async {
    final previous = current.where((item) => item.id == product.id).firstOrNull;
    final purchase = RecentPurchase(
      id: product.id,
      name: product.name,
      unit: product.unit,
      group: product.group,
      purchaseCount: (previous?.purchaseCount ?? 0) + 1,
      totalQuantity: (previous?.totalQuantity ?? 0) + quantity,
    );

    final next = <RecentPurchase>[
      purchase,
      ...current.where((item) => item.id != purchase.id),
    ].take(30).toList();

    await _preferences.setStringList(
      _storageKey,
      next.map((item) => item.toJson()).toList(),
    );

    return next;
  }
}



class ShoppingListStore {
  static const _storageKey = 'shopping_list';
  static const _knownItemsStorageKey = 'known_shopping_items';
  static const _preferredProductsStorageKey = 'preferred_products_by_group';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<Map<String, String>> loadPreferredProducts() async {
    final values =
        await _preferences.getStringList(_preferredProductsStorageKey);
    if (values == null) {
      return <String, String>{'butter': 'butter_streichzart'};
    }

    final result = <String, String>{};
    for (final value in values) {
      final parts = value.split('|');
      if (parts.length == 2) {
        result[parts[0]] = parts[1];
      }
    }
    return result;
  }

  Future<void> savePreferredProduct(String group, String productId) async {
    final current = await loadPreferredProducts();
    current[group] = productId;
    await _preferences.setStringList(
      _preferredProductsStorageKey,
      current.entries.map((entry) => '${entry.key}|${entry.value}').toList(),
    );
  }

  Future<List<RecentPurchase>> loadKnownItems() async {
    final values = await _preferences.getStringList(_knownItemsStorageKey);
    if (values == null) {
      return <RecentPurchase>[];
    }

    final items = <RecentPurchase>[];
    for (final value in values) {
      try {
        items.add(RecentPurchase.fromJson(value));
      } catch (_) {
        // Beschädigte Einzel-Einträge werden ignoriert.
      }
    }
    return items;
  }

  Future<void> saveKnownItem(Product product) async {
    final current = await loadKnownItems();
    final item = RecentPurchase.fromProduct(product);
    final next = [
      item,
      ...current.where((existing) => existing.id != item.id),
    ];
    await _preferences.setStringList(
      _knownItemsStorageKey,
      next.map((entry) => entry.toJson()).toList(),
    );
  }

  Future<List<ListItem>> load() async {
    final values = await _preferences.getStringList(_storageKey);
    if (values == null) {
      return <ListItem>[];
    }

    final items = <ListItem>[];

    for (final value in values) {
      try {
        final json = jsonDecode(value) as Map<String, dynamic>;
        items.add(
          ListItem(
            product: Product(
              id: json['id'] as String,
              name: json['name'] as String,
              unit: json['unit'] as String,
              group: json['group'] as String,
            ),
            quantity: (json['quantity'] as num?)?.toInt() ?? 1,
          ),
        );
      } catch (_) {
        // Beschädigte Einzel-Einträge werden ignoriert.
      }
    }

    return items;
  }

  Future<void> save(List<ListItem> items) async {
    await _preferences.setStringList(
      _storageKey,
      items.map((item) {
        return jsonEncode({
          'id': item.product.id,
          'name': item.product.name,
          'unit': item.product.unit,
          'group': item.product.group,
          'quantity': item.quantity,
        });
      }).toList(),
    );
  }

  Future<void> clear() async {
    await _preferences.remove(_storageKey);
  }
}

class Store {
  const Store({
    required this.name,
    required this.location,
    required this.distanceKm,
    required this.prices,
    this.isBigShop = false,
  });

  final String name;
  final String location;
  final double distanceKm;
  final Map<String, double> prices;
  final bool isBigShop;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.group,
    this.aliases = const [],
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String unit;
  final String group;
  final List<String> aliases;
  final bool isFavorite;
}

class ListItem {
  ListItem({
    required this.product,
    this.quantity = 1,
  });

  final Product product;
  int quantity;
}

const products = <Product>[
  Product(
    id: 'butter_streichzart',
    name: 'Streichzart ungesalzen',
    unit: '250 g',
    group: 'butter',
    aliases: ['butter'],
    isFavorite: true,
  ),
  Product(
    id: 'butter_block',
    name: 'Butterblock',
    unit: '250 g',
    group: 'butter',
    aliases: ['butter', 'backen'],
  ),
  Product(
    id: 'milch_35',
    name: 'Vollmilch 3,5 %',
    unit: '1 l',
    group: 'milch',
    aliases: ['milch'],
  ),
  Product(
    id: 'bananen',
    name: 'Bananen',
    unit: '1 kg',
    group: 'obst',
    aliases: ['banane'],
  ),
  Product(
    id: 'weintrauben',
    name: 'Weintrauben',
    unit: '500 g',
    group: 'obst',
    aliases: ['trauben', 'weintraube'],
  ),
  Product(
    id: 'hackfleisch',
    name: 'Hackfleisch gemischt',
    unit: '500 g',
    group: 'fleisch',
    aliases: ['hack', 'hackfleisch'],
  ),
  Product(
    id: 'nudeln',
    name: 'Spaghetti',
    unit: '500 g',
    group: 'nudeln',
    aliases: ['nudeln', 'pasta'],
  ),
];

const stores = <Store>[
  Store(
    name: 'Lidl',
    location: 'Zellingen',
    distanceKm: 1.2,
    prices: {
      'butter_streichzart': 1.99,
      'butter_block': 1.79,
      'milch_35': 1.29,
      'bananen': 1.49,
      'weintrauben': 1.69,
      'hackfleisch': 4.99,
      'nudeln': 0.89,
    },
  ),
  Store(
    name: 'EDEKA',
    location: 'Zellingen',
    distanceKm: 1.4,
    prices: {
      'butter_streichzart': 1.89,
      'butter_block': 2.19,
      'milch_35': 1.39,
      'bananen': 1.59,
      'weintrauben': 2.29,
      'hackfleisch': 5.49,
      'nudeln': 1.29,
    },
  ),
  Store(
    name: 'PENNY',
    location: 'Zellingen',
    distanceKm: 1.1,
    prices: {
      'butter_streichzart': 1.99,
      'butter_block': 1.69,
      'milch_35': 1.19,
      'bananen': 1.49,
      'weintrauben': 1.79,
      'hackfleisch': 4.79,
      'nudeln': 0.79,
    },
  ),
  Store(
    name: 'ALDI Süd',
    location: 'Zellingen',
    distanceKm: 1.6,
    prices: {
      'butter_streichzart': 1.89,
      'butter_block': 1.59,
      'milch_35': 1.15,
      'bananen': 1.39,
      'weintrauben': 1.49,
      'hackfleisch': 4.69,
      'nudeln': 0.75,
    },
  ),
  Store(
    name: 'Netto',
    location: 'Thüngersheim',
    distanceKm: 5.8,
    prices: {
      'butter_streichzart': 2.09,
      'butter_block': 1.89,
      'milch_35': 1.35,
      'bananen': 1.29,
      'weintrauben': 1.39,
      'hackfleisch': 4.99,
      'nudeln': 0.79,
    },
  ),
  Store(
    name: 'REWE',
    location: 'Veitshöchheim',
    distanceKm: 16.5,
    prices: {
      'butter_streichzart': 1.99,
      'butter_block': 2.29,
      'milch_35': 1.49,
      'bananen': 1.49,
      'weintrauben': 1.99,
      'hackfleisch': 5.29,
      'nudeln': 1.19,
    },
  ),
  Store(
    name: 'Kaufland',
    location: 'Würzburg · Nürnberger Straße',
    distanceKm: 25.0,
    isBigShop: true,
    prices: {
      'butter_streichzart': 1.89,
      'butter_block': 1.49,
      'milch_35': 1.19,
      'bananen': 1.19,
      'weintrauben': 1.29,
      'hackfleisch': 4.49,
      'nudeln': 0.69,
    },
  ),
];

class SparzamApp extends StatelessWidget {
  const SparzamApp({
    super.key,
    required this.recentPurchaseStore,
    required this.shoppingListStore,
    required this.initialRecentPurchases,
    required this.initialShoppingList,
  });

  final RecentPurchaseStore recentPurchaseStore;
  final ShoppingListStore shoppingListStore;
  final List<RecentPurchase> initialRecentPurchases;
  final List<ListItem> initialShoppingList;
  final Map<String, String> initialPreferredProductByGroup;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF155EEF);

    return MaterialApp(
      title: 'sparzamApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
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
        recentPurchaseStore: recentPurchaseStore,
        shoppingListStore: shoppingListStore,
        initialRecentPurchases: initialRecentPurchases,
        initialShoppingList: initialShoppingList,
        initialPreferredProductByGroup: initialPreferredProductByGroup,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.recentPurchaseStore,
    required this.shoppingListStore,
    required this.initialRecentPurchases,
    required this.initialShoppingList,
    required this.initialPreferredProductByGroup,
  });

  final RecentPurchaseStore recentPurchaseStore;
  final ShoppingListStore shoppingListStore;
  final List<RecentPurchase> initialRecentPurchases;
  final List<ListItem> initialShoppingList;
  final Map<String, String> initialPreferredProductByGroup;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;
  late List<ListItem> shoppingList;
  late List<RecentPurchase> recentPurchases;

  @override
  void initState() {
    super.initState();
    shoppingList = [...widget.initialShoppingList];
    recentPurchases = [...widget.initialRecentPurchases];
    preferredProductByGroup = {...widget.initialPreferredProductByGroup};
  }

  Future<void> persistShoppingList() {
    return widget.shoppingListStore.save(shoppingList);
  }

  // Persönliche Präferenzen werden dauerhaft gespeichert und beim Start geladen.
  late final Map<String, String> preferredProductByGroup;

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

  Future<void> markPurchased(Product product, int quantity) async {
    final next = await widget.recentPurchaseStore.add(
      product,
      quantity,
      recentPurchases,
    );

    await widget.shoppingListStore.savePreferredProduct(
      product.group,
      product.id,
    );

    setState(() {
      preferredProductByGroup[product.group] = product.id;
      recentPurchases = next;
    });
  }

  void changeQuantity(String productId, int delta) {
    setState(() {
      final index = shoppingList.indexWhere(
        (item) => item.product.id == productId,
      );
      if (index < 0) {
        return;
      }

      final item = shoppingList[index];
      item.quantity += delta;

      if (item.quantity <= 0) {
        shoppingList.removeAt(index);
      }
    });

    persistShoppingList();
  }

  void clearPurchasedItems(Set<String> productIds) {
    if (productIds.isEmpty) {
      return;
    }

    setState(() {
      shoppingList.removeWhere(
        (item) => productIds.contains(item.product.id),
      );
    });

    persistShoppingList();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        itemCount: shoppingList.length,
        onOpenList: () => setState(() => selectedIndex = 1),
        onOpenRoute: () => setState(() => selectedIndex = 2),
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
      ),
      RouteScreen(items: shoppingList),
      const ReceiptScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Liste',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Route',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bon',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.itemCount,
    required this.onOpenList,
    required this.onOpenRoute,
  });

  final int itemCount;
  final VoidCallback onOpenList;
  final VoidCallback onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text(
          'sparzamApp',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dein intelligenter Einkaufsplaner',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(
                    Icons.savings_outlined,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zellingen MVP',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text('7 Testmärkte · Testdaten'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        ActionCard(
          icon: Icons.playlist_add_check,
          title: 'Einkauf planen',
          subtitle: itemCount == 0
              ? 'Erstelle deine erste Einkaufsliste'
              : '${itemCount} Produkte auf deiner Liste',
          onTap: onOpenList,
        ),
        const SizedBox(height: 12),
        ActionCard(
          icon: Icons.route,
          title: 'Beste Route berechnen',
          subtitle: itemCount == 0
              ? 'Füge zuerst Produkte hinzu'
              : 'Preis + Fahrtkosten vergleichen',
          enabled: itemCount > 0,
          onTap: onOpenRoute,
        ),
        const SizedBox(height: 24),
        Text(
          'Deine Testmärkte',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final store in stores)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: store.isBigShop
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                  child: Icon(
                    store.isBigShop ? Icons.local_mall : Icons.storefront,
                    color: store.isBigShop
                        ? Colors.orange.shade700
                        : Colors.blue.shade700,
                  ),
                ),
                title: Text(
                  '${store.name} · ${store.location}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  store.isBigShop
                      ? 'Großeinkauf · ${store.distanceKm.toStringAsFixed(1)} km'
                      : '${store.distanceKm.toStringAsFixed(1)} km entfernt',
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Testdaten: Die Preise sind aktuell noch keine Live-Preise. '
          'Angebote, Coupons und Kassenbonpreise kommen in den nächsten Sprints.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: enabled ? Colors.black54 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onChangeQuantity,
    required this.preferredProductByGroup,
    required this.recentPurchases,
    required this.onPurchased,
    required this.onClearPurchased,
    required this.shoppingListStore,
  });

  final List<ListItem> items;
  final ValueChanged<Product> onAdd;
  final void Function(String productId, int delta) onChangeQuantity;
  final Map<String, String> preferredProductByGroup;
  final List<RecentPurchase> recentPurchases;
  final Future<void> Function(Product product, int quantity) onPurchased;
  final void Function(Set<String> productIds) onClearPurchased;
  final ShoppingListStore shoppingListStore;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final controller = TextEditingController();
  final _inputFocusNode = FocusNode();
  final Set<String> checkedProductIds = <String>{};
  List<RecentPurchase> knownItems = <RecentPurchase>[];

  @override
  void initState() {
    super.initState();
    _loadKnownItems();
  }

  Future<void> _loadKnownItems() async {
    final items = await widget.shoppingListStore.loadKnownItems();
    if (!mounted) {
      return;
    }
    setState(() {
      knownItems = items;
    });
  }

  List<Product> get suggestions {
    final query = controller.text.trim().toLowerCase();

    if (query.isEmpty) {
      return const <Product>[];
    }

    final learnedMatches = knownItems
        .map((item) => item.toProduct())
        .where((product) => product.name.toLowerCase().contains(query))
        .toList();

    final catalogMatches = products.where((product) {
      final haystacks = <String>[
        product.name,
        product.group,
        ...product.aliases,
      ];

      return haystacks.any(
        (value) => value.toLowerCase().contains(query),
      );
    }).toList();

    final combined = <Product>[...learnedMatches, ...catalogMatches];
    final seen = <String>{};
    final matches = combined.where((product) => seen.add(product.id)).toList();

    matches.sort((a, b) {
      final aLearned = knownItems.any((item) => item.id == a.id);
      final bLearned = knownItems.any((item) => item.id == b.id);

      if (aLearned != bLearned) {
        return aLearned ? -1 : 1;
      }

      if (aLearned && bLearned) {
        final aCount = knownItems
            .firstWhere((item) => item.id == a.id)
            .purchaseCount;
        final bCount = knownItems
            .firstWhere((item) => item.id == b.id)
            .purchaseCount;

        if (aCount != bCount) {
          return bCount.compareTo(aCount);
        }
      }

      final aPreferred =
          widget.preferredProductByGroup[a.group] == a.id;
      final bPreferred =
          widget.preferredProductByGroup[b.group] == b.id;

      if (aPreferred != bPreferred) {
        return aPreferred ? -1 : 1;
      }

      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }

      return a.name.compareTo(b.name);
    });

    return matches;
  }

  List<Product> get quickProducts {
    final preferredIds = widget.preferredProductByGroup.values.toSet();
    final preferred = products.where((p) => preferredIds.contains(p.id));
    final favorites = products.where((p) => p.isFavorite);
    final combined = <Product>[...preferred, ...favorites];

    final seen = <String>{};
    return combined.where((p) => seen.add(p.id)).take(5).toList();
  }

  Map<String, List<ListItem>> get itemsByGroup {
    final grouped = <String, List<ListItem>>{};

    for (final item in widget.items) {
      grouped.putIfAbsent(item.product.group, () => []).add(item);
    }

    return grouped;
  }

  String groupLabel(String group) {
    switch (group) {
      case 'butter':
        return 'Milch & Käse';
      case 'milch':
        return 'Milch & Käse';
      case 'obst':
        return 'Obst & Gemüse';
      case 'fleisch':
        return 'Fleisch';
      case 'nudeln':
        return 'Nudeln & Beilagen';
      default:
        return 'Weitere Produkte';
    }
  }

  void _focusShoppingInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _inputFocusNode.requestFocus();
    });
  }

  void add(Product product) {
    widget.onAdd(product);
    controller.clear();
    setState(() {});
    _focusShoppingInput();
  }

  void addCustomProduct() {
    final name = controller.text.trim();
    if (name.isEmpty) {
      return;
    }

    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final product = Product(
      id: 'custom_' + (slug.isEmpty ? 'artikel' : slug),
      name: name,
      unit: 'Artikel',
      group: 'custom',
    );

    widget.onAdd(product);
    controller.clear();
    setState(() {});
    _focusShoppingInput();
  }

  Future<void> toggleChecked(Product product) async {
    final wasChecked = checkedProductIds.contains(product.id);

    setState(() {
      if (wasChecked) {
        checkedProductIds.remove(product.id);
      } else {
        checkedProductIds.add(product.id);
      }
    });

    if (!wasChecked) {
      final item = widget.items.firstWhere(
        (item) => item.product.id == product.id,
      );
      await widget.onPurchased(product, item.quantity);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = itemsByGroup;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Einkaufsliste',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (widget.items.isNotEmpty)
                    Text(
                      '${widget.items.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                focusNode: _inputFocusNode,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    return;
                  }

                  final exactMatch = suggestions.where(
                    (product) => product.name.toLowerCase() == name.toLowerCase(),
                  );

                  if (exactMatch.isNotEmpty) {
                    add(exactMatch.first);
                  } else {
                    addCustomProduct();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Was möchtest du einkaufen?',
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            controller.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final product in suggestions)
                        ListTile(
                          onTap: () => add(product),
                          leading: CircleAvatar(
                            radius: 18,
                            child: Icon(
                              widget.preferredProductByGroup[product.group] ==
                                      product.id
                                  ? Icons.auto_awesome
                                  : Icons.add,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            widget.preferredProductByGroup[product.group] ==
                                    product.id
                                ? '${product.name} · deine Auswahl'
                                : product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(product.unit),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ListTile(
                        onTap: addCustomProduct,
                        leading: const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.playlist_add),
                        ),
                        title: Text(
                          '„${controller.text.trim()}“ zur Liste hinzufügen',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Noch kein bekanntes Produkt – wird trotzdem gespeichert.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ] else if (controller.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    onTap: addCustomProduct,
                    leading: const CircleAvatar(
                      child: Icon(Icons.playlist_add),
                    ),
                    title: Text(
                      '„${controller.text.trim()}“ hinzufügen',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Noch nicht bekannt – trotzdem direkt auf die Einkaufsliste.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  ),
                ),
              ] else if (controller.text.trim().isEmpty &&
                  widget.recentPurchases.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Zuletzt gekauft',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.recentPurchases.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final purchase = widget.recentPurchases[index];
                      return ActionChip(
                        onPressed: () => add(purchase.toProduct()),
                        avatar: const Icon(Icons.history, size: 18),
                        label: Text(
                          purchase.averageQuantity > 1.5
                              ? '${purchase.name} · meist ×${purchase.averageQuantity.round()}'
                              : purchase.name,
                        ),
                      );
                    },
                  ),
                ),
              ] else if (controller.text.trim().isEmpty &&
                  quickProducts.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Schnell hinzufügen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: quickProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final product = quickProducts[index];
                      return ActionChip(
                        onPressed: () => add(product),
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(product.name),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (checkedProductIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FilledButton.icon(
                    onPressed: () {
                      final purchased = {...checkedProductIds};
                      widget.onClearPurchased(purchased);
                      setState(() => checkedProductIds.clear());
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      checkedProductIds.length.toString() +
                          ' erledigte Artikel entfernen',
                    ),
                  ),
                ),
              if (widget.items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 52,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Deine Liste ist noch leer.',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tippe oben ein Produkt ein oder füge es über '
                          '„Schnell hinzufügen“ direkt hinzu.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      groupLabel(entry.key),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < entry.value.length; i++) ...[
                          Builder(
                            builder: (context) {
                              final item = entry.value[i];
                              final checked =
                                  checkedProductIds.contains(item.product.id);

                              return ListTile(
                                onTap: () => toggleChecked(item.product),
                                leading: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: checked
                                        ? Colors.green.shade600
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: checked
                                          ? Colors.green.shade600
                                          : Colors.black26,
                                      width: 2,
                                    ),
                                  ),
                                  child: checked
                                      ? const Icon(
                                          Icons.check,
                                          size: 17,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  item.product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: checked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: checked ? Colors.black45 : null,
                                  ),
                                ),
                                subtitle: Text(
                                  item.quantity > 1
                                      ? '${item.product.unit} · ×${item.quantity}'
                                      : item.product.unit,
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'minus') {
                                      widget.onChangeQuantity(
                                        item.product.id,
                                        -1,
                                      );
                                    } else if (value == 'plus') {
                                      widget.onChangeQuantity(
                                        item.product.id,
                                        1,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'plus',
                                      child: Text('Menge erhöhen'),
                                    ),
                                    PopupMenuItem(
                                      value: 'minus',
                                      child: Text('Menge verringern'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (i < entry.value.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key, required this.items});

  final List<ListItem> items;

  double basketCost(Store store) {
    return items.fold<double>(
      0,
      (sum, item) =>
          sum + ((store.prices[item.product.id] ?? 0) * item.quantity),
    );
  }

  double effectiveCost(Store store) {
    const euroPerKmRoundTrip = 0.22;
    return basketCost(store) + (store.distanceKm * 2 * euroPerKmRoundTrip);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Füge zuerst Produkte zu deiner Einkaufsliste hinzu.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final results = stores.map((store) {
      return RouteResult(
        store: store,
        basket: basketCost(store),
        total: effectiveCost(store),
      );
    }).toList()
      ..sort((a, b) => a.total.compareTo(b.total));

    final best = results.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text(
          'Beste Route',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Erste Testlogik: Warenkorb + geschätzte Hin- und Rückfahrt.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.check)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Aktuell günstigste Einzelroute',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${best.store.name} · ${best.store.location}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${best.total.toStringAsFixed(2)} € Gesamtkosten',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Warenkorb ${best.basket.toStringAsFixed(2)} € · '
                  '${(best.store.distanceKm * 2).toStringAsFixed(1)} km',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Vergleich der 7 Märkte',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final result in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: result.store == best.store
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  child: Icon(
                    result.store == best.store ? Icons.check : Icons.store,
                    color: result.store == best.store
                        ? Colors.green.shade700
                        : Colors.black54,
                  ),
                ),
                title: Text(
                  '${result.store.name} · ${result.store.location}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Warenkorb ${result.basket.toStringAsFixed(2)} € · '
                  '${result.store.distanceKm.toStringAsFixed(1)} km',
                ),
                trailing: Text(
                  '${result.total.toStringAsFixed(2)} €',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Card(
          color: Colors.blue.shade50,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Noch Testdaten: Mehrmarkt-Kombinationen, Angebote, Coupons '
              'und echte Preisquellen werden als nächste Ausbaustufe ergänzt.',
            ),
          ),
        ),
      ],
    );
  }
}

class RouteResult {
  const RouteResult({
    required this.store,
    required this.basket,
    required this.total,
  });

  final Store store;
  final double basket;
  final double total;
}

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Bon fotografieren',
      'Filiale erkennen',
      'Artikel und Preise lesen',
      'Unsichere Zuordnungen bestätigen',
      'Preise in der Historie speichern',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text(
          'Kassenbon',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bon-Erfassung kommt als nächstes',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Die Oberfläche ist vorbereitet. Im nächsten Schritt '
                  'bauen wir Kamera, OCR und das Lernsystem.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.camera_alt_outlined),
                  label: Text('Bon fotografieren'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'So wird sparzamApp lernen',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var index = 0; index < steps.length; index++)
                ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(steps[index]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text(
          'Profil',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.login),
                title: Text('Mit Apple anmelden'),
                subtitle: Text('Kommt mit Supabase im nächsten Sprint'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.directions_car_outlined),
                title: Text('Mobilität'),
                subtitle: Text('Auto · Testwert 0,22 €/km'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.storefront_outlined),
                title: Text('Meine Märkte'),
                subtitle: Text('7 Märkte im Zellingen-MVP'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
