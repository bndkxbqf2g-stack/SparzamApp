import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../design/sparzam_theme.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../offers/prospect_price_statistics.dart';
import '../price_gaps/price_gap_priority.dart';
import '../shopping_list/shopping_price_quotes.dart';

class PricesHubScreen extends StatefulWidget {
  const PricesHubScreen({
    super.key,
    required this.onOpenCatalog,
    required this.onOpenSettings,
    required this.summary,
    this.shoppingList = const <ListItem>[],
    this.offers = const <Offer>[],
    this.marketPrices = const <MarketPrice>[],
    this.enabledStoreNames = const <String>[],
    this.openPricesMaxAgeDays = 60,
    this.prospectPriceHistory = const <String, ProspectPriceHistorySummary>{},
    this.onOpenList,
    this.onOpenRoute,
    this.onResolvePriceGap,
    this.now,
  });

  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenSettings;
  final String summary;
  final List<ListItem> shoppingList;
  final List<Offer> offers;
  final List<MarketPrice> marketPrices;
  final List<String> enabledStoreNames;
  final int openPricesMaxAgeDays;
  final Map<String, ProspectPriceHistorySummary> prospectPriceHistory;
  final VoidCallback? onOpenList;
  final VoidCallback? onOpenRoute;
  final Future<void> Function(PriceGapPriority gap)? onResolvePriceGap;
  final DateTime? now;

  @override
  State<PricesHubScreen> createState() => _PricesHubScreenState();
}

class _PricesHubScreenState extends State<PricesHubScreen> {
  int? _snapshotSignatureValue;
  List<_PriceSnapshot>? _snapshotCache;
  ShoppingPriceQuoteSnapshot? _quoteSnapshotCache;
  List<ListItem>? _signatureShoppingListInput;
  List<MarketPrice>? _signatureMarketPricesInput;
  List<Offer>? _signatureOffersInput;
  Map<String, ProspectPriceHistorySummary>? _signatureHistoryInput;
  List<String>? _signatureEnabledStoresInput;
  int? _signatureMaxAgeDays;
  DateTime? _signatureDay;

  int _snapshotSignature() {
    final reference = widget.now ?? DateTime.now();
    final day = DateTime(reference.year, reference.month, reference.day);
    if (_snapshotSignatureValue != null &&
        identical(_signatureShoppingListInput, widget.shoppingList) &&
        identical(_signatureMarketPricesInput, widget.marketPrices) &&
        identical(_signatureOffersInput, widget.offers) &&
        identical(_signatureHistoryInput, widget.prospectPriceHistory) &&
        identical(_signatureEnabledStoresInput, widget.enabledStoreNames) &&
        _signatureMaxAgeDays == widget.openPricesMaxAgeDays &&
        _signatureDay == day) {
      return _snapshotSignatureValue!;
    }

    var hash = 17;
    void add(Object? value) {
      hash = (hash * 31 + (value?.hashCode ?? 0)) & 0x3fffffff;
    }

    add(widget.shoppingList.length);
    for (final item in widget.shoppingList) {
      add(item.product.id);
      add(item.quantity);
    }
    add(widget.marketPrices.length);
    for (final price in widget.marketPrices) {
      add(price.productId);
      add(price.storeName);
      add(price.source.name);
      add(price.price);
      add(price.updatedAt.millisecondsSinceEpoch);
      add(price.sourceLocationId);
      add(price.quantity);
      add(price.unit);
      add(price.unitPrice);
    }
    add(widget.offers.length);
    for (final offer in widget.offers) {
      add(offer.id);
      add(offer.productId);
      add(offer.storeName);
      add(offer.offerPrice);
      add(offer.originalPrice);
      add(offer.validFrom?.millisecondsSinceEpoch);
      add(offer.validUntil.millisecondsSinceEpoch);
      add(offer.locationId);
      add(offer.packageAmount);
      add(offer.packageUnit);
    }
    final history = widget.prospectPriceHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in history) {
      add(entry.key);
      for (final summary in entry.value.allSummaries) {
        add(summary.storeName);
        add(summary.kind.name);
        add(summary.medianPrice);
        add(summary.latestValidUntil.millisecondsSinceEpoch);
        add(summary.observationCount);
      }
    }
    add(widget.enabledStoreNames.join('|'));
    add(widget.openPricesMaxAgeDays);
    add(day.millisecondsSinceEpoch);

