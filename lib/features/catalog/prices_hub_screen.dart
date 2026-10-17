import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../design/sparzam_theme.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../offers/prospect_price_statistics.dart';
import '../prospects/prospect_feed_status.dart';
import 'market_price_freshness.dart';
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
    this.prospectFeedGeneratedAt,
    this.prospectFeedFromCache = false,
    this.prospectRegularPriceCount = 0,
    this.prospectRegularPriceCountsByStore = const <String, int>{},
    this.prospectRegularPricePersistenceStatus =
        ProspectRegularPricePersistenceStatus.standalone,
    this.historicalPriceObservations = const <PriceObservation>[],
    this.catalogProducts = const <Product>[],
    this.onOpenList,
    this.onOpenRoute,
    this.onRefreshProspects,
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
  final DateTime? prospectFeedGeneratedAt;
  final bool prospectFeedFromCache;
  final int prospectRegularPriceCount;
  final Map<String, int> prospectRegularPriceCountsByStore;
  final ProspectRegularPricePersistenceStatus
      prospectRegularPricePersistenceStatus;
  final List<PriceObservation> historicalPriceObservations;
  final List<Product> catalogProducts;
  final VoidCallback? onOpenList;
  final VoidCallback? onOpenRoute;
  final Future<void> Function()? onRefreshProspects;
  final Future<void> Function(PriceGapPriority gap)? onResolvePriceGap;
  final DateTime? now;

  @override
  State<PricesHubScreen> createState() => _PricesHubScreenState();
}

class _PricesHubScreenState extends State<PricesHubScreen> {
  int? _snapshotSignatureValue;
  int? _quoteSnapshotSignature;
  List<_PriceSnapshot>? _snapshotCache;
  ShoppingPriceQuoteSnapshot? _quoteSnapshotCache;
  List<ListItem>? _signatureShoppingListInput;
  List<MarketPrice>? _signatureMarketPricesInput;
  List<Offer>? _signatureOffersInput;
  List<Product>? _signatureCatalogProductsInput;
  Map<String, ProspectPriceHistorySummary>? _signatureHistoryInput;
  List<PriceObservation>? _signatureHistoricalPriceObservationsInput;
  List<String>? _signatureEnabledStoresInput;
  int? _signatureMaxAgeDays;
  DateTime? _signatureDay;
  DateTime? _signatureProspectFeedGeneratedAt;
  bool? _signatureProspectFeedFromCache;
  int? _signatureProspectRegularPriceCount;
  Map<String, int>? _signatureProspectRegularPriceCountsByStore;
  ProspectRegularPricePersistenceStatus?
      _signatureProspectRegularPricePersistenceStatus;

