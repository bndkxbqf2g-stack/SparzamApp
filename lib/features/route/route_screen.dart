import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../../models/road_route_matrix.dart';
import '../../models/route_plan.dart';
import '../../models/recent_purchase.dart';
import '../../services/road_distance_service.dart';
import '../../services/road_distance_store.dart';
import '../../services/road_route_matrix_store.dart';
import '../price_gaps/price_gap_card.dart';
import '../price_gaps/price_gap_history.dart';
import '../price_gaps/price_gap_priority.dart';
import 'route_alternative_card.dart';
import 'route_cost_breakdown_card.dart';
import 'route_recommendation.dart';
import 'route_recommendation_card.dart';
import 'route_optimizer.dart';
import 'route_travel_distance.dart';
import 'route_price_evidence.dart';
import 'route_price_evidence_card.dart';
import 'route_savings.dart';
import 'route_store_card.dart';
import 'route_summary_card.dart';
import 'travel_estimator.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({
    super.key,
    required this.items,
    required this.offers,
    required this.mobility,
    required this.marketPrices,
    this.openPricesMaxAgeDays = 60,
    this.recentPurchases = const <RecentPurchase>[],
    this.historicalPriceObservations = const <PriceObservation>[],
    this.onRoadDistancesChanged,
    this.onRoadMatrixChanged,
    this.onResolvePriceGap,
  });

  final List<ListItem> items;
  final List<Offer> offers;
  final MobilitySettings mobility;
  final List<MarketPrice> marketPrices;
  final int openPricesMaxAgeDays;
  final List<RecentPurchase> recentPurchases;
  final List<PriceObservation> historicalPriceObservations;
  final ValueChanged<Map<String, double>>? onRoadDistancesChanged;
  final ValueChanged<RoadRouteMatrix?>? onRoadMatrixChanged;
  final Future<void> Function(PriceGapPriority gap)? onResolvePriceGap;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final cache = RoadDistanceStore();
  final matrixCache = RoadRouteMatrixStore();
  late RoadDistanceService service;
  Map<String, double> roadDistances = <String, double>{};
  RoadRouteMatrix? roadMatrix;
  bool loadingRoadDistances = false;
  int _distanceRequestRevision = 0;

  RouteOptimizer? _optimizerCache;
  List<ListItem>? _optimizerItems;
  List<Offer>? _optimizerOffers;
  List<MarketPrice>? _optimizerMarketPrices;
  Map<String, double>? _optimizerRoadDistances;
  RoadRouteMatrix? _optimizerRoadMatrix;
  MobilitySettings? _optimizerMobility;
  int _optimizerOpenPricesMaxAgeDays = -1;
  int _optimizerDayKey = -1;

  _RouteComputation? _routeComputationCache;
  RouteOptimizer? _routeComputationOptimizer;
  List<RecentPurchase>? _routeComputationRecentPurchases;
  List<PriceObservation>? _routeComputationHistory;
  MobilitySettings? _routeComputationMobility;
  Map<String, double>? _routeComputationRoadDistances;
  RoadRouteMatrix? _routeComputationRoadMatrix;

  @override
  void initState() {
    super.initState();
    service = RoadDistanceService(originAddress: widget.mobility.startAddress);
    _loadRoadDistances();
  }

  @override
  void didUpdateWidget(covariant RouteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mobility.startAddress != widget.mobility.startAddress) {
      _distanceRequestRevision++;
      service.close();
      service = RoadDistanceService(
        originAddress: widget.mobility.startAddress,
      );
      roadDistances = <String, double>{};
      roadMatrix = null;
      loadingRoadDistances = false;
      _loadRoadDistances();
    }
  }

  Future<void> _loadRoadDistances() async {
    final revision = ++_distanceRequestRevision;
    final originAddress = widget.mobility.startAddress;
    Map<String, double> loaded = <String, double>{};
    RoadRouteMatrix? matrix;
    try {
      loaded = await cache.load(widget.mobility.startAddress);
      matrix = await matrixCache.load(widget.mobility.startAddress);
    } catch (_) {
      // Offline storage is an optimization. A corrupt or unavailable cache
      // must not prevent the route screen from rendering its fallback values.
    }
    if (!mounted ||
        revision != _distanceRequestRevision ||
        originAddress != widget.mobility.startAddress) {
      return;
    }
    setState(() {
      roadDistances = loaded;
      roadMatrix = matrix;
    });
  }

  Future<void> _refreshRoadDistances() async {
    if (loadingRoadDistances) return;
    final revision = ++_distanceRequestRevision;
    final originAddress = widget.mobility.startAddress;
    setState(() => loadingRoadDistances = true);

    final destinations = {
      for (final store in stores)
        if (widget.mobility.isStoreEnabled(store.name) &&
            store.address.isNotEmpty)
          store.name: store.address,
    };
    try {
      final matrix = await service.fetchMatrix(destinations);
      if (!mounted ||
          revision != _distanceRequestRevision ||
          originAddress != widget.mobility.startAddress) {
        return;
      }

      final next = {...roadDistances};
      if (matrix != null) {
        for (final store in stores) {
          final distance = matrix.distance(RoadRouteMatrix.origin, store.name);
          if (distance != null && distance > 0) {
            next[store.name] = distance;
          }
        }
        await matrixCache.save(matrix);
      }

      await cache.save(originAddress, next);
      if (!mounted ||
          revision != _distanceRequestRevision ||
          originAddress != widget.mobility.startAddress) {
        return;
      }
      setState(() {
        roadDistances = next;
        roadMatrix = matrix ?? roadMatrix;
      });
      widget.onRoadDistancesChanged?.call(next);
      widget.onRoadMatrixChanged?.call(matrix ?? roadMatrix);
    } catch (_) {
      if (!mounted || revision != _distanceRequestRevision) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Straßenstrecke konnte nicht aktualisiert werden.'),
        ),
      );
    } finally {
      if (mounted && revision == _distanceRequestRevision) {
        setState(() => loadingRoadDistances = false);
      }
    }
  }

  @override
  void dispose() {
    service.close();
    super.dispose();
  }

  bool _sameListReferences<T>(
    List<T>? previous,
    List<T> current,
  ) {
    if (previous == null || previous.length != current.length) return false;
    for (var index = 0; index < current.length; index++) {
      if (!identical(previous[index], current[index])) return false;
    }
    return true;
  }

  int _dayKey(DateTime value) =>
      value.year * 10000 + value.month * 100 + value.day;

  RouteOptimizer _optimizerForCurrentInputs() {
    final today = DateTime.now();
    final dayKey = _dayKey(today);
    final cached = _optimizerCache;
    if (cached != null &&
        _sameListReferences(_optimizerItems, widget.items) &&
        _sameListReferences(_optimizerOffers, widget.offers) &&
        _sameListReferences(_optimizerMarketPrices, widget.marketPrices) &&
        identical(_optimizerRoadDistances, roadDistances) &&
        identical(_optimizerRoadMatrix, roadMatrix) &&
        identical(_optimizerMobility, widget.mobility) &&
        _optimizerOpenPricesMaxAgeDays == widget.openPricesMaxAgeDays &&
        _optimizerDayKey == dayKey) {
      return cached;
    }

    final next = RouteOptimizer(
      widget.items,
      widget.offers,
      roadDistances: roadDistances,
      euroPerKm: widget.mobility.effectiveEuroPerKm,
      maxStores: widget.mobility.maxStores,
      minExtraStoreSavings: widget.mobility.minExtraStoreSavings,
      additionalStoreCost: widget.mobility.additionalStoreCost,
      timeValuePerHour: widget.mobility.timeValuePerHour,
      travelMinutesPerKm: 60 / widget.mobility.mode.averageSpeedKmh,
      enabledStoreNames: widget.mobility.enabledStoreNames,
      marketPrices: widget.marketPrices,
      openPricesMaxAgeDays: widget.openPricesMaxAgeDays,
      roadMatrix: widget.mobility.mode == MobilityMode.car ? roadMatrix : null,
      now: today,
    );
    _optimizerCache = next;
    _optimizerItems = widget.items;
    _optimizerOffers = widget.offers;
    _optimizerMarketPrices = widget.marketPrices;
    _optimizerRoadDistances = roadDistances;
    _optimizerRoadMatrix = roadMatrix;
    _optimizerMobility = widget.mobility;
    _optimizerOpenPricesMaxAgeDays = widget.openPricesMaxAgeDays;
    _optimizerDayKey = dayKey;
    return next;
  }

  _RouteComputation _routeComputationForCurrentInputs(
    RouteOptimizer optimizer,
  ) {
    final cached = _routeComputationCache;
    if (cached != null &&
        identical(_routeComputationOptimizer, optimizer) &&
        identical(
          _routeComputationRecentPurchases,
          widget.recentPurchases,
        ) &&
        identical(
          _routeComputationHistory,
          widget.historicalPriceObservations,
        ) &&
        identical(_routeComputationMobility, widget.mobility) &&
        identical(_routeComputationRoadDistances, roadDistances) &&
        identical(_routeComputationRoadMatrix, roadMatrix)) {
      return cached;
    }

    final best = optimizer.bestPlan();
    final priceGaps = _buildPriceGaps(
      optimizer,
      best?.unassigned ?? widget.items,
      recentPurchases: widget.recentPurchases,
      historicalPriceObservations: widget.historicalPriceObservations,
    );

    late final _RouteComputation next;
    if (best == null) {
      next = _RouteComputation(
        best: null,
        priceGaps: priceGaps,
      );
    } else {
      final alternatives = optimizer.alternatives();
      final cheapest = alternatives.first;
      final single = optimizer.bestSingleStorePlan();
      final optimizedTravel = optimizer.travelRoute(best.stores);
      next = _RouteComputation(
        best: best,
        priceGaps: priceGaps,
        priceEvidence: summarizeRoutePriceEvidence(best, optimizer.prices),
        single: single,
        savings: single == null
            ? 0.0
            : single.planningScore - best.planningScore,
        offerSavings: routeOfferSavings(best, optimizer.prices),
        visibleAlternatives: _uniqueAlternatives(alternatives),
        cheapest: cheapest,
        travel: estimateRoundTrips(
          best.stores,
          mobility: widget.mobility,
          roadDistances: roadDistances,
          roadMatrix: widget.mobility.mode == MobilityMode.car
              ? roadMatrix
              : null,
        ),
        recommendation: buildRouteRecommendationInfo(
          recommended: best,
          cheapest: cheapest,
          singleStore: single,
          mobility: widget.mobility,
        ),
        optimizedTravel: optimizedTravel,
        realCount: roadDistances.entries
            .where((entry) => widget.mobility.isStoreEnabled(entry.key))
            .length,
      );
    }

    _routeComputationCache = next;
    _routeComputationOptimizer = optimizer;
    _routeComputationRecentPurchases = widget.recentPurchases;
    _routeComputationHistory = widget.historicalPriceObservations;
    _routeComputationMobility = widget.mobility;
    _routeComputationRoadDistances = roadDistances;
    _routeComputationRoadMatrix = roadMatrix;
    return next;
  }
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const _EmptyRoute();

    final optimizer = _optimizerForCurrentInputs();
    final computation = _routeComputationForCurrentInputs(optimizer);
    final best = computation.best;
    final priceGaps = computation.priceGaps;
    if (best == null) {
      return _MissingPrices(
        gaps: priceGaps,
        onResolvePriceGap: widget.onResolvePriceGap,
      );
    }
    final priceEvidence = computation.priceEvidence!;
    final single = computation.single;
    final savings = computation.savings;
    final offerSavings = computation.offerSavings;
    final visibleAlternatives = computation.visibleAlternatives;
    final cheapest = computation.cheapest!;
    final travel = computation.travel!;
    final recommendation = computation.recommendation!;
    final optimizedTravel = computation.optimizedTravel!;
    final realCount = computation.realCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text(
          'Einkaufsoptimierung',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Verglichen werden Normalpreise, aktive Angebote, Coupons, '
          'Cashback, Preisaktualität, Wegeaufwand und deine persönlichen Routenregeln.',
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(realCount > 0 ? Icons.route : Icons.route_outlined),
            title: Text(
              realCount > 0
                  ? 'Straßenentfernungen aktiv'
                  : 'Noch mit hinterlegten Entfernungen',
            ),
            subtitle: Text(
              realCount > 0
                  ? '$realCount Märkte mit realer Fahrstrecke · Start: ${widget.mobility.startAddress}'
                  : 'Tippe auf Aktualisieren, um reale Fahrstrecken zu laden.',
            ),
            trailing: loadingRoadDistances
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: 'Straßenentfernungen aktualisieren',
                    onPressed: _refreshRoadDistances,
                    icon: const Icon(Icons.refresh),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        RouteSummaryCard(
          best: best,
          extraSavings: savings,
          offerSavings: offerSavings,
        ),
        const SizedBox(height: 10),
        RouteCostBreakdownCard(plan: best),
        if (priceEvidence.hasEvidence) ...[
          const SizedBox(height: 10),
          RoutePriceEvidenceCard(summary: priceEvidence),
        ],
        if (priceGaps.isNotEmpty) ...[
          const SizedBox(height: 10),
          PriceGapCard(
            gaps: priceGaps,
            onResolveGap: widget.onResolvePriceGap,
            description:
                'Die Reihenfolge nutzt fehlende Marktbelege, Grundbedarf, '
                'deine bisherigen Käufe, historische Preisniveaus und '
                'Listenmenge. Historische Werte sind keine aktuellen '
                'Marktpreise.',
          ),
        ],
        const SizedBox(height: 10),
        RouteRecommendationCard(
          info: recommendation,
          travelLabel: travel.durationLabel,
          mobilityLabel: widget.mobility.mode.label,
        ),
        if (best.stores.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.alt_route),
              title: Text(
                [
                  'Start',
                  ...best.stores.map((store) => store.name),
                  'Start',
                ].join(' → '),
              ),
              subtitle: Text(
                optimizedTravel.usesRoadMatrix
                    ? '${optimizedTravel.distanceKm.toStringAsFixed(1)} km · '
                          'optimierte Straßenroute'
                    : '${optimizedTravel.distanceKm.toStringAsFixed(1)} km · '
                          'Fallback-Distanzen',
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _Title('Dein Einkaufsplan'),
        const SizedBox(height: 10),
        for (final store in best.stores)
          RouteStoreCard(
            store: store,
            items: best.assignments[store]!,
            prices: optimizer.prices,
          ),
        const SizedBox(height: 18),
        _Title('Vergleich'),
        const SizedBox(height: 10),
        for (final plan in visibleAlternatives.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RouteAlternativeCard(
              plan: plan,
              travelLabel: estimateRoundTrips(
                plan.stores,
                mobility: widget.mobility,
                roadDistances: roadDistances,
                roadMatrix: widget.mobility.mode == MobilityMode.car
                    ? roadMatrix
                    : null,
              ).durationLabel,
            ),
          ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.mobility.mode == MobilityMode.car
                  ? '${optimizedTravel.usesRoadMatrix ? 'Fahrtkosten: optimierte Mehrmarkt-Straßenroute × '
                                  '${widget.mobility.effectiveEuroPerKm.toStringAsFixed(2)} €/km (aus ${widget.mobility.fuelConsumptionLitersPer100Km.toStringAsFixed(1)} l/100 km × ${widget.mobility.fuelPricePerLiter.toStringAsFixed(2)} €/l).' : 'Fahrtkosten: aktuell '
                                  '${widget.mobility.effectiveEuroPerKm.toStringAsFixed(2)} €/km '
                                  'auf Basis der hinterlegten Fallback-Distanzen.'}'
                        '${widget.mobility.timeValuePerHour > 0 ? ' Zeitwert: ${widget.mobility.timeValuePerHour.toStringAsFixed(2)} €/Std. '
                                  'wird im Planungswert berücksichtigt.' : ' Wegezeit wird angezeigt; ein optionaler Zeitwert kann in Mobilität & Route gesetzt werden.'}'
                  : '${widget.mobility.mode.label}: keine monetären Fahrtkosten. '
                        'Die Strecke wird weiterhin für die geschätzte Wegezeit verwendet.'
                        '${widget.mobility.timeValuePerHour > 0 ? ' Zeitwert: ${widget.mobility.timeValuePerHour.toStringAsFixed(2)} €/Std. '
                                  'wird im Planungswert berücksichtigt.' : ''}',
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteComputation {
  const _RouteComputation({
    required this.best,
    required this.priceGaps,
    this.priceEvidence,
    this.single,
    this.savings = 0,
    this.offerSavings = 0,
    this.visibleAlternatives = const <RoutePlan>[],
    this.cheapest,
    this.travel,
    this.recommendation,
    this.optimizedTravel,
    this.realCount = 0,
  });

  final RoutePlan? best;
  final List<PriceGapPriority> priceGaps;
  final RoutePriceEvidenceSummary? priceEvidence;
  final RoutePlan? single;
  final double savings;
  final double offerSavings;
  final List<RoutePlan> visibleAlternatives;
  final RoutePlan? cheapest;
  final TravelEstimate? travel;
  final RouteRecommendationInfo? recommendation;
  final OptimizedTravelRoute? optimizedTravel;
  final int realCount;
}

