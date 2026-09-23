import 'package:flutter/material.dart';

import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/named_shopping_list.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import '../../models/purchase_record.dart';
import '../../models/recent_purchase.dart';
import '../../models/replenishment_suggestion.dart';
import '../../models/road_route_matrix.dart';
import '../../models/route_plan.dart';
import '../../services/shopping_list_store.dart';
import '../home/dashboard_data.dart';
import '../home/home_screen.dart';
import '../offers/offers_screen.dart';
import '../profile/profile_screen.dart';
import '../receipt/receipt_screen.dart';
import '../route/route_screen.dart';
import '../shopping_list/shopping_list_screen.dart';

List<Widget> buildShellPages({
  required DashboardData dashboard,
  required VoidCallback onOpenList,
  required VoidCallback onOpenRoute,
  required VoidCallback onOpenOffers,
  required VoidCallback onOpenBudget,
  required VoidCallback onOpenScanner,
  required List<ListItem> shoppingList,
  required List<NamedShoppingList> shoppingLists,
  required String activeShoppingListId,
  required Future<void> Function(String id) onSelectShoppingList,
  required Future<void> Function(String name) onCreateShoppingList,
  required ValueChanged<Product> onAddProduct,
  required void Function(String productId, int delta) onChangeQuantity,
  required void Function(String productId, String note) onUpdateItemNote,
  required void Function(String productId, bool checked) onUpdateItemChecked,
  required Map<String, String> preferredProductByGroup,
  required List<RecentPurchase> recentPurchases,
  required Future<void> Function(Product product, int quantity) onPurchased,
  required void Function(Set<String> productIds) onClearPurchased,
  required ShoppingListStore shoppingListStore,
  required List<Offer> offers,
  required List<PricePoint> priceHistory,
  required MobilitySettings mobility,
  required List<Product> catalogProducts,
  required List<MarketPrice> marketPrices,
  required List<ReplenishmentSuggestion> replenishmentSuggestions,
  required ValueChanged<Map<String, double>> onRoadDistancesChanged,
  required ValueChanged<RoadRouteMatrix?> onRoadMatrixChanged,
  required RoutePlan? currentPlan,
  required double baselineTotal,
  required List<PurchaseRecord> purchaseHistory,
  required Future<void> Function() onCompletePurchase,
  required Future<void> Function(PurchaseRecord record) onUpdatePurchase,
  required Future<void> Function(PurchaseRecord record) onDeletePurchase,
  required VoidCallback onEditMobility,
  required VoidCallback onEditStores,
  required int storeCount,
  required VoidCallback onOpenCatalog,
  required VoidCallback onEditPriceData,
  required String priceDataSummary,
  required Future<List<MarketPrice>> Function(MarketPrice price) onSavePrice,
  required Future<List<Offer>> Function(Offer offer) onSaveOffer,
  required Future<List<Offer>> Function(Offer offer) onDeleteOffer,
  required VoidCallback onOpenDiagnostics,
}) =>
    [
      HomeScreen(
        data: dashboard,
        onOpenList: onOpenList,
        onOpenRoute: onOpenRoute,
        onOpenOffers: onOpenOffers,
        onOpenBudget: onOpenBudget,
        onOpenScanner: onOpenScanner,
      ),
      ShoppingListScreen(
        items: shoppingList,
        shoppingLists: shoppingLists,
        activeShoppingListId: activeShoppingListId,
        onSelectShoppingList: onSelectShoppingList,
        onCreateShoppingList: onCreateShoppingList,
        onAdd: onAddProduct,
        onChangeQuantity: onChangeQuantity,
        onUpdateItemNote: onUpdateItemNote,
        onUpdateItemChecked: onUpdateItemChecked,
        preferredProductByGroup: preferredProductByGroup,
        recentPurchases: recentPurchases,
        onPurchased: onPurchased,
        onClearPurchased: onClearPurchased,
        shoppingListStore: shoppingListStore,
        onOpenScanner: onOpenScanner,
        offers: offers,
        priceHistory: priceHistory,
        mobility: mobility,
        catalogProducts: catalogProducts,
        marketPrices: marketPrices,
        replenishmentSuggestions: replenishmentSuggestions,
      ),
      OffersScreen(
        offers: offers,
        priceHistory: priceHistory,
        onSave: onSaveOffer,
        onDelete: onDeleteOffer,
        catalogProducts: catalogProducts,
      ),
      RouteScreen(
        items: shoppingList,
        offers: offers,
        mobility: mobility,
        marketPrices: marketPrices,
        onRoadDistancesChanged: onRoadDistancesChanged,
        onRoadMatrixChanged: onRoadMatrixChanged,
      ),
      ReceiptScreen(
        plan: currentPlan,
        baselineTotal: baselineTotal,
        history: purchaseHistory,
        onComplete: onCompletePurchase,
        onUpdatePurchase: onUpdatePurchase,
        onDeletePurchase: onDeletePurchase,
        catalogProducts: catalogProducts,
        onSavePrices: (prices) async {
          for (final price in prices) {
            await onSavePrice(price);
          }
        },
      ),
      ProfileScreen(
        mobility: mobility,
        onEditMobility: onEditMobility,
        onEditStores: onEditStores,
        storeCount: storeCount,
        onOpenCatalog: onOpenCatalog,
        productCount: catalogProducts.length,
        onEditPriceData: onEditPriceData,
        priceDataSummary: priceDataSummary,
        onOpenDiagnostics: onOpenDiagnostics,
      ),
    ];