    _signatureShoppingListInput = widget.shoppingList;
    _signatureMarketPricesInput = widget.marketPrices;
    _signatureOffersInput = widget.offers;
    _signatureHistoryInput = widget.prospectPriceHistory;
    _signatureEnabledStoresInput = widget.enabledStoreNames;
    _signatureMaxAgeDays = widget.openPricesMaxAgeDays;
    _signatureDay = day;
    _snapshotSignatureValue = hash;
    return hash;
  }

  ShoppingPriceQuoteSnapshot _quoteSnapshot() {
    final signature = _snapshotSignature();
    final cached = _quoteSnapshotCache;
    if (cached != null && _snapshotSignatureValue == signature) {
      return cached;
    }
    final next = shoppingPriceQuoteSnapshot(
      widget.shoppingList,
      prices: widget.marketPrices,
      offers: widget.offers,
      prospectPriceHistory: widget.prospectPriceHistory,
      enabledStores: widget.enabledStoreNames,
      openPricesMaxAgeDays: widget.openPricesMaxAgeDays,
      now: widget.now,
    );
    _snapshotSignatureValue = signature;
    _quoteSnapshotCache = next;
    _snapshotCache = null;
    return next;
  }

  List<_PriceSnapshot> _snapshots(
    ShoppingPriceQuoteSnapshot quoteSnapshot,
  ) {
    final cached = _snapshotCache;
    if (cached != null) return cached;
    final snapshots = [
      for (final item in widget.shoppingList)
        _snapshotFor(item, quoteSnapshot),
    ];
    _snapshotCache = snapshots;
    return snapshots;
  }

  _PriceSnapshot _snapshotFor(
    ListItem item,
    ShoppingPriceQuoteSnapshot quoteSnapshot,
  ) {
    final quotes = quoteSnapshot.quotesFor(item);
    ShoppingQuote? current;
    for (final quote in quotes) {
      if (!quote.isHistorical) {
        current = quote;
        break;
      }
    }
    return _PriceSnapshot(
      item: item,
      quote: current,
      hasHistorical: quotes.any((quote) => quote.isHistorical),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = widget;
    final quoteSnapshot = _quoteSnapshot();
    final snapshots = _snapshots(quoteSnapshot);
    final current = snapshots.where((row) => row.quote != null).length;
    final historical = snapshots.where((row) => row.hasHistorical).length;
    final missing = snapshots.length - current;
    final coverage = snapshots.isEmpty ? 0.0 : current / snapshots.length;
    final orientingTotal = snapshots.fold<double>(
      0,
      (sum, row) => sum + (row.quote?.unitPrice ?? 0) * row.item.quantity,
    );

    return ListView(
      scrollCacheExtent: ScrollCacheExtent.pixels(0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Icon(
          Icons.sell_outlined,
          color: SparzamTheme.deepGreen,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          'Preise',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Center(child: Text('Transparenz schafft echte Ersparnis.')),
        const SizedBox(height: 20),
        if (snapshots.isEmpty)
          _EmptyListCard(onOpenList: screen.onOpenList)
        else
          _ListCoverageCard(
            current: current,
            total: snapshots.length,
            historical: historical,
            missing: missing,
            coverage: coverage,
            orientingTotal: orientingTotal,
            onOpenList: screen.onOpenList,
            onOpenRoute: screen.onOpenRoute,
          ),
        if (snapshots.isNotEmpty && current > 0) ...[
          const SizedBox(height: 16),
          Text(
            'Günstigste aktuelle Hinweise',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in snapshots.where((row) => row.quote != null).take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PriceSnapshotTile(snapshot: row),
            ),
          if (current > 8)
            Text(
              'Weitere ${current - 8} Positionen findest du direkt in der Einkaufsliste.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
        if (snapshots.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            'Marktvergleich deiner Liste',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Öffne eine Position, um aktuelle, historische und fehlende '
            'Belege je aktiviertem Markt zu prüfen.',
          ),
          const SizedBox(height: 10),
          _PriceComparisonList(
            shoppingList: screen.shoppingList,
            quoteSnapshot: quoteSnapshot,
            onResolvePriceGap: screen.onResolvePriceGap,
            now: screen.now,
          ),
        ],
        if (snapshots.isNotEmpty && missing > 0) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.amber.shade50,
            child: ListTile(
              leading: Icon(Icons.help_outline, color: Colors.amber.shade900),
              title: Text(
                '$missing ${missing == 1 ? 'Position' : 'Positionen'} ohne aktuellen Preis',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                historical > 0
                    ? 'Historische Hinweise bleiben sichtbar, werden aber nicht als aktuell gerechnet.'
                    : 'Ergänze einen Bonpreis, ein gültiges Angebot oder einen eigenen Marktpreis.',
              ),
              trailing: screen.onOpenList == null
                  ? null
                  : const Icon(Icons.chevron_right),
              onTap: screen.onOpenList,
            ),
          ),
        ],
        const SizedBox(height: 22),
        Card(
          child: ListTile(
            leading: const Icon(Icons.search, color: SparzamTheme.deepGreen),
            title: const Text('Produkte und Preise vergleichen'),
            subtitle: const Text(
              'Produkt suchen, Marktpreise und Verlauf ansehen',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: screen.onOpenCatalog,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.storage_outlined,
              color: SparzamTheme.deepGreen,
            ),
            title: const Text('Preisdaten'),
            subtitle: Text(screen.summary),
            trailing: const Icon(Icons.chevron_right),
            onTap: screen.onOpenSettings,
          ),
        ),
      ],
    );
  }
}
class _ListCoverageCard extends StatelessWidget {
  const _ListCoverageCard({
    required this.current,
    required this.total,
    required this.historical,
    required this.missing,
    required this.coverage,
    required this.orientingTotal,
    this.onOpenList,
    this.onOpenRoute,
  });

