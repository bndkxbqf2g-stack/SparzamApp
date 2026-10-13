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

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final searchController = TextEditingController();
  var query = '';

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
          records: currentProspectRecords(
            widget.prospectRecords,
            now: widget.now,
          ),
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
    final currentProspectIssues = _currentProspectIssues(
      widget.prospectIssues,
      now: widget.now,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Angebote'), centerTitle: true),
      body: ListView(
        key: const ValueKey('offers-scroll'),
        // Offer groups can contain many current prospect records. Keep the
        // outer scroll from building a speculative tail while the user moves.
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
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
            records: currentProspectRecords(
              widget.prospectRecords,
              now: widget.now,
            ),
            issues: widget.prospectIssues,
            query: query,
            catalogProducts: widget.catalogProducts,
            onAddToShoppingList: widget.onAddToShoppingList,
          ),
        ],
      ),
    );
  }
}

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
    if (validUntil != null &&
        !isOfferDateRangeActive(
          validFrom: validFrom,
          validUntil: validUntil,
          now: now,
        )) {
      continue;
    }
    final previous = byStore[issue.storeName];
    if (previous == null ||
        _prospectIssueScore(issue) > _prospectIssueScore(previous)) {
      byStore[issue.storeName] = issue;
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

class _ProspectOffersState extends State<_ProspectOffers> {
  final expandedStores = <String>{};
  final expandedCategories = <String>{};
  final _resolvedProducts = <String, Product?>{};

  @override
  void didUpdateWidget(covariant _ProspectOffers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.catalogProducts, widget.catalogProducts)) {
      _resolvedProducts.clear();
    }
  }

  Product? _memoizedProduct(OfferImportRecord record) {
    final key = [
      record.sourceId,
      record.storeName,
      record.productLabel,
      record.offerPrice,
      record.packageSize,
    ].join('|');
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
    final byStore = <String, List<OfferImportRecord>>{};
    for (final record in widget.records) {
      final searchable =
          '${record.storeName} ${record.category ?? ''} '
                  '${presentProspectCategory(record.category)} ${record.productLabel}'
              .toLowerCase();
      if (normalizedQuery.isNotEmpty && !searchable.contains(normalizedQuery)) {
        continue;
      }
      byStore.putIfAbsent(record.storeName, () => []).add(record);
    }

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
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${prospectRecordLocationLabel(entry.key, entry.value)} · '
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
                    for (final category in _grouped(entry.value).entries)
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
                        children:
                            expandedCategories.contains(
                              '${entry.key}|${category.key}',
                            )
                            ? [
                                for (final record in category.value)
                                  _buildProspectCard(record),
                              ]
                            : const [],
                      ),
                  ]
                : const [],
          ),
      ],
    );
  }

  Widget _buildProspectCard(OfferImportRecord record) {
    final product = _memoizedProduct(record);
    final onAdd = widget.onAddToShoppingList;
    return ProspectOfferCard(
      key: ValueKey('prospect-offer-${record.sourceId}'),
      record: record,
      product: product,
      compact: true,
      onAdd: product == null || onAdd == null ? null : () => onAdd(product),
    );
  }

  List<Widget> _sourceNotices() {
    if (widget.query.trim().isNotEmpty) return const <Widget>[];
    final currentCounts = <String, int>{};
    for (final record in widget.records) {
      currentCounts.update(
        record.storeName,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final visible = <String, ProspectIssue>{};
    for (final issue in widget.issues) {
      final count = currentCounts[issue.storeName] ?? 0;
      final regionalCount = widget.records
          .where(
            (record) =>
                record.storeName == issue.storeName && record.regionalOnly,
          )
          .length;
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
        issue.storeName,
        () => ProspectIssue(
          storeName: issue.storeName,
          title: issue.title,
          pages: issue.pages,
          url: issue.url,
          thumbnailUrl: issue.thumbnailUrl,
          branchId: issue.branchId,
          location: issue.location,
          address: issue.address,
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
