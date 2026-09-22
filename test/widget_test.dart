import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/app.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_point.dart';
import 'package:sparzamapp/models/recent_purchase.dart';
import 'package:sparzamapp/models/purchase_record.dart';
import 'package:sparzamapp/services/budget_store.dart';
import 'package:sparzamapp/services/offer_store.dart';
import 'package:sparzamapp/services/recent_purchase_store.dart';
import 'package:sparzamapp/services/purchase_store.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  testWidgets('sparzamApp startet', (tester) async {
    await tester.pumpWidget(
      SparzamApp(
        budgetStore: BudgetStore(),
        offerStore: OfferStore(),
        recentPurchaseStore: RecentPurchaseStore(),
        purchaseStore: PurchaseStore(),
        shoppingListStore: ShoppingListStore(),
        initialBudget: const BudgetPlan(),
        initialOffers: const <Offer>[],
        initialPriceHistory: const <PricePoint>[],
        initialRecentPurchases: const <RecentPurchase>[],
        initialPurchaseHistory: const <PurchaseRecord>[],
        initialShoppingList: <ListItem>[],
        initialPreferredProductByGroup: const <String, String>{},
      ),
    );

    expect(find.text('sparzamApp'), findsOneWidget);
  });
}
