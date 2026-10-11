import 'dart:convert';

import '../models/budget_plan.dart';
import '../models/list_item.dart';
import '../models/market_price.dart';
import '../models/mobility_settings.dart';
import '../models/named_shopping_list.dart';
import '../models/offer.dart';
import '../models/price_data_settings.dart';
import '../models/price_observation.dart';
import '../models/price_point.dart';
import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/receipt_alias.dart';
import '../models/receipt_observation.dart';
import '../models/recent_purchase.dart';
import '../models/road_route_matrix.dart';

/// Versioned, local-only application data. Receipt files and diagnostic logs
/// are deliberately not part of the backup: the backup contains the parsed
/// evidence and references, never copies of private source files.
class AppBackup {
  const AppBackup({
    required this.createdAt,
    required this.budget,
    required this.mobility,
    required this.priceDataSettings,
    required this.activeShoppingListId,
    required this.shoppingList,
    required this.namedLists,
    required this.offers,
    required this.marketPrices,
    required this.customProducts,
    required this.priceHistory,
    required this.recentPurchases,
    required this.purchaseHistory,
    required this.preferredProductByGroup,
    required this.receiptObservations,
    required this.priceObservations,
    required this.receiptAliases,
    required this.roadDistances,
    required this.roadMatrix,
    required this.knownItems,
    required this.aisleOrder,
    required this.tileView,
  });

  static const schemaVersion = 1;

  final DateTime createdAt;
  final BudgetPlan budget;
  final MobilitySettings mobility;
  final PriceDataSettings priceDataSettings;
  final String activeShoppingListId;
  final List<ListItem> shoppingList;
  final List<NamedShoppingList> namedLists;
  final List<Offer> offers;
  final List<MarketPrice> marketPrices;
  final List<Product> customProducts;
  final List<PricePoint> priceHistory;
  final List<RecentPurchase> recentPurchases;
  final List<PurchaseRecord> purchaseHistory;
  final Map<String, String> preferredProductByGroup;
  final List<ReceiptObservation> receiptObservations;
  final List<PriceObservation> priceObservations;
  final List<ReceiptAlias> receiptAliases;
  final Map<String, double> roadDistances;
  final RoadRouteMatrix? roadMatrix;
  final List<RecentPurchase> knownItems;
  final List<String> aisleOrder;
  final bool tileView;

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toIso8601String(),
    'budget': {
      'monthlyBudget': budget.monthlyBudget,
      'foodBudget': budget.foodBudget,
      'foodSpent': budget.foodSpent,
    },
    'mobility': mobility.toJson(),
    'priceDataSettings': priceDataSettings.toJson(),
    'activeShoppingListId': activeShoppingListId,
    'shoppingList': shoppingList.map(_listItemToJson).toList(),
    'namedLists': namedLists.map((list) => list.toJson()).toList(),
    'offers': offers.map((offer) => jsonDecode(offer.toJson())).toList(),
    'marketPrices': marketPrices.map((price) => price.toJson()).toList(),
    'customProducts': customProducts
        .map((product) => product.toJson())
        .toList(),
    'priceHistory': priceHistory
        .map((point) => jsonDecode(point.toJson()))
        .toList(),
    'recentPurchases': recentPurchases
        .map((purchase) => jsonDecode(purchase.toJson()))
        .toList(),
    'purchaseHistory': purchaseHistory
        .map((purchase) => jsonDecode(purchase.toJson()))
        .toList(),
    'preferredProductByGroup': preferredProductByGroup,
    'receiptObservations': receiptObservations
        .map((item) => item.toJson())
        .toList(),
    'priceObservations': priceObservations
        .map((item) => item.toJson())
        .toList(),
    'receiptAliases': receiptAliases.map((item) => item.toJson()).toList(),
    'roadDistances': roadDistances,
    'roadMatrix': roadMatrix?.toJson(),
    'knownItems': knownItems.map((item) => jsonDecode(item.toJson())).toList(),
    'aisleOrder': aisleOrder,
    'tileView': tileView,
  };

  factory AppBackup.fromJson(Map<String, dynamic> json) {
    final version = (json['schemaVersion'] as num?)?.toInt();
    if (version != schemaVersion) {
      throw FormatException(
        'Nicht unterstützte Backup-Version: ${json['schemaVersion']}',
      );
    }
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    if (createdAt == null) throw const FormatException('Backup-Datum fehlt');

    final budgetMap = _map(json['budget'], 'budget');
    final budget = BudgetPlan(
      monthlyBudget: _nonNegativeFinite(
        budgetMap['monthlyBudget'],
        'monthlyBudget',
      ),
      foodBudget: _nonNegativeFinite(budgetMap['foodBudget'], 'foodBudget'),
      foodSpent: _nonNegativeFinite(budgetMap['foodSpent'], 'foodSpent'),
    );

    return AppBackup(
      createdAt: createdAt,
      budget: budget,
      mobility: MobilitySettings.fromJson(_map(json['mobility'], 'mobility')),
      priceDataSettings: PriceDataSettings.fromJson(
        _map(json['priceDataSettings'], 'priceDataSettings'),
      ),
      activeShoppingListId:
          (json['activeShoppingListId'] as String?)?.trim().isNotEmpty == true
          ? (json['activeShoppingListId'] as String).trim()
          : 'default',
      shoppingList: _list(
        json['shoppingList'],
        'shoppingList',
        _listItemFromJson,
      ),
      namedLists: _list(
        json['namedLists'],
        'namedLists',
        (value) => NamedShoppingList.fromJson(_map(value, 'namedList')),
      ),
      offers: _list(
        json['offers'],
        'offers',
        (value) => Offer.fromJson(jsonEncode(_map(value, 'offer'))),
      ),
      marketPrices: _list(
        json['marketPrices'],
        'marketPrices',
        (value) => MarketPrice.fromJson(_map(value, 'marketPrice')),
      ),
      customProducts: _list(
        json['customProducts'],
        'customProducts',
        (value) => Product.fromJson(_map(value, 'product')),
      ),
      priceHistory: _list(
        json['priceHistory'],
        'priceHistory',
        (value) => PricePoint.fromJson(jsonEncode(_map(value, 'priceHistory'))),
      ),
      recentPurchases: _list(
        json['recentPurchases'],
        'recentPurchases',
        (value) =>
            RecentPurchase.fromJson(jsonEncode(_map(value, 'recentPurchase'))),
      ),
      purchaseHistory: _list(
        json['purchaseHistory'],
        'purchaseHistory',
        (value) => PurchaseRecord.fromJson(jsonEncode(_map(value, 'purchase'))),
      ),
      preferredProductByGroup: _stringMap(
        json['preferredProductByGroup'],
        'preferredProductByGroup',
      ),
      receiptObservations: _list(
        json['receiptObservations'],
        'receiptObservations',
        (value) =>
            ReceiptObservation.fromJson(_map(value, 'receiptObservation')),
      ),
      priceObservations: _list(
        json['priceObservations'],
        'priceObservations',
        (value) => PriceObservation.fromJson(_map(value, 'priceObservation')),
      ),
      receiptAliases: _list(
        json['receiptAliases'],
        'receiptAliases',
        (value) => ReceiptAlias.fromJson(_map(value, 'receiptAlias')),
      ),
      roadDistances: _doubleMap(json['roadDistances'], 'roadDistances'),
      roadMatrix: json['roadMatrix'] == null
          ? null
          : RoadRouteMatrix.fromJson(_map(json['roadMatrix'], 'roadMatrix')),
      knownItems: _list(
        json['knownItems'],
        'knownItems',
        (value) =>
            RecentPurchase.fromJson(jsonEncode(_map(value, 'knownItem'))),
      ),
      aisleOrder: _stringList(json['aisleOrder'], 'aisleOrder'),
      tileView: json['tileView'] as bool? ?? true,
    );
  }

  static AppBackup decode(String value) {
    final decoded = jsonDecode(value);
    return AppBackup.fromJson(_map(decoded, 'backup'));
  }
}

