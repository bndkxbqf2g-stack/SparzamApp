import 'package:flutter/material.dart';

void main() {
  runApp(const SparzamApp());
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
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String unit;
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
    isFavorite: true,
  ),
  Product(
    id: 'butter_block',
    name: 'Butterblock',
    unit: '250 g',
  ),
  Product(
    id: 'milch_35',
    name: 'Vollmilch 3,5 %',
    unit: '1 l',
  ),
  Product(
    id: 'bananen',
    name: 'Bananen',
    unit: '1 kg',
  ),
  Product(
    id: 'weintrauben',
    name: 'Weintrauben',
    unit: '500 g',
  ),
  Product(
    id: 'hackfleisch',
    name: 'Hackfleisch gemischt',
    unit: '500 g',
  ),
  Product(
    id: 'nudeln',
    name: 'Spaghetti',
    unit: '500 g',
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
  const SparzamApp({super.key});

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
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;
  final List<ListItem> shoppingList = [];

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
  });

  final List<ListItem> items;
  final ValueChanged<Product> onAdd;
  final void Function(String productId, int delta) onChangeQuantity;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final controller = TextEditingController();

  List<Product> get suggestions {
    final query = controller.text.trim().toLowerCase();

    if (query.isEmpty) {
      return products;
    }

    return products
        .where((product) => product.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text(
          'Einkaufsliste',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Produkt hinzufügen, z. B. Butter',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (final product in suggestions)
                ListTile(
                  leading: Icon(
                    product.isFavorite ? Icons.star : Icons.add_circle_outline,
                    color: product.isFavorite ? Colors.amber.shade700 : null,
                  ),
                  title: Text(
                    product.isFavorite
                        ? '${product.name} · dein Favorit'
                        : product.name,
                  ),
                  subtitle: Text(product.unit),
                  trailing: IconButton(
                    onPressed: () {
                      widget.onAdd(product);
                      controller.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.add),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: widget.items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Deine Liste ist noch leer.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Füge oben Produkte hinzu. Später lernt sparzamApp '
                        'deine Lieblingsprodukte automatisch.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final item in widget.items)
                      ListTile(
                        leading: item.product.isFavorite
                            ? Icon(
                                Icons.star,
                                color: Colors.amber.shade700,
                              )
                            : const Icon(Icons.shopping_basket_outlined),
                        title: Text(
                          item.product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(item.product.unit),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => widget.onChangeQuantity(
                                item.product.id,
                                -1,
                              ),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              onPressed: () => widget.onChangeQuantity(
                                item.product.id,
                                1,
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
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
