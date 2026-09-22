import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../services/road_distance_service.dart';
import '../../services/road_distance_store.dart';
import 'route_alternative_card.dart';
import 'route_recommendation.dart';
import 'route_recommendation_card.dart';
import 'route_optimizer.dart';
import 'route_store_card.dart';
import 'route_summary_card.dart';
import 'travel_estimator.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({
    super.key,
    required this.items,
    required this.offers,
    required this.mobility,
    this.onRoadDistancesChanged,
  });

  final List<ListItem> items;
  final List<Offer> offers;
  final MobilitySettings mobility;
  final ValueChanged<Map<String, double>>? onRoadDistancesChanged;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final cache = RoadDistanceStore();
  late RoadDistanceService service;
  Map<String, double> roadDistances = <String, double>{};
  bool loadingRoadDistances = false;

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
      service.close();
      service = RoadDistanceService(
        originAddress: widget.mobility.startAddress,
      );
      roadDistances = <String, double>{};
      _loadRoadDistances();
    }
  }

  Future<void> _loadRoadDistances() async {
    final loaded = await cache.load(widget.mobility.startAddress);
    if (!mounted) return;
    setState(() => roadDistances = loaded);
  }

  Future<void> _refreshRoadDistances() async {
    if (loadingRoadDistances) return;
    setState(() => loadingRoadDistances = true);

    final next = {...roadDistances};
    for (final store in stores) {
      if (!widget.mobility.isStoreEnabled(store.name)) continue;
      if (store.address.isEmpty) continue;
      final distance = await service.fetchKm(store.address);
      if (distance != null && distance > 0) next[store.name] = distance;
      await Future<void>.delayed(const Duration(milliseconds: 1100));
    }

    await cache.save(widget.mobility.startAddress, next);
    if (!mounted) return;
    setState(() {
      roadDistances = next;
      loadingRoadDistances = false;
    });
    widget.onRoadDistancesChanged?.call(next);
  }

  @override
  void dispose() {
    service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const _EmptyRoute();

    final optimizer = RouteOptimizer(
      widget.items,
      widget.offers,
      roadDistances: roadDistances,
      euroPerKm: widget.mobility.effectiveEuroPerKm,
      maxStores: widget.mobility.maxStores,
      minExtraStoreSavings: widget.mobility.minExtraStoreSavings,
      enabledStoreNames: widget.mobility.enabledStoreNames,
    );
    final best = optimizer.bestPlan();
    if (best == null) return const _MissingPrices();

    final single = optimizer.bestSingleStorePlan();
    final savings = single == null ? 0.0 : single.total - best.total;
    final alternatives = optimizer.alternatives();
    final cheapest = alternatives.first;
    final travel = estimateRoundTrips(
      best.stores,
      mobility: widget.mobility,
      roadDistances: roadDistances,
    );
    final recommendation = buildRouteRecommendationInfo(
      recommended: best,
      cheapest: cheapest,
      singleStore: single,
      mobility: widget.mobility,
    );
    final realCount = roadDistances.entries
        .where((entry) => widget.mobility.isStoreEnabled(entry.key))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text(
          'Einkaufsoptimierung',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Verglichen werden Normalpreise, aktive Angebote, Coupons, '
          'Cashback und Fahrtkosten für bis zu 3 Märkte.',
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(
              realCount > 0 ? Icons.route : Icons.route_outlined,
            ),
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
        RouteSummaryCard(best: best, extraSavings: savings),
        const SizedBox(height: 10),
        RouteRecommendationCard(
          info: recommendation,
          travelLabel: travel.durationLabel,
          mobilityLabel: widget.mobility.mode.label,
        ),
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
        for (final plan in alternatives.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RouteAlternativeCard(plan: plan),
          ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.mobility.mode == MobilityMode.car
                  ? (realCount > 0
                      ? 'Fahrtkosten: Straßenentfernung × 2 × '
                          '${widget.mobility.effectiveEuroPerKm.toStringAsFixed(2)} €/km. '
                          'Nicht geladene Strecken verwenden den hinterlegten Fallback.'
                      : 'Fahrtkosten: aktuell '
                          '${widget.mobility.effectiveEuroPerKm.toStringAsFixed(2)} €/km '
                          'auf Basis der hinterlegten Entfernungen.')
                  : '${widget.mobility.mode.label}: keine monetären Fahrtkosten. '
                      'Die Strecke wird weiterhin für die geschätzte Wegezeit verwendet.',
            ),
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
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
  const _MissingPrices();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Für mindestens einen Artikel ist noch kein Marktpreis hinterlegt.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}