Map<String, dynamic> _listItemToJson(ListItem item) => {
  'product': item.product.toJson(),
  'quantity': item.quantity,
  'note': item.note,
  'checked': item.checked,
};

ListItem _listItemFromJson(Object? value) {
  final json = _map(value, 'listItem');
  final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
  if (quantity <= 0) throw const FormatException('Ungültige Listenmenge');
  return ListItem(
    product: Product.fromJson(_map(json['product'], 'listItem.product')),
    quantity: quantity,
    note: json['note'] as String? ?? '',
    checked: json['checked'] as bool? ?? false,
  );
}

Map<String, dynamic> _map(Object? value, String name) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw FormatException('Backup-Feld "$name" ist ungültig');
}

List<T> _list<T>(Object? value, String name, T Function(Object? value) parse) {
  if (value is! List) throw FormatException('Backup-Feld "$name" ist ungültig');
  return [for (final entry in value) parse(entry)];
}

List<String> _stringList(Object? value, String name) {
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('Backup-Feld "$name" ist ungültig');
  }
  return value.cast<String>();
}

Map<String, String> _stringMap(Object? value, String name) {
  final map = _map(value, name);
  if (map.values.any((entry) => entry is! String)) {
    throw FormatException('Backup-Feld "$name" ist ungültig');
  }
  return map.map((key, value) => MapEntry(key, value as String));
}

Map<String, double> _doubleMap(Object? value, String name) {
  final map = _map(value, name);
  final result = <String, double>{};
  for (final entry in map.entries) {
    final number = entry.value is num
        ? (entry.value as num).toDouble()
        : double.nan;
    if (!number.isFinite || number < 0) {
      throw FormatException('Backup-Feld "$name" enthält eine ungültige Zahl');
    }
    result[entry.key] = number;
  }
  return result;
}

double _nonNegativeFinite(Object? value, String name) {
  final number = value is num ? value.toDouble() : double.nan;
  if (!number.isFinite || number < 0) {
    throw FormatException('Backup-Feld "$name" enthält eine ungültige Zahl');
  }
  return number;
}
