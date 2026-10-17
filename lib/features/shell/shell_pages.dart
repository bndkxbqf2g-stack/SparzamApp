import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/named_shopping_list.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../models/purchase_record.dart';
import '../../models/recent_purchase.dart';
import '../../models/replenishment_suggestion.dart';
import '../../models/road_route_matrix.dart';
import '../../models/route_plan.dart';
import '../../models/store.dart';
import '../../services/shopping_list_store.dart';
import '../home/dashboard_data.dart';
import '../home/home_screen.dart';
import '../catalog/prices_hub_screen.dart';
import '../prospects/prospects_screen.dart';
import '../prospects/prospect_feed_status.dart';
import '../../services/prospect_feed_service.dart';
import 'more_screen.dart';
import '../offers/offer_import.dart';
import '../offers/prospect_price_statistics.dart';
import '../offers/offers_screen.dart';
import '../price_gaps/price_gap_priority.dart';
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
  required ValueChanged<ListItem> onSelectFamily,
  required void Function(String productId, String note) onUpdateItemNote,
  required void Function(String productId, bool checked) onUpdateItemChecked,
  required Map<String, String> preferredProductByGroup,
  required List<RecentPurchase> recentPurchases,
  required Future<void> Function(Product product, int quantity) onPurchased,
  required void Function(Set<String> productIds) onClearPurchased,
  required ShoppingListStore shoppingListStore,
  required List<Offer> offers,
  required List<OfferImportRecord> prospectRecords,
  List<ProspectIssue> prospectIssues = const <ProspectIssue>[],
  bool prospectFeedFromCache = false,
  DateTime? prospectFeedGeneratedAt,
  int prospectRegularPriceCount = 0,
  Map<String, int> prospectRegularPriceCountsByStore = const <String, int>{},
  ProspectRegularPricePersistenceStatus prospectRegularPricePersistenceStatus =
      ProspectRegularPricePersistenceStatus.standalone,
  Future<void> Function()? onRefreshProspects,
  bool prospectsRefreshing = false,
  required List<PricePoint> priceHistory,
  required MobilitySettings mobility,
  required List<Product> catalogProducts,
  required List<MarketPrice> marketPrices,
  List<Store> storeCatalog = stores,
  int openPricesMaxAgeDays = 60,
  required List<MarketPrice> priceObservations,
  required List<PriceObservation> historicalPriceObservations,
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  required List<ReplenishmentSuggestion> replenishmentSuggestions,
  required ValueChanged<Map<String, double>> onRoadDistancesChanged,
  required ValueChanged<RoadRouteMatrix?> onRoadMatrixChanged,
  required RoutePlan? currentPlan,
  required double baselineTotal,
  bool baselineHasDataGaps = false,
  required List<PurchaseRecord> purchaseHistory,
  required Future<void> Function() onCompletePurchase,
  required Future<void> Function(PurchaseRecord record) onUpdatePurchase,
  required Future<void> Function(PurchaseRecord record) onDeletePurchase,
  required VoidCallback onEditMobility,
  required VoidCallback onEditStores,
  required int storeCount,
  required VoidCallback onOpenCatalog,
  Future<void> Function(PriceGapPriority gap)? onResolvePriceGap,
  required VoidCallback onEditPriceData,
  required String priceDataSummary,
  required Future<List<MarketPrice>> Function(MarketPrice price) onSavePrice,
  Future<void> Function(List<MarketPrice> prices)? onSavePrices,
  required Future<List<Product>> Function(Product product) onSaveProduct,
  required Future<void> Function() onReceiptObservationsChanged,
  required Future<List<Offer>> Function(Offer offer) onSaveOffer,
  required Future<List<Offer>> Function(Offer offer) onDeleteOffer,
  required VoidCallback onOpenDiagnostics,
  required Future<void> Function() onExportBackup,
  required Future<void> Function() onImportBackup,
  required int dataRevision,
}) => [
  HomeScreen(
    data: dashboard,
    onOpenList: onOpenList,
    onOpenRoute: onOpenRoute,
    onOpenOffers: onOpenOffers,
    onOpenBudget: onOpenBudget,
    onOpenScanner: onOpenScanner,
  ),
  ShoppingListScreen(
    key: ValueKey('shopping-list-$dataRevision'),
    items: shoppingList,
    shoppingLists: shoppingLists,
    activeShoppingListId: activeShoppingListId,
    onSelectShoppingList: onSelectShoppingList,
    onCreateShoppingList: onCreateShoppingList,
    onAdd: onAddProduct,
    onChangeQuantity: onChangeQuantity,
    onSelectFamily: onSelectFamily,
    onUpdateItemNote: onUpdateItemNote,
    onUpdateItemChecked: onUpdateItemChecked,
    preferredProductByGroup: preferredProductByGroup,
    recentPurchases: recentPurchases,
    onPurchased: onPurchased,
    onClearPurchased: onClearPurchased,
    shoppingListStore: shoppingListStore,
    onOpenScanner: onOpenScanner,
    onOpenRoute: onOpenRoute,
    offers: offers,
    priceHistory: priceHistory,
    mobility: mobility,
    catalogProducts: catalogProducts,
    marketPrices: marketPrices,
    openPricesMaxAgeDays: openPricesMaxAgeDays,
    priceObservations: priceObservations,
    historicalPriceObservations: historicalPriceObservations,
    prospectPriceHistory: prospectPriceHistory,
    onSavePrices: onSavePrices ??
        (prices) async {
          for (final price in prices) {
            await onSavePrice(price);
          }
        },
    onCreateProduct: onSaveProduct,
    onReceiptObservationsChanged: onReceiptObservationsChanged,
    onResolvePriceGap: onResolvePriceGap,
    replenishmentSuggestions: replenishmentSuggestions,
  ),
  OffersScreen(
    offers: offers,
    prospectRecords: prospectRecords,
    prospectIssues: prospectIssues,
    generatedAt: prospectFeedGeneratedAt,
    fromCache: prospectFeedFromCache,
    regularPriceCount: prospectRegularPriceCount,
    regularPricePersistenceStatus: prospectRegularPricePersistenceStatus,
    persistedRegularPriceCounts: prospectRegularPriceCountsByStore,
    onRefreshProspects: onRefreshProspects,
    prospectsRefreshing: prospectsRefreshing,
    priceHistory: priceHistory,
    onSave: onSaveOffer,
    onDelete: onDeleteOffer,
    catalogProducts: catalogProducts,
    onAddToShoppingList: onAddProduct,
  ),
  ProspectsScreen(
    records: prospectRecords,
    prospects: prospectIssues,
    fromCache: prospectFeedFromCache,
    generatedAt: prospectFeedGeneratedAt,
    regularPriceCount: prospectRegularPriceCount,
    persistedRegularPriceCounts: prospectRegularPriceCountsByStore,
    regularPricePersistenceStatus: prospectRegularPricePersistenceStatus,
    onRefreshProspects: onRefreshProspects,
    prospectsRefreshing: prospectsRefreshing,
    catalogProducts: catalogProducts,
    onAddProduct: onAddProduct,
    onSaveOffer: onSaveOffer,
  ),
  PricesHubScreen(
    onOpenCatalog: onOpenCatalog,
    onOpenSettings: onEditPriceData,
    summary: priceDataSummary,
    shoppingList: shoppingList,
    offers: offers,
    marketPrices: marketPrices,
    enabledStoreNames: mobility.enabledStoreNames,
    openPricesMaxAgeDays: openPricesMaxAgeDays,
    prospectPriceHistory: prospectPriceHistory,
    prospectFeedGeneratedAt: prospectFeedGeneratedAt,
    prospectFeedFromCache: prospectFeedFromCache,
    prospectRegularPriceCount: prospectRegularPriceCount,
    prospectRegularPriceCountsByStore: prospectRegularPriceCountsByStore,
    prospectRegularPricePersistenceStatus:
        prospectRegularPricePersistenceStatus,
    historicalPriceObservations: historicalPriceObservations,
    catalogProducts: catalogProducts,
    onOpenList: onOpenList,
    onOpenRoute: onOpenRoute,
    onRefreshProspects: onRefreshProspects,
    onResolvePriceGap: onResolvePriceGap,
  ),
  MoreScreen(
    onOpenStores: onEditStores,
    onOpenPriceData: onEditPriceData,
    routePage: RouteScreen(
      items: shoppingList,
      offers: offers,
      mobility: mobility,
      marketPrices: marketPrices,
      storeCatalog: storeCatalog,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
      recentPurchases: recentPurchases,
      historicalPriceObservations: historicalPriceObservations,
      onRoadDistancesChanged: onRoadDistancesChanged,
      onRoadMatrixChanged: onRoadMatrixChanged,
      onResolvePriceGap: onResolvePriceGap,
    ),
    receiptPage: ReceiptScreen(
      plan: currentPlan,
      baselineTotal: baselineTotal,
      baselineHasDataGaps: baselineHasDataGaps,
      history: purchaseHistory,
      onComplete: onCompletePurchase,
      onUpdatePurchase: onUpdatePurchase,
      onDeletePurchase: onDeletePurchase,
      catalogProducts: catalogProducts,
      onSavePrices: onSavePrices ??
          (prices) async {
            for (final price in prices) {
              await onSavePrice(price);
            }
          },
      onCreateProduct: onSaveProduct,
    ),
    profilePage: ProfileScreen(
      mobility: mobility,
      onEditMobility: onEditMobility,
      onEditStores: onEditStores,
      storeCount: storeCount,
      onOpenCatalog: onOpenCatalog,
      productCount: catalogProducts.length,
      onEditPriceData: onEditPriceData,
      priceDataSummary: priceDataSummary,
      onOpenDiagnostics: onOpenDiagnostics,
      onExportBackup: onExportBackup,
      onImportBackup: onImportBackup,
    ),
  ),
];

