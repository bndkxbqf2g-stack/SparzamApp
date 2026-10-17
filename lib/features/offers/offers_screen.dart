import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import 'offer_import.dart';
import '../prospects/prospect_offer_card.dart';
import 'prospect_offer_products.dart';
import '../prospects/prospect_category_presentation.dart';
import 'offer_filter.dart';
import '../../services/prospect_feed_service.dart';
import '../prospects/prospect_feed_status.dart';
import '../prospects/prospect_cover_section.dart';
import '../prospects/prospect_issue_identity.dart';
import '../prospects/prospects_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({
    super.key,
    this.offers = const [],
    this.priceHistory = const [],
    this.onSave,
    this.onDelete,
    required this.catalogProducts,
    this.prospectRecords = const [],
    this.prospectIssues = const [],
    this.onAddToShoppingList,
    this.now,
    this.generatedAt,
    this.fromCache = false,
    this.onRefreshProspects,
    this.prospectsRefreshing = false,
    this.regularPriceCount,
    this.regularPricePersistenceStatus =
        ProspectRegularPricePersistenceStatus.standalone,
    this.persistedRegularPriceCounts,
  });

  // Kept for the shell/route data contract. The Angebote tab deliberately
  // renders only the current prospect feed; stored offers remain available to
  // the pricing and route pipeline.
  final List<Offer> offers;
  final List<PricePoint> priceHistory;
  final Future<List<Offer>> Function(Offer offer)? onSave;
  final Future<List<Offer>> Function(Offer offer)? onDelete;
  final List<Product> catalogProducts;
  final List<OfferImportRecord> prospectRecords;
  final List<ProspectIssue> prospectIssues;
  final ValueChanged<Product>? onAddToShoppingList;
  final DateTime? now;
  final DateTime? generatedAt;
  final bool fromCache;
  final Future<void> Function()? onRefreshProspects;
  final bool prospectsRefreshing;
  /// Count confirmed by the shell's local price-observation persistence.
  /// Null keeps standalone screens on their feed-derived fallback.
  final int? regularPriceCount;
  final ProspectRegularPricePersistenceStatus regularPricePersistenceStatus;
  /// Per-store counts confirmed by local price-observation persistence.
  final Map<String, int>? persistedRegularPriceCounts;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final searchController = TextEditingController();
  var query = '';
  List<OfferImportRecord>? _currentRecordsInput;
  DateTime? _currentRecordsDay;
  List<OfferImportRecord>? _currentRecordsCache;
  List<ProspectIssue>? _currentIssuesInput;
  DateTime? _currentIssuesDay;
  List<ProspectIssue>? _currentIssuesCache;

  List<OfferImportRecord> _currentRecords() {
    final day = offerFilterDay(widget.now);
    if (identical(_currentRecordsInput, widget.prospectRecords) &&
        _currentRecordsDay == day) {
      return _currentRecordsCache ?? const <OfferImportRecord>[];
    }
    final current = currentProspectRecords(
      widget.prospectRecords,
      now: widget.now,
    );
    _currentRecordsInput = widget.prospectRecords;
    _currentRecordsDay = day;
    _currentRecordsCache = current;
    return current;
  }

  List<ProspectIssue> _currentIssues() {
    final day = offerFilterDay(widget.now);
    if (identical(_currentIssuesInput, widget.prospectIssues) &&
        _currentIssuesDay == day) {
      return _currentIssuesCache ?? const <ProspectIssue>[];
    }
    final current = _currentProspectIssues(
      widget.prospectIssues,
      now: widget.now,
    );
    _currentIssuesInput = widget.prospectIssues;
    _currentIssuesDay = day;
    _currentIssuesCache = current;
    return current;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _openProspect(BuildContext context, ProspectIssue issue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProspectViewerScreen(
          issue: issue,
          records: _currentRecords(),
          catalogProducts: widget.catalogProducts,
          onAddProduct: widget.onAddToShoppingList,
          now: widget.now,
          onSaveOffer: widget.onSave,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRecords = _currentRecords();
    final currentProspectIssues = _currentIssues();

    return Scaffold(
      appBar: AppBar(title: const Text('Angebote'), centerTitle: true),
      body: ListView(
        key: const ValueKey('offers-scroll'),
        // Warm a short cover lead-in so image decoding starts before a fast
        // swipe reaches it. The nested cover/page lists keep their own
        // strict limits; the smaller reserve avoids retaining a full extra cover row.
        scrollCacheExtent: const ScrollCacheExtent.pixels(180),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const Center(child: Text('Die besten Preise. Für dich.')),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: 'Aktuelles Prospekt durchsuchen',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Suche löschen',
                      onPressed: () {
                        searchController.clear();
                        setState(() => query = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ProspectFeedStatusCard(
            generatedAt: widget.generatedAt,
            now: widget.now,
            fromCache: widget.fromCache,
            regularPriceCount: widget.regularPriceCount ??
                currentRecords.where(hasLearnableProspectRegularPrice).length,
            regularPricePersistenceStatus:
                widget.regularPricePersistenceStatus,
            onRefresh: widget.onRefreshProspects,
            refreshing: widget.prospectsRefreshing,
          ),
          const SizedBox(height: 12),
          if (currentProspectIssues.isNotEmpty) ...[
            ProspectCoverSection(
              issues: currentProspectIssues,
              onOpen: (issue) => _openProspect(context, issue),
            ),
            const SizedBox(height: 22),
          ],
          Text(
            'Aktuelles Prospekt',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Es werden ausschließlich aktuell gültige Prospektangebote angezeigt.',
          ),
          const SizedBox(height: 14),
          _ProspectOffers(
            records: currentRecords,
            issues: _currentProspectStatusIssues(
              widget.prospectIssues,
              now: widget.now,
            ),
            query: query,
            catalogProducts: widget.catalogProducts,
            onAddToShoppingList: widget.onAddToShoppingList,
          ),
          if (currentProspectIssues.isNotEmpty || currentRecords.isNotEmpty) ...[
            const SizedBox(height: 18),
            ProspectCoverageCard(
              coverage: calculateProspectCoverage(
                issues: currentProspectIssues,
                records: currentRecords,
                now: widget.now,
                catalogProducts: widget.catalogProducts,
                persistedRegularPriceCounts:
                    widget.persistedRegularPriceCounts,
              ),
              regularPricePersistenceStatus:
                  widget.regularPricePersistenceStatus,
            ),
          ],
        ],
      ),
    );
  }
}

List<ProspectIssue> _currentProspectStatusIssues(
  Iterable<ProspectIssue> issues, {
  DateTime? now,
}) =>
    issues
        .where(
          (issue) =>
              (issue.validFrom != null || issue.validUntil != null)
                  ? isOptionalOfferDateRangeActive(
                      validFrom: issue.validFrom,
                      validUntil: issue.validUntil,
                      now: now,
                    )
                  : true,
        )
        .toList(growable: false);

List<ProspectIssue> _currentProspectIssues(
  Iterable<ProspectIssue> issues, {
  DateTime? now,
}) {
  final byStore = <String, ProspectIssue>{};
  for (final issue in issues) {
    final hasCover = issue.thumbnailUrl?.trim().isNotEmpty == true ||
        issue.pages.isNotEmpty;
    if (!hasCover) continue;
    final validFrom = issue.validFrom;
    final validUntil = issue.validUntil;
    // A supplied start date is validity evidence even when a feed omits
    // its end date. Otherwise a future cover could appear in the current tab.
    if ((validFrom != null || validUntil != null) &&
        !isOptionalOfferDateRangeActive(
          validFrom: validFrom,
          validUntil: validUntil,
          now: now,
        )) {
      continue;
    }
    final key = prospectIssueKey(issue);
    final previous = byStore[key];
    if (previous == null ||
        _prospectIssueScore(issue) > _prospectIssueScore(previous)) {
      byStore[key] = issue;
    }
  }
  return byStore.values.toList(growable: false);
}

int _prospectIssueScore(ProspectIssue issue) {
  final status = switch (issue.sourceStatus) {
    'ok' => 4,
    'metadata_only' => 3,
    'current_fallback' => 2,
    'regional_only' => 1,
    _ => 0,
  };
  return status * 100000 +
      issue.pages.length * 1000 +
      (issue.thumbnailUrl?.trim().isNotEmpty == true ? 100 : 0) +
      issue.recordCount;
}

class _ProspectOffers extends StatefulWidget {
  const _ProspectOffers({
    required this.records,
    required this.issues,
    required this.query,
    required this.catalogProducts,
    this.onAddToShoppingList,
  });

  final List<OfferImportRecord> records;
  final List<ProspectIssue> issues;
  final String query;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddToShoppingList;

  @override
  State<_ProspectOffers> createState() => _ProspectOffersState();
}

const prospectOfferPageSize = 24;

class _ProspectOffersState extends State<_ProspectOffers> {
  final expandedStores = <String>{};
  final expandedCategories = <String>{};
  final _visibleCategoryCounts = <String, int>{};
  final _resolvedProducts = <String, Product?>{};
  List<OfferImportRecord>? _searchIndexInput;
  Map<OfferImportRecord, String>? _searchIndexCache;
  List<OfferImportRecord>? _filteredInput;
  String? _filteredQuery;
  Map<String, List<OfferImportRecord>>? _filteredByStore;
  List<OfferImportRecord>? _groupedInput;
  String? _groupedQuery;
  final _groupedCache = <String, Map<String, List<OfferImportRecord>>>{};

  @override
  void didUpdateWidget(covariant _ProspectOffers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.catalogProducts, widget.catalogProducts)) {
      _resolvedProducts.clear();
    }
    if (!identical(oldWidget.records, widget.records) ||
        oldWidget.query != widget.query) {
      _visibleCategoryCounts.clear();
    }
  }

  Map<OfferImportRecord, String> _searchIndex() {
    if (identical(_searchIndexInput, widget.records)) {
      return _searchIndexCache ?? const <OfferImportRecord, String>{};
    }
    final index = <OfferImportRecord, String>{};
    for (final record in widget.records) {
      final sourceCategory = record.category?.trim() ?? '';
      index[record] = [
        record.productLabel,
        record.storeName,
        sourceCategory,
        presentProspectCategory(sourceCategory),
        record.ean ?? '',
        record.packageSize ?? '',
        record.priceByBaseUnit ?? '',
      ].join(' ').toLowerCase();
    }
    _searchIndexInput = widget.records;
    _searchIndexCache = index;
    return index;
  }
  Map<String, List<OfferImportRecord>> _filteredRecordsByStore(
    String normalizedQuery,
  ) {
    if (identical(_filteredInput, widget.records) &&
        _filteredQuery == normalizedQuery) {
      return _filteredByStore ?? const <String, List<OfferImportRecord>>{};
    }

    final byStore = <String, List<OfferImportRecord>>{};
    final searchIndex = _searchIndex();
    for (final record in widget.records) {
      if (normalizedQuery.isNotEmpty &&
          !(searchIndex[record] ?? '').contains(normalizedQuery)) {
        continue;
      }
      byStore.putIfAbsent(prospectRecordKey(record), () => []).add(record);
    }
    _filteredInput = widget.records;
    _filteredQuery = normalizedQuery;
    _filteredByStore = byStore;
    return byStore;
  }

  Map<String, List<OfferImportRecord>> _groupedRecords(
    String storeName,
    List<OfferImportRecord> records,
    String normalizedQuery,
  ) {
    if (!identical(_groupedInput, widget.records) ||
        _groupedQuery != normalizedQuery) {
      _groupedInput = widget.records;
      _groupedQuery = normalizedQuery;
      _groupedCache.clear();
    }
    return _groupedCache.putIfAbsent(storeName, () => _grouped(records));
  }

  Product? _memoizedProduct(OfferImportRecord record) {
    final key = prospectOfferResolutionKey(record);
    if (_resolvedProducts.containsKey(key)) {
      return _resolvedProducts[key];
    }
    final product = addableProductForProspectOffer(
      record,
      widget.catalogProducts,
    );
    _resolvedProducts[key] = product;
    return product;
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = widget.query.trim().toLowerCase();
    final byStore = _filteredRecordsByStore(normalizedQuery);

    if (byStore.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._sourceNotices(),
          const Text('Keine passenden Prospektangebote gefunden.'),
        ],
      );
    }

    return Column(
      children: [
        ..._sourceNotices(),
        for (final entry in byStore.entries)
          ExpansionTile(
            key: PageStorageKey('prospect-store-${entry.key}'),
            initiallyExpanded: false,
            title: Text(
              entry.value.first.storeName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${prospectRecordLocationLabel(entry.value.first.storeName, entry.value)} · '
              '${entry.value.length} Angebote',
            ),
            onExpansionChanged: (expanded) => setState(() {
              if (expanded) {
                expandedStores.add(entry.key);
              } else {
                expandedStores.remove(entry.key);
              }
            }),
            children: expandedStores.contains(entry.key)
                ? [
                    for (final category
                        in _groupedRecords(
                          entry.key,
                          entry.value,
                          normalizedQuery,
                        ).entries)
                      ExpansionTile(
                        key: PageStorageKey(
                          'prospect-category-${entry.key}-${category.key}',
                        ),
                        title: Text(category.key),
                        subtitle: Text('${category.value.length} Artikel'),
                        onExpansionChanged: (expanded) => setState(() {
                          final key = '${entry.key}|${category.key}';
                          if (expanded) {
                            expandedCategories.add(key);
                          } else {
                            expandedCategories.remove(key);
                          }
                        }),
                        children: _categoryChildren(
                          storeName: entry.key,
                          categoryName: category.key,
                          records: category.value,
                        ),
                      ),
                  ]
                : const [],
          ),
      ],
    );
  }

  List<Widget> _categoryChildren({
    required String storeName,
    required String categoryName,
    required List<OfferImportRecord> records,
  }) {
    final key = '$storeName|$categoryName';
    if (!expandedCategories.contains(key)) return const <Widget>[];

    final visibleCount = (_visibleCategoryCounts[key] ?? prospectOfferPageSize)
        .clamp(0, records.length)
        .toInt();
    final children = <Widget>[
      for (final record in records.take(visibleCount)) _buildProspectCard(record),
    ];
    if (visibleCount < records.length) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: ValueKey('prospect-load-more-$key'),
              onPressed: () => setState(() {
                final next = visibleCount + prospectOfferPageSize;
                _visibleCategoryCounts[key] =
                    next > records.length ? records.length : next;
              }),
              icon: const Icon(Icons.expand_more),
              label: Text(
                'Weitere Artikel laden (${records.length - visibleCount})',
              ),
            ),
          ),
        ),
      );
    }
    return children;
  }

  Widget _buildProspectCard(OfferImportRecord record) {
    final product = _memoizedProduct(record);
    final manualProduct =
        product == null ? manualProductForProspectOffer(record) : null;
    final regionalProduct = record.regionalOnly
        ? listOnlyProductForRegionalProspectOffer(
            record,
            widget.catalogProducts,
          )
        : null;
    final selectableProduct =
        record.regionalOnly ? regionalProduct : product ?? manualProduct;
    final listOnlyWithoutBranch =
        record.regionalOnly && selectableProduct != null;
    final onAdd = widget.onAddToShoppingList;
    final canAdd = onAdd != null && selectableProduct != null;
    return ProspectOfferCard(
      key: ValueKey('prospect-offer-${prospectOfferRecordKey(record)}'),
      record: record,
      product: selectableProduct,
      compact: true,
      requiresManualConfirmation:
          listOnlyWithoutBranch || (product == null && manualProduct != null),
      listOnlyWithoutBranch: listOnlyWithoutBranch,
      onAdd: !canAdd ? null : () => onAdd(selectableProduct),
    );
  }

  List<Widget> _sourceNotices() {
    if (widget.query.trim().isNotEmpty) return const <Widget>[];
    final currentCounts = <String, int>{};
    final regionalCounts = <String, int>{};
    final unscopedCounts = <String, int>{};
    final unscopedRegionalCounts = <String, int>{};
    for (final record in widget.records) {
      currentCounts.update(
        prospectRecordKey(record),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final recordBranch = record.branchId?.trim();
      if (recordBranch == null || recordBranch.isEmpty) {
        unscopedCounts.update(
          record.storeName,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      if (record.regionalOnly) {
        regionalCounts.update(
          prospectRecordKey(record),
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (recordBranch == null || recordBranch.isEmpty) {
          unscopedRegionalCounts.update(
            record.storeName,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }
    final visible = <String, ProspectIssue>{};
    for (final issue in widget.issues) {
      final hasBranch = issue.branchId?.trim().isNotEmpty == true;
      final issueKey = prospectIssueKey(issue);
      final count = hasBranch
          ? (currentCounts[issueKey] ?? 0) +
              (unscopedCounts[issue.storeName] ?? 0)
          : currentCounts[issue.storeName] ?? 0;
      final regionalCount = hasBranch
          ? (regionalCounts[issueKey] ?? 0) +
              (unscopedRegionalCounts[issue.storeName] ?? 0)
          : regionalCounts[issue.storeName] ?? 0;
      final usesCurrentFallback = issue.sourceStatus == 'error' && count > 0;
      final needsRegionalNotice = issue.sourceStatus == 'regional_only' ||
          (count > 0 && regionalCount == count);
      if (count > 0 && !usesCurrentFallback && !needsRegionalNotice) continue;
      final String status;
      if (needsRegionalNotice) {
        status = 'regional_only';
      } else if (issue.sourceStatus == 'ok') {
        status = 'no_current_offers';
      } else if (usesCurrentFallback) {
        status = 'current_fallback';
      } else {
        status = issue.sourceStatus;
      }
      visible.putIfAbsent(
        issueKey,
        () => ProspectIssue(
          storeName: issue.storeName,
          title: issue.title,
          pages: issue.pages,
          url: issue.url,
          thumbnailUrl: issue.thumbnailUrl,
          branchId: issue.branchId,
          location: issue.location,
          address: issue.address,
          sourceAdapter: issue.sourceAdapter,
          sourceStatus: status,
          recordCount: count,
          validFrom: issue.validFrom,
          validUntil: issue.validUntil,
        ),
      );
    }
    return [
      for (final issue in visible.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _OfferSourceNotice(issue: issue),
        ),
    ];
  }
}

class _OfferSourceNotice extends StatelessWidget {
  const _OfferSourceNotice({required this.issue});

  final ProspectIssue issue;

  @override
  Widget build(BuildContext context) {
    final message = switch (issue.sourceStatus) {
      'no_current_offers' => 'Keine aktuell gültigen Angebotsdaten geladen.',
      'metadata_only' =>
        'Prospektquelle gefunden; Produktdaten fehlen aktuell.',
      'current_fallback' =>
        'Der letzte geprüfte Prospektstand wird verwendet; die automatische '
            'Aktualisierung ist aktuell nicht verfügbar.',
      'error' =>
        'Automatischer Abruf aktuell nicht verfügbar. '
            'Der offizielle Prospekt bleibt direkt erreichbar.',
      'regional_only' =>
        'Angebote sind nur regional erkannt; eine exakte Filiale ist noch '
            'nicht bestätigt und die Artikel bleiben für die Route gesperrt.',
      _ => 'Für diesen Markt sind aktuell keine Angebotsdaten verfügbar.',
    };
    final location = issue.location?.trim();
    final issueUri = _safeProspectUri(issue.url);
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade900),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location == null || location.isEmpty
                        ? issue.storeName
                        : '${issue.storeName} $location',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(message),
                  if (issueUri != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => launchUrl(
                          issueUri,
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Offiziellen Prospekt öffnen'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Uri? _safeProspectUri(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      uri.host.trim().isEmpty ||
      (scheme != 'http' && scheme != 'https')) {
    return null;
  }
  return uri;
}

Map<String, List<OfferImportRecord>> _grouped(List<OfferImportRecord> records) {
  final grouped = <String, List<OfferImportRecord>>{};
  for (final record in records) {
    grouped.putIfAbsent(_offerCategory(record), () => []).add(record);
  }
  final entries = grouped.entries.toList()
    ..sort((a, b) => _categoryRank(a.key).compareTo(_categoryRank(b.key)));
  return {for (final entry in entries) entry.key: entry.value};
}

String _offerCategory(OfferImportRecord record) {
  final sourceCategory = record.category?.trim();
  if (sourceCategory != null && sourceCategory.isNotEmpty) {
    return presentProspectCategory(sourceCategory);
  }
  return fallbackProspectCategory(record.productLabel);
}

int _categoryRank(String category) =>
    const {
      'Obst & Gemüse': 0,
      'Milchprodukte': 1,
      'Fleisch & Fisch': 2,
      'Backwaren': 3,
      'Kaffee & Snacks': 4,
      'Getränke': 5,
      'Vorrat & Konserven': 6,
      'Tiefkühl': 7,
      'Kühlregal': 8,
      'Haushalt': 20,
      'Drogerie': 21,
      'Garten & Pflanzen': 22,
      'Non-Food': 30,
      'Dauerhaft günstiger': 39,
      'Weitere Angebote': 40,
    }[category] ??
    50;