  final int current;
  final int total;
  final int historical;
  final int missing;
  final double coverage;
  final double orientingTotal;
  final VoidCallback? onOpenList;
  final VoidCallback? onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final amount = orientingTotal.toStringAsFixed(2).replaceAll('.', ',');
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preisabdeckung deiner Liste',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text('$current von $total Positionen mit aktuellem Marktpreis'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: coverage,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: SparzamTheme.deepGreen,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  avatar: const Icon(Icons.euro, size: 16),
                  label: Text('Orientierung: $amount €'),
                ),
                if (historical > 0)
                  Chip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text('$historical historische Hinweise'),
                  ),
                if (missing > 0)
                  Chip(
                    avatar: const Icon(Icons.help_outline, size: 16),
                    label: Text('$missing unbekannt'),
                  ),
              ],
            ),
            if (onOpenList != null || onOpenRoute != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (onOpenList != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenList,
                        icon: const Icon(Icons.list_alt_outlined),
                        label: const Text('Liste öffnen'),
                      ),
                    ),
                  if (onOpenList != null && onOpenRoute != null)
                    const SizedBox(width: 8),
                  if (onOpenRoute != null)
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: onOpenRoute,
                        icon: const Icon(Icons.route_outlined),
                        label: const Text('Route prüfen'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceSnapshotTile extends StatelessWidget {
  const _PriceSnapshotTile({required this.snapshot});

  final _PriceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final quote = snapshot.quote!;
    final amount = quote.unitPrice.toStringAsFixed(2).replaceAll('.', ',');
    final quantity = snapshot.item.quantity > 1
        ? ' · ×${snapshot.item.quantity}'
        : '';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.price_check_outlined),
        title: Text(
          snapshot.item.product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${quote.storeName} · ${quote.displayPrefix}$quantity',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '$amount €',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}


class _PriceComparisonList extends StatefulWidget {
  const _PriceComparisonList({
    required this.shoppingList,
    required this.quoteSnapshot,
    required this.onResolvePriceGap,
    this.now,
  });

  static const pageSize = 12;

  final List<ListItem> shoppingList;
  final ShoppingPriceQuoteSnapshot quoteSnapshot;
  final Future<void> Function(PriceGapPriority gap)? onResolvePriceGap;
  final DateTime? now;

  @override
  State<_PriceComparisonList> createState() => _PriceComparisonListState();
}

class _PriceComparisonListState extends State<_PriceComparisonList> {
  var _visibleCount = _PriceComparisonList.pageSize;

  void _showMore() {
    setState(() {
      final nextCount = _visibleCount + _PriceComparisonList.pageSize;
      _visibleCount = nextCount > widget.shoppingList.length
          ? widget.shoppingList.length
          : nextCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.shoppingList.take(_visibleCount);
    return Column(
      children: [
        for (final item in visibleItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PriceComparisonCard(
              key: ValueKey('price-comparison-${item.product.id}'),
              item: item,
              quoteSnapshot: widget.quoteSnapshot,
              onResolvePriceGap: widget.onResolvePriceGap,
              now: widget.now,
            ),
          ),
        if (_visibleCount < widget.shoppingList.length)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('price-comparisons-load-more'),
              onPressed: _showMore,
              icon: const Icon(Icons.expand_more),
              label: Text(
                'Weitere ${widget.shoppingList.length - _visibleCount} '
                'Preisvergleiche laden',
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceComparisonCard extends StatefulWidget {
  const _PriceComparisonCard({
    super.key,
    required this.item,
    required this.quoteSnapshot,
    required this.onResolvePriceGap,
    this.now,
  });

  final ListItem item;
  final ShoppingPriceQuoteSnapshot quoteSnapshot;
  final Future<void> Function(PriceGapPriority gap)? onResolvePriceGap;
  final DateTime? now;

  @override
  State<_PriceComparisonCard> createState() => _PriceComparisonCardState();
}

class _PriceComparisonCardState extends State<_PriceComparisonCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final matrix = widget.quoteSnapshot.matrixFor(widget.item);
    final current = matrix.where((entry) => entry.hasCurrentQuote).length;
    final historical = matrix.where((entry) => entry.hasHistoricalQuote).length;
    final missing = matrix.length - current;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (value) => setState(() => expanded = value),
        title: Text(
          widget.item.product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$current/${matrix.length} Märkte aktuell'
          '${historical == 0 ? '' : ' · $historical historisch'}',
        ),
        children: expanded
            ? [
                if (widget.onResolvePriceGap != null && missing > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: ValueKey(
                        'resolve-price-gap-${widget.item.product.id}',
                      ),
                      onPressed: () async {
                        await widget.onResolvePriceGap!(
                          PriceGapPriority(
                            item: widget.item,
                            missingMarketCount: missing,
                            marketCount: matrix.length,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Fehlenden Preis ergänzen'),
                    ),
                  ),
                for (final entry in matrix)
                  _PriceMatrixRow(entry: entry, now: widget.now),
              ]
            : const [],
      ),
    );
  }
}

class _PriceMatrixRow extends StatelessWidget {
  const _PriceMatrixRow({required this.entry, this.now});

  final ShoppingPriceMatrixEntry entry;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final quote = entry.quote;
    if (quote == null) {
      return ListTile(
        dense: true,
        leading: const Icon(Icons.help_outline, color: Colors.amber),
        title: Text(entry.storeName),
        subtitle: const Text('Kein aktueller, vergleichbarer Preisbeleg'),
        trailing: const Text('fehlt'),
      );
    }
    final details = <String>[
      quote.sourceLabel,
      if (quote.packageLabel != null) 'Packung ${quote.packageLabel}',
      if (quote.baseUnitPriceLabel != null) quote.baseUnitPriceLabel!,
      quote.comparabilityLabel,
      quote.freshnessLabel(now: now),
      if (quote.savingsLabel != null) quote.savingsLabel!,
    ];
    return ListTile(
      dense: true,
      leading: Icon(
        quote.isHistorical
            ? Icons.history_toggle_off_outlined
            : Icons.price_check_outlined,
        color: quote.isHistorical ? Colors.grey : SparzamTheme.deepGreen,
      ),
      title: Text(entry.storeName),
      subtitle: Text(details.join(' · ')),
      trailing: Text(
        quote.amountLabel,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: quote.isHistorical ? Colors.grey : null,
        ),
      ),
    );
  }
}

class _EmptyListCard extends StatelessWidget {
  const _EmptyListCard({this.onOpenList});

  final VoidCallback? onOpenList;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFF1F7ED),
    child: ListTile(
      leading: const Icon(
        Icons.shopping_basket_outlined,
        color: SparzamTheme.deepGreen,
      ),
      title: const Text(
        'Noch keine Liste zum Vergleichen',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text(
        'Füge Produkte hinzu, damit aktuelle Marktpreise direkt sichtbar werden.',
      ),
      trailing: onOpenList == null ? null : const Icon(Icons.chevron_right),
      onTap: onOpenList,
    ),
  );
}

class _PriceSnapshot {
  const _PriceSnapshot({
    required this.item,
    required this.quote,
    required this.hasHistorical,
  });

  final ListItem item;
  final ShoppingQuote? quote;
  final bool hasHistorical;
}
