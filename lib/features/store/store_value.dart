import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/store.dart';
import '../route/route_optimizer.dart';
import 'store_shopping_summary.dart';

class StoreValue {
  const StoreValue({
    required this.basketSavings,
    required this.travelCost,
    required this.netAdvantage,
    required this.totalWithTravel,
  });

  final double basketSavings;
  final double travelCost;
  final double netAdvantage;
  final double totalWithTravel;

  bool get isWorthIt => netAdvantage > 0;
  bool get isNeutral => netAdvantage.abs() < 0.005;
}

StoreValue evaluateStoreValue(
  Store store,
  List<ListItem> items,
  List<Offer> offers, {
  DateTime? now,
  Map<String, double>? roadDistances,
  double euroPerKm = 0.22,
  List<MarketPrice> marketPrices = const <MarketPrice>[],
}) {
  final summary = buildStoreShoppingSummary(
    store,
    items,
    offers,
    now: now,
    marketPrices: marketPrices,
  );
  final optimizer = RouteOptimizer(
    items,
    offers,
    roadDistances: roadDistances,
    euroPerKm: euroPerKm,
    marketPrices: marketPrices,
  );
  final travel = optimizer.travelCost([store]);
  final net = summary.savings - travel;

  return StoreValue(
    basketSavings: summary.savings,
    travelCost: travel,
    netAdvantage: net,
    totalWithTravel: summary.total + travel,
  );
}