List<PriceGapPriority> _buildPriceGaps(
  RouteOptimizer optimizer,
  Iterable<ListItem> items, {
  List<RecentPurchase> recentPurchases = const <RecentPurchase>[],
  List<PriceObservation> historicalPriceObservations =
      const <PriceObservation>[],
}) {
  final gapItems = items.toList(growable: false);
  final enabledStores = optimizer.availableStores;
  final marketCount = enabledStores.length;
  final missingByProduct = <String, int>{};
  final purchasesByProduct = <String, int>{};

  for (final purchase in recentPurchases) {
    final count = purchase.purchaseCount < 0 ? 0 : purchase.purchaseCount;
    final previous = purchasesByProduct[purchase.id] ?? 0;
    if (count > previous) purchasesByProduct[purchase.id] = count;
  }

  final historicalMedianByProduct = historicalPriceLevelsByProduct(
    items: gapItems,
    observations: historicalPriceObservations,
  );

  for (final item in gapItems) {
    missingByProduct[item.product.id] = enabledStores.where((store) {
      final quote = optimizer.prices.quote(store, item);
      return quote == null || quote.isEstimated;
    }).length;
  }

  return prioritizePriceGaps(
    gapItems,
    marketCount: marketCount,
    missingMarketCountFor: (item) =>
        missingByProduct[item.product.id] ?? marketCount,
    purchaseCountFor: (item) => purchasesByProduct[item.product.id] ?? 0,
    historicalPriceLevelFor: (item) =>
        historicalMedianByProduct[item.product.id],
  );
}

