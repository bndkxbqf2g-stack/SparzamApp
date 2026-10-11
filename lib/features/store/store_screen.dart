import 'package:flutter/material.dart';

import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/store.dart';
import '../../services/road_distance_service.dart';
import '../../services/road_distance_store.dart';
import 'store_shopping_summary.dart';
import 'store_value.dart';
import '../price_gaps/price_gap_card.dart';
import '../price_gaps/price_gap_priority.dart';
import '../route/travel_estimator.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({
    super.key,
    required this.store,
    required this.items,
    required this.offers,
    required this.mobility,
    required this.marketPrices,
    this.openPricesMaxAgeDays = 60,
    this.onResolvePriceGap,
  });

  final Store store;
  final List<ListItem> items;
  final List<Offer> offers;
  final MobilitySettings mobility;
  final List<MarketPrice> marketPrices;
  final int openPricesMaxAgeDays;
  final Future<void> Function(PriceGapPriority gap)? onResolvePriceGap;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final cache = RoadDistanceStore();
  late RoadDistanceService service;
  Map<String, double> roadDistances = <String, double>{};
  bool loading = false;

  @override
  void initState() {
    super.initState();
    service = RoadDistanceService(originAddress: widget.mobility.startAddress);
    _load();
  }

  Future<void> _load() async {
    final loaded = await cache.load(widget.mobility.startAddress);
    if (!mounted) return;
    setState(() => roadDistances = loaded);
  }

  Future<void> _refresh() async {
    if (loading || widget.store.address.isEmpty) return;
    setState(() => loading = true);

    final distance = await service.fetchKm(widget.store.address);
    final next = {...roadDistances};
    if (distance != null && distance > 0) {
      next[widget.store.name] = distance;
      await cache.save(widget.mobility.startAddress, next);
    }

    if (!mounted) return;
    setState(() {
      roadDistances = next;
      loading = false;
    });
  }

  @override
  void dispose() {
    service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = buildStoreShoppingSummary(
      widget.store,
      widget.items,
      widget.offers,
      marketPrices: widget.marketPrices,
      openPricesMaxAgeDays: widget.openPricesMaxAgeDays,
    );
    final priceGaps = prioritizePriceGaps(
      summary.unpricedItems,
      marketCount: 1,
    );
    final value = evaluateStoreValue(
      widget.store,
      widget.items,
      widget.offers,
      roadDistances: roadDistances,
      euroPerKm: widget.mobility.effectiveEuroPerKm,
      marketPrices: widget.marketPrices,
      openPricesMaxAgeDays: widget.openPricesMaxAgeDays,
    );
    final roadDistance = roadDistances[widget.store.name];
    final shownDistance = roadDistance ?? widget.store.distanceKm;
    final travel = estimateRoundTrips(
      [widget.store],
      mobility: widget.mobility,
      roadDistances: roadDistances,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.store.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.store.location),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.mobility.mode.label} · ca. ${travel.durationLabel} Wegezeit',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          roadDistance == null
                              ? '${shownDistance.toStringAsFixed(1)} km · hinterlegter Wert'
                              : '${shownDistance.toStringAsFixed(1)} km · reale Straßenstrecke',
                        ),
                      ),
                      if (loading)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          tooltip: 'Straßenstrecke aktualisieren',
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${summary.total.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    summary.savings > 0
                        ? summary.hasDataGaps
                            ? 'Für den belegten Teil · spare '
                                '${summary.savings.toStringAsFixed(2)} €'
                            : 'Für deine Liste · spare '
                                '${summary.savings.toStringAsFixed(2)} €'
                        : summary.hasDataGaps
                            ? 'Für den belegten Teil'
                            : 'Für deine Liste',
                  ),
                  if (summary.totalItemCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${summary.pricedItemCount} von '
                      '${summary.totalItemCount} Artikeln mit aktuellem, '
                      'vergleichbarem Preis',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (summary.hasDataGaps) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Preisabdeckung unvollständig',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kosten und Ersparnis gelten nur für den belegten Teil '
                      'deiner Liste.',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Die fehlenden Positionen sind unten nach fehlender '
                      'Marktabdeckung, Grundbedarf und Listenmenge sortiert.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (priceGaps.isNotEmpty) ...[
            const SizedBox(height: 10),
            PriceGapCard(
              gaps: priceGaps,
              description:
                  'Kosten und Ersparnis gelten nur für den belegten Teil '
                  'deiner Liste.',
              onResolveGap: widget.onResolvePriceGap,
            ),
          ],
          const SizedBox(height: 16),
          _ValueCard(value: value),
          const SizedBox(height: 16),
          Text(
            'Deine Artikel in diesem Markt',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          if (summary.lines.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Für deine aktuelle Liste sind hier keine Preise hinterlegt.',
                ),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < summary.lines.length; index++) ...[
                    _StoreLine(line: summary.lines[index]),
                    if (index < summary.lines.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreLine extends StatelessWidget {
  const _StoreLine({required this.line});

  final StoreShoppingLine line;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(
          line.usesOffer
              ? Icons.local_offer_outlined
              : Icons.shopping_bag_outlined,
        ),
        title: Text(
          line.item.product.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          line.item.quantity > 1
              ? '${line.item.product.unit} · ×${line.item.quantity}'
              : line.item.product.unit,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${line.total.toStringAsFixed(2)} €',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (line.usesOffer)
              Text(
                'Angebot · -${line.savings.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Text(
                '${line.unitPrice.toStringAsFixed(2)} € / Einheit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      );
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.value});

  final StoreValue value;

  @override
  Widget build(BuildContext context) {
    final incomplete = value.hasDataGaps;
    final positive = value.isWorthIt;
    final neutral = value.isNeutral;
    final icon = incomplete
        ? Icons.info_outline
        : positive
        ? Icons.thumb_up_alt_outlined
        : neutral
            ? Icons.remove_circle_outline
            : Icons.warning_amber_rounded;
    final title = incomplete
        ? 'Preisabdeckung unvollständig'
        : positive
        ? 'Dieser Markt lohnt sich durch die Angebote'
        : neutral
            ? 'Angebotsvorteil und Fahrtkosten gleichen sich aus'
            : 'Die Fahrtkosten sind höher als die Angebotsersparnis';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ValueRow(
              label: incomplete ? 'Bekannte Ersparnis' : 'Warenkorbersparnis',
              value: '+${value.basketSavings.toStringAsFixed(2)} €',
            ),
            _ValueRow(
              label: 'Fahrtkosten',
              value: '-${value.travelCost.toStringAsFixed(2)} €',
            ),
            const Divider(height: 20),
            _ValueRow(
              label: incomplete
                  ? 'Teilwarenkorb nach Fahrtkosten'
                  : 'Echter Vorteil',
              value: '${value.netAdvantage >= 0 ? '+' : ''}'
                  '${value.netAdvantage.toStringAsFixed(2)} €',
              strong: true,
            ),
            const SizedBox(height: 6),
            Text(
              incomplete
                  ? 'Bekannte Kosten inklusive Fahrt: '
                      '${value.totalWithTravel.toStringAsFixed(2)} € · '
                      '${value.pricedItemCount} von '
                      '${value.totalItemCount} Artikeln bepreist'
                  : 'Gesamt inklusive Fahrt: '
                      '${value.totalWithTravel.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