  int _snapshotSignature() {
    final reference = widget.now ?? DateTime.now();
    final day = DateTime(reference.year, reference.month, reference.day);
    if (_snapshotSignatureValue != null &&
        identical(_signatureShoppingListInput, widget.shoppingList) &&
        identical(_signatureMarketPricesInput, widget.marketPrices) &&
        identical(_signatureOffersInput, widget.offers) &&
        identical(
          _signatureCatalogProductsInput,
          widget.catalogProducts,
        ) &&
        identical(_signatureHistoryInput, widget.prospectPriceHistory) &&
        identical(
          _signatureHistoricalPriceObservationsInput,
          widget.historicalPriceObservations,
        ) &&
        identical(_signatureEnabledStoresInput, widget.enabledStoreNames) &&
        _signatureMaxAgeDays == widget.openPricesMaxAgeDays &&
        _signatureDay == day &&
        _signatureProspectFeedGeneratedAt == widget.prospectFeedGeneratedAt &&
        _signatureProspectFeedFromCache == widget.prospectFeedFromCache &&
        _signatureProspectRegularPriceCount ==
            widget.prospectRegularPriceCount &&
        identical(
          _signatureProspectRegularPriceCountsByStore,
          widget.prospectRegularPriceCountsByStore,
        ) &&
        _signatureProspectRegularPricePersistenceStatus ==
            widget.prospectRegularPricePersistenceStatus) {
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
      add(price.sourceLocationName);
      add(price.sourceAdapter);
      add(price.externalId);
      add(price.discounted);
      add(price.proofRef);
      add(price.quantity);
      add(price.unit);
      add(price.unitPrice);
      add(price.identityConfidence);
      add(price.kind.name);
      add(price.evidenceConfidence?.name);
    }
    add(widget.offers.length);
    for (final offer in widget.offers) {
      add(offer.id);
      add(offer.productId);
      add(offer.storeName);
      add(offer.offerPrice);
      add(offer.originalPrice);
      add(offer.originalPriceVerified);
      add(offer.evidenceConfidence?.name);
      add(offer.validFrom?.millisecondsSinceEpoch);
      add(offer.validUntil.millisecondsSinceEpoch);
      add(offer.source);
      add(offer.sourceAdapter);
      add(offer.capturedAt?.millisecondsSinceEpoch);
      add(offer.proofRef);
      add(offer.imageUrl);
      add(offer.locationId);
      add(offer.region);
      add(offer.address);
      add(offer.packageAmount);
      add(offer.packageUnit);
      add(offer.unitPrice);
      add(offer.buyQuantity);
      add(offer.payQuantity);
      add(offer.coupon);
      add(offer.couponPercent);
      add(offer.couponAmount);
      add(offer.cashback);
      add(offer.cashbackPercent);
      add(offer.cashbackAmount);
    }
    add(widget.catalogProducts.length);
    for (final product in widget.catalogProducts) {
      add(product.id);
      add(product.name);
      add(product.unit);
      add(product.packageAmount);
      add(product.packageUnit);
      add(product.ean);
      add(product.brand);
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
    add(widget.historicalPriceObservations.length);
    for (final observation in widget.historicalPriceObservations) {
      add(observation.id);
      add(observation.productId);
      add(observation.storeName);
      add(observation.locationId);
      add(observation.price);
      add(observation.observedAt.millisecondsSinceEpoch);
      add(observation.validFrom?.millisecondsSinceEpoch);
      add(observation.validUntil?.millisecondsSinceEpoch);
      add(observation.kind.name);
      add(observation.isCurrent);
    }
    add(widget.enabledStoreNames.join('|'));
    add(widget.openPricesMaxAgeDays);
    add(widget.prospectFeedGeneratedAt?.millisecondsSinceEpoch);
    add(widget.prospectFeedFromCache);
    add(widget.prospectRegularPriceCount);
    final persistedByStore = widget.prospectRegularPriceCountsByStore.entries
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in persistedByStore) {
      add(entry.key);
      add(entry.value);
    }
    add(widget.prospectRegularPricePersistenceStatus.name);
    add(day.millisecondsSinceEpoch);

    _signatureShoppingListInput = widget.shoppingList;
    _signatureMarketPricesInput = widget.marketPrices;
    _signatureOffersInput = widget.offers;
    _signatureCatalogProductsInput = widget.catalogProducts;
    _signatureHistoryInput = widget.prospectPriceHistory;
    _signatureHistoricalPriceObservationsInput =
        widget.historicalPriceObservations;
    _signatureEnabledStoresInput = widget.enabledStoreNames;
    _signatureMaxAgeDays = widget.openPricesMaxAgeDays;
    _signatureDay = day;
    _signatureProspectFeedGeneratedAt = widget.prospectFeedGeneratedAt;
    _signatureProspectFeedFromCache = widget.prospectFeedFromCache;
    _signatureProspectRegularPriceCount = widget.prospectRegularPriceCount;
    _signatureProspectRegularPriceCountsByStore =
        widget.prospectRegularPriceCountsByStore;
    _signatureProspectRegularPricePersistenceStatus =
        widget.prospectRegularPricePersistenceStatus;
    _snapshotSignatureValue = hash;
    return hash;
  }