List<RoutePlan> _uniqueAlternatives(List<RoutePlan> plans) {
  final seen = <String>{};
  return plans.where((plan) {
    final stores = plan.stores.map((store) => store.name).toList()..sort();
    final assignments =
        plan.assignments.entries
            .expand(
              (entry) => entry.value.map(
                (item) => '${entry.key.name}:${item.product.id}',
              ),
            )
            .toList()
          ..sort();
    return seen.add('${stores.join('|')}::${assignments.join('|')}');
  }).toList();
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Füge zuerst Produkte zu deiner Einkaufsliste hinzu.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _MissingPrices extends StatelessWidget {
  const _MissingPrices({required this.gaps, this.onResolvePriceGap});

  final List<PriceGapPriority> gaps;
  final Future<void> Function(PriceGapPriority gap)? onResolvePriceGap;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
    children: [
      Text(
        'Einkaufsoptimierung',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Für diese Liste liegt in den aktivierten Märkten noch kein '
        'belastbarer Preis vor. Ergänze ein aktuelles Angebot, einen '
        'Bonpreis oder einen eigenen Preis, damit die Route rechnen kann.',
      ),
      const SizedBox(height: 14),
      if (gaps.isNotEmpty)
        PriceGapCard(
          gaps: gaps,
          onResolveGap: onResolvePriceGap,
          description:
              'Die Reihenfolge nutzt nur fehlende Marktbelege, '
              'Grundbedarf, deine bisherigen Käufe, historische '
              'Preisniveaus und Listenmenge. Historische Werte sind keine '
              'aktuellen Marktpreise.',
        )
      else
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Keine aktivierten Märkte ausgewählt.'),
          ),
        ),
    ],
  );
}
