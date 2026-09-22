import 'package:flutter/material.dart';

import 'app.dart';
import 'services/budget_store.dart';
import 'services/offer_store.dart';
import 'services/price_history_store.dart';
import 'services/recent_purchase_store.dart';
import 'services/purchase_store.dart';
import 'services/shopping_list_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final budgetStore = BudgetStore();
  final offerStore = OfferStore();
  final priceHistoryStore = PriceHistoryStore();
  final recentPurchaseStore = RecentPurchaseStore();
  final purchaseStore = PurchaseStore();
  final shoppingListStore = ShoppingListStore();

  runApp(
    SparzamApp(
      budgetStore: budgetStore,
      offerStore: offerStore,
      recentPurchaseStore: recentPurchaseStore,
      purchaseStore: purchaseStore,
      shoppingListStore: shoppingListStore,
      initialBudget: await budgetStore.load(),
      initialOffers: await offerStore.load(),
      initialPriceHistory: await priceHistoryStore.load(),
      initialRecentPurchases: await recentPurchaseStore.load(),
      initialPurchaseHistory: await purchaseStore.load(),
      initialShoppingList: await shoppingListStore.load(),
      initialPreferredProductByGroup:
          await shoppingListStore.loadPreferredProducts(),
    ),
  );
}