  ShoppingPriceQuoteSnapshot _quoteSnapshot() {
    final signature = _snapshotSignature();
    final cached = _quoteSnapshotCache;
    if (cached != null && _quoteSnapshotSignature == signature) {
      return cached;
    }
    final next = shoppingPriceQuoteSnapshot(
      widget.shoppingList,
      prices: widget.marketPrices,
      offers: widget.offers,
      catalogProducts: widget.catalogProducts,
      prospectPriceHistory: widget.prospectPriceHistory,
      enabledStores: widget.enabledStoreNames,
      openPricesMaxAgeDays: widget.openPricesMaxAgeDays,
      now: widget.now,
    );
    _snapshotSignatureValue = signature;
    _quoteSnapshotSignature = signature;
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
    final quality = calculatePriceDataQuality(
      screen.marketPrices,
      openPricesMaxAgeDays: screen.openPricesMaxAgeDays,
      now: screen.now,
    );
    final currentSnapshots = snapshots
        .where((row) => row.quote != null)
        .toList(growable: false)
      ..sort(_compareCurrentPriceSnapshots);
    final current = currentSnapshots.length;
    final historical = snapshots.where((row) => row.hasHistorical).length;
    final missing = snapshots.length - current;
    final coverage = snapshots.isEmpty ? 0.0 : current / snapshots.length;
    final orientingTotal = snapshots.fold<double>(
      0,
      (sum, row) => sum + (row.quote?.unitPrice ?? 0) * row.item.quantity,
    );
    final hasProspectRegularPriceStatus =
        screen.prospectFeedGeneratedAt != null ||
        screen.prospectFeedFromCache ||
        screen.prospectRegularPriceCount > 0 ||
        screen.prospectRegularPricePersistenceStatus !=
            ProspectRegularPricePersistenceStatus.standalone;
    final currentProspectRegularPrices =
        currentProspectRegularPriceObservations(
          observations: screen.historicalPriceObservations,
          now: screen.now,
        );
    final reference = screen.now ?? DateTime.now();
    final referenceDay = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    final offerOnlyProspectCount = screen.offers.where((offer) {
      if (!offer.id.startsWith('import|') || offer.originalPriceVerified) {
        return false;
      }
      final validFrom = offer.validFrom;
      if (validFrom != null) {
        final validFromDay = DateTime(
          validFrom.year,
          validFrom.month,
          validFrom.day,
        );
        if (validFromDay.isAfter(referenceDay)) return false;
      }
      final validUntilDay = DateTime(
        offer.validUntil.year,
        offer.validUntil.month,
        offer.validUntil.day,
      );
      return !validUntilDay.isBefore(referenceDay);
    }).length;

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
          for (final row in currentSnapshots.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PriceSnapshotTile(
                key: ValueKey('price-snapshot-${row.item.product.id}'),
                snapshot: row,
              ),
            ),
          if (currentSnapshots.length > 8)
            Text(
              'Weitere ${currentSnapshots.length - 8} Positionen findest du direkt in der Einkaufsliste.',
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
        if (quality.hasData) ...[
          const SizedBox(height: 16),
          _PriceDataQualityCard(quality: quality),
        ],
        if (hasProspectRegularPriceStatus) ...[
          const SizedBox(height: 16),
          _ProspectRegularPriceDatabaseCard(
            generatedAt: screen.prospectFeedGeneratedAt,
            fromCache: screen.prospectFeedFromCache,
            count: screen.prospectRegularPriceCount,
            countsByStore: screen.prospectRegularPriceCountsByStore,
            status: screen.prospectRegularPricePersistenceStatus,
            offerOnlyCount: offerOnlyProspectCount,
            onRefresh: screen.onRefreshProspects,
          ),
        ],
        if (currentProspectRegularPrices.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ProspectRegularPriceLedgerCard(
            observations: currentProspectRegularPrices,
            catalogProducts: screen.catalogProducts,
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

class _ProspectRegularPriceDatabaseCard extends StatelessWidget {
  const _ProspectRegularPriceDatabaseCard({
    required this.generatedAt,
    required this.fromCache,
    required this.count,
    required this.countsByStore,
    required this.status,
    required this.offerOnlyCount,
    this.onRefresh,
  });

  final DateTime? generatedAt;
  final bool fromCache;
  final int count;
  final Map<String, int> countsByStore;
  final ProspectRegularPricePersistenceStatus status;
  final int offerOnlyCount;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final stores = countsByStore.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final countLabel = count == 1
        ? '1 regulärer Normalpreis'
        : '$count reguläre Normalpreise';
    final statusLabel = switch (status) {
      ProspectRegularPricePersistenceStatus.standalone =>
        count == 0
            ? 'Lokale Speicherung nicht bestätigt.'
            : '$countLabel im Feed erkannt; lokale Speicherung nicht bestätigt.',
      ProspectRegularPricePersistenceStatus.pending =>
        count == 0
            ? 'Speicherung läuft.'
            : 'Speicherung läuft; $countLabel erkannt.',
      ProspectRegularPricePersistenceStatus.succeeded =>
        '$countLabel als Preisbasis gespeichert.',
      ProspectRegularPricePersistenceStatus.failed =>
        'Speicherung fehlgeschlagen oder unbekannt; keine Bestätigung für '
            'reguläre Normalpreise.',
    };
    final feedLabel = generatedAt == null
        ? 'Feed-Stand unbekannt.'
        : 'Feed-Stand ${formatProspectFeedTimestamp(generatedAt)}'
            '${fromCache ? ' · lokaler Cache' : ''}.';
    final offerOnlyLabel = offerOnlyCount == 1
        ? '1 aktueller Angebotspreis'
        : '$offerOnlyCount aktuelle Angebotspreise';

    return Card(
      key: const ValueKey('prospect-regular-price-database-card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Automatische Prospekt-Normalpreise',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nur ausdrücklich ausgewiesene reguläre Normalpreise werden '
              'gespeichert. Aktionspreise bleiben getrennt.',
            ),
            const SizedBox(height: 6),
            Text(feedLabel),
            if (offerOnlyCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                '$offerOnlyLabel ohne belegten Normalpreis bleiben getrennt '
                'und werden nicht als Preisbasis gespeichert.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (onRefresh != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('prospect-regular-price-refresh'),
                onPressed: () => unawaited(onRefresh!()),
                icon: const Icon(Icons.refresh),
                label: const Text('Prospektpreise jetzt aktualisieren'),
              ),
              const Text(
                'Der Abruf speichert danach nur ausdrücklich ausgewiesene '
                'reguläre Normalpreise.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (stores.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Gespeichert je Markt/Filiale',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stores
                    .take(6)
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (status ==
                ProspectRegularPricePersistenceStatus.succeeded) ...[
              const SizedBox(height: 8),
              const Text('0 gespeichert: Der aktuelle Feed enthält keinen '
                  'belegten regulären Normalpreis.'),
            ],
          ],
        ),
      ),
    );
  }
}


List<PriceObservation> currentProspectRegularPriceObservations({
  required Iterable<PriceObservation> observations,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final day = DateTime(reference.year, reference.month, reference.day);
  final latestByKey = <String, PriceObservation>{};
  for (final entry in observations) {
    final sourceIsProspect = switch (entry.source) {
      PriceObservationSource.retailer ||
      PriceObservationSource.retailerWebsite ||
      PriceObservationSource.leaflet => true,
      _ => false,
    };
    if (entry.kind != PriceObservationKind.regular ||
        !sourceIsProspect ||
        !entry.isCurrent ||
        entry.productId?.trim().isNotEmpty != true ||
        entry.identityConfidence < 1 ||
        entry.proofRef?.trim().isNotEmpty != true ||
        // A current prospect ledger entry must identify one exact branch.
        // Branchless legacy history stays available for audit but is not
        // presented as a current filial price.
        entry.locationId?.trim().isNotEmpty != true ||
        entry.validUntil == null ||
        _priceLedgerDay(entry.observedAt).isAfter(day) ||
        (entry.validFrom != null &&
            _priceLedgerDay(entry.validFrom!).isAfter(day)) ||
        _priceLedgerDay(entry.validUntil!).isBefore(day)) {
      continue;
    }
    final key = [
      entry.source.name,
      entry.sourceAdapter?.trim().toLowerCase() ?? '',
      entry.storeName.trim().toLowerCase(),
      entry.locationId?.trim().toLowerCase() ?? '',
      entry.productId!.trim(),
      entry.quantity?.toStringAsFixed(6) ?? '',
      entry.unit?.trim().toLowerCase() ?? '',
    ].join('\u001f');
    final previous = latestByKey[key];
    if (previous == null ||
        entry.observedAt.isAfter(previous.observedAt) ||
        (entry.observedAt.isAtSameMomentAs(previous.observedAt) &&
            entry.id.compareTo(previous.id) > 0)) {
      latestByKey[key] = entry;
    }
  }
  final result = latestByKey.values.toList()
    ..sort((a, b) {
      final store = a.storeName.compareTo(b.storeName);
      if (store != 0) return store;
      final product = (a.productId ?? '').compareTo(b.productId ?? '');
      if (product != 0) return product;
      return b.observedAt.compareTo(a.observedAt);
    });
  return result;
}

DateTime _priceLedgerDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class _ProspectRegularPriceLedgerCard extends StatelessWidget {
  const _ProspectRegularPriceLedgerCard({
    required this.observations,
    required this.catalogProducts,
  });

  final List<PriceObservation> observations;
  final List<Product> catalogProducts;

  @override
  Widget build(BuildContext context) {
    final catalogById = {
      for (final product in catalogProducts) product.id: product,
    };
    final visible = observations.take(12).toList(growable: false);
    final countLabel = observations.length == 1
        ? '1 gespeicherter regulärer Preis mit Filialnachweis'
        : '${observations.length} gespeicherte reguläre Preise mit Filialnachweis';
    return Card(
      child: ExpansionTile(
        key: const ValueKey('prospect-regular-price-ledger-card'),
        leading: const Icon(Icons.fact_check_outlined),
        title: const Text('Aktuelle gespeicherte Normalpreise'),
        subtitle: Text(countLabel),
        children: [
          for (final observation in visible)
            _ProspectRegularPriceLedgerRow(
              observation: observation,
              product: catalogById[observation.productId],
            ),
          if (observations.length > visible.length)
            ListTile(
              dense: true,
              leading: const Icon(Icons.more_horiz),
              title: Text(
                'Weitere ${observations.length - visible.length} '
                'gespeicherte Normalpreise',
              ),
            ),
        ],
      ),
    );
  }
}

class _ProspectRegularPriceLedgerRow extends StatelessWidget {
  const _ProspectRegularPriceLedgerRow({
    required this.observation,
    required this.product,
  });

  final PriceObservation observation;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final branch = observation.locationId?.trim();
    final validity = [
      if (branch != null && branch.isNotEmpty) 'Filiale $branch',
      if (observation.validFrom != null)
        'ab ${_priceLedgerDate(observation.validFrom!)}',
      'bis ${_priceLedgerDate(observation.validUntil!)}',
      if (observation.sourceAdapter?.trim().isNotEmpty == true)
        'Quelle ${observation.sourceAdapter!.trim()}',
      if (observation.evidenceConfidence != null)
        'Evidenz ${evidenceConfidenceLabel(observation.evidenceConfidence!)}',
      'Nachweis vorhanden',
    ].join(' · ');
    final name = product?.name ?? observation.productId ?? 'Produkt unbekannt';
    final amount = observation.price.toStringAsFixed(2).replaceAll('.', ',');
    return ListTile(
      dense: true,
      leading: const Icon(Icons.price_check_outlined),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(validity, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '$amount €',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _priceLedgerDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month.${local.year}';
}

class _PriceDataQualityCard extends StatelessWidget {
  const _PriceDataQualityCard({required this.quality});

  final PriceDataQuality quality;

  @override
  Widget build(BuildContext context) {
    final storeLocations = quality.currentByStoreLocation.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return Card(
      key: const ValueKey('price-data-quality-card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gespeicherte Preisbelege',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${quality.current} von ${quality.total} Belegen sind aktuell '
              'und für die Routenplanung zugelassen.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (quality.currentProspectRegular > 0)
                  Chip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text(
                      'Prospekt-Normalpreise ${quality.currentProspectRegular}',
                    ),
                  ),
                if (quality.unclassifiedProspectEvidence > 0)
                  Chip(
                    avatar: const Icon(Icons.help_outline, size: 16),
                    label: Text(
                      'Prospektpreise ohne Preisrolle ${quality.unclassifiedProspectEvidence}',
                    ),
                  ),
                if (quality.currentReceipt > 0)
                  Chip(
                    avatar: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: Text('Kassenbons ${quality.currentReceipt}'),
                  ),
                if (quality.currentManual > 0)
                  Chip(
                    avatar: const Icon(Icons.edit_outlined, size: 16),
                    label: Text('Eigene Preise ${quality.currentManual}'),
                  ),
                if (quality.currentOpenPrices > 0)
                  Chip(
                    avatar: const Icon(Icons.public_outlined, size: 16),
                    label: Text('Open Prices ${quality.currentOpenPrices}'),
                  ),
                if (quality.futureEvidence > 0)
                  Chip(
                    avatar: const Icon(Icons.schedule_outlined, size: 16),
                    label: Text(
                      '${quality.futureEvidence} zukünftig',
                    ),
                  ),
                if (quality.staleEvidence > 0)
                  Chip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(
                      '${quality.staleEvidence} veraltet',
                    ),
                  ),
                if (quality.identityUncertainEvidence > 0)
                  Chip(
                    avatar: const Icon(Icons.help_outline, size: 16),
                    label: Text(
                      '${quality.identityUncertainEvidence} Identität unklar',
                    ),
                  ),
                if (quality.incomparableEvidence > 0)
                  Chip(
                    avatar: const Icon(Icons.info_outline, size: 16),
                    label: Text(
                      '${quality.incomparableEvidence} Mengenbasis fehlt',
                    ),
                  ),
                if (quality.invalidAmountEvidence > 0)
                  Chip(
                    avatar: const Icon(Icons.price_check_outlined, size: 16),
                    label: Text(
                      '${quality.invalidAmountEvidence} ungültiger Betrag',
                    ),
                  ),
                if (quality.lowConfidenceEvidence > 0)
                  Chip(
                    avatar: const Icon(Icons.warning_amber_outlined, size: 16),
                    label: Text(
                      '${quality.lowConfidenceEvidence} unsichere Belege',
                    ),
                  ),
                if (quality.notRouteReady > 0)
                  Chip(
                    avatar: const Icon(Icons.schedule_outlined, size: 16),
                    label: Text(
                      '${quality.notRouteReady} nicht routenfähig',
                    ),
                  ),
                if (quality.prospectOfferEvidence > 0)
                  Chip(
                    avatar: const Icon(Icons.local_offer_outlined, size: 16),
                    label: Text(
                      'Prospekt-Angebote separat ${quality.prospectOfferEvidence}',
                    ),
                  ),
              ],
            ),
            if (storeLocations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Aktuell je Markt/Filiale',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                storeLocations
                    .take(6)
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join(' · '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
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
  const _PriceSnapshotTile({
    super.key,
    required this.snapshot,
  });

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
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kein aktueller, vergleichbarer Preisbeleg'),
            Text(
              entry.gapLabel,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        trailing: const Text('fehlt'),
      );
    }
    final details = <String>[
      quote.sourceLabel,
      if (quote.branchLabel != null) 'Filiale ${quote.branchLabel}',
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

int _compareCurrentPriceSnapshots(_PriceSnapshot a, _PriceSnapshot b) {
  final priceA = a.quote?.rankingPrice ?? double.infinity;
  final priceB = b.quote?.rankingPrice ?? double.infinity;
  final byPrice = priceA.compareTo(priceB);
  if (byPrice != 0) return byPrice;

  final byProduct = a.item.product.name.toLowerCase().compareTo(
        b.item.product.name.toLowerCase(),
      );
  if (byProduct != 0) return byProduct;

  final byStore = a.quote!.storeName.toLowerCase().compareTo(
        b.quote!.storeName.toLowerCase(),
      );
  if (byStore != 0) return byStore;
  return a.item.product.id.compareTo(b.item.product.id);
}
