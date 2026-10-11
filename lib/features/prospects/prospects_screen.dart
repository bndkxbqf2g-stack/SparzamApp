import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/sparzam_theme.dart';
import '../offers/offer_import.dart';
import '../offers/prospect_offer_products.dart';
import 'prospect_category_presentation.dart';
import '../../models/product.dart';
import '../../services/prospect_feed_service.dart';
import '../offers/offer_filter.dart';
import 'prospect_offer_card.dart';
import 'prospect_feed_status.dart';

class ProspectsScreen extends StatefulWidget {
  const ProspectsScreen({
    super.key,
    required this.records,
    this.prospects = const [],
    this.catalogProducts = const [],
    this.onAddProduct,
    this.now,
    this.fromCache = false,
    this.generatedAt,
    this.onRefreshProspects,
    this.prospectsRefreshing = false,
  });

  final List<OfferImportRecord> records;
  final List<ProspectIssue> prospects;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddProduct;
  final DateTime? now;
  final bool fromCache;
  final DateTime? generatedAt;
  final Future<void> Function()? onRefreshProspects;
  final bool prospectsRefreshing;

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  final searchController = TextEditingController();
  var query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRecords = currentProspectRecords(
      widget.records,
      now: widget.now,
    );
    final matchingRecords = _matchingProspectRecords(currentRecords, query);
    final currentCounts = <String, int>{};
    for (final record in currentRecords) {
      currentCounts.update(
        record.storeName,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final byStore = <String, List<ProspectIssue>>{};
    for (final issue in widget.prospects) {
      byStore.putIfAbsent(issue.storeName, () => []).add(issue);
    }
    final visibleProspects = <ProspectIssue>[
      for (final entries in byStore.values)
        _visibleIssue(
          entries,
          currentCounts[entries.first.storeName] ?? 0,
          now: widget.now,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        const Icon(
          Icons.menu_book_outlined,
          color: SparzamTheme.deepGreen,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          'Prospekte',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Center(
          child: Text('Aktuelle Prospekte. Produkte antippen und vormerken.'),
        ),
        const SizedBox(height: 14),
        Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: searchController,
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: 'Prospekte und Artikel durchsuchen',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.trim().isEmpty
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
        ),
        ProspectFeedStatusCard(
          generatedAt: widget.generatedAt,
          fromCache: widget.fromCache,
          onRefresh: widget.onRefreshProspects,
          refreshing: widget.prospectsRefreshing,
        ),
        const SizedBox(height: 20),
        if (query.trim().isNotEmpty)
          _ProspectSearchResults(
            records: matchingRecords,
            catalogProducts: widget.catalogProducts,
            onAddProduct: widget.onAddProduct,
            query: query,
          )
        else if (visibleProspects.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Noch keine Prospekte geladen.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          Text('Alle Märkte', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleProspects.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final issue = visibleProspects[index];
                return _ProspectCard(
                  issue: issue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ProspectViewer(
                        issue: issue,
                        records: currentRecords,
                        catalogProducts: widget.catalogProducts,
                        onAddProduct: widget.onAddProduct,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (query.trim().isEmpty && visibleProspects.isNotEmpty)
          ProspectCoverageCard(
            coverage: calculateProspectCoverage(
              issues: visibleProspects,
              records: currentRecords,
            ),
          ),
      ],
    );
  }
}

class _ProspectSearchResults extends StatelessWidget {
  const _ProspectSearchResults({
    required this.records,
    required this.catalogProducts,
    required this.onAddProduct,
    required this.query,
  });

  final List<OfferImportRecord> records;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddProduct;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Keine aktuellen Prospektartikel für „${query.trim()}“ gefunden.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final byStore = <String, List<OfferImportRecord>>{};
    for (final record in records) {
      byStore.putIfAbsent(record.storeName, () => []).add(record);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${records.length} passende Prospektartikel',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Artikel werden nur mit ihrem vorhandenen Händlernachweis und '
          'aktuellen Gültigkeitszeitraum angeboten.',
        ),
        const SizedBox(height: 12),
        for (final entry in byStore.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          for (final record in entry.value)
            ProspectOfferCard(
              key: ValueKey('prospect-search-offer-${record.sourceId}'),
              record: record,
              product: addableProductForProspectOffer(
                record,
                catalogProducts,
              ),
              compact: true,
              onAdd: onAddProduct == null
                  ? null
                  : () {
                      final product = addableProductForProspectOffer(
                        record,
                        catalogProducts,
                      );
                      if (product != null) onAddProduct!(product);
                    },
            ),
        ],
      ],
    );
  }
}

List<OfferImportRecord> _matchingProspectRecords(
  Iterable<OfferImportRecord> records,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return records.toList(growable: false);
  return records
      .where((record) {
        final category = record.category?.trim() ?? '';
        final searchable = [
          record.productLabel,
          record.storeName,
          category,
          presentProspectCategory(category),
          fallbackProspectCategory(record.productLabel),
        ].join(' ').toLowerCase();
        return searchable.contains(normalized);
      })
      .toList(growable: false);
}

ProspectIssue _visibleIssue(
  List<ProspectIssue> entries,
  int currentRecordCount, {
  DateTime? now,
}) {
  final current = entries
      .where(
        (issue) =>
            issue.validFrom != null &&
            issue.validUntil != null &&
            isOfferDateRangeActive(
              validFrom: issue.validFrom,
              validUntil: issue.validUntil!,
              now: now,
            ),
      )
      .firstOrNull;
  final selected = current ?? entries.first;
  final String sourceStatus;
  if (currentRecordCount == 0 &&
      (current?.sourceStatus ?? selected.sourceStatus) == 'ok') {
    sourceStatus = 'no_current_offers';
  } else if (selected.sourceStatus == 'error' && currentRecordCount > 0) {
    sourceStatus = 'current_fallback';
  } else {
    sourceStatus = selected.sourceStatus;
  }
  return ProspectIssue(
    storeName: selected.storeName,
    title: current?.title ?? 'Aktionsprospekt',
    pages: current?.pages ?? const <ProspectPage>[],
    url: current?.url ?? officialProspectUrl(selected.storeName, selected.url),
    thumbnailUrl: current?.thumbnailUrl,
    branchId: current?.branchId ?? selected.branchId,
    location: current?.location ?? selected.location,
    address: current?.address ?? selected.address,
    sourceStatus: sourceStatus,
    recordCount: currentRecordCount,
    validFrom: current?.validFrom,
    validUntil: current?.validUntil,
  );
}

class _ProspectCard extends StatelessWidget {
  const _ProspectCard({required this.issue, required this.onTap});

  final ProspectIssue issue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPages = issue.pages.isNotEmpty;
    return SizedBox(
      width: 250,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: hasPages
                    ? Image.network(
                        issue.pages.first.imageUrl,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.menu_book, size: 56),
                      )
                    : const Center(
                        child: Icon(
                          Icons.local_offer_outlined,
                          size: 56,
                          color: SparzamTheme.deepGreen,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (issue.location?.trim().isNotEmpty == true)
                      Text(
                        issue.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    Text(
                      _prospectCardSummary(issue),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: issue.sourceStatus == 'error'
                            ? Colors.orange.shade900
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _prospectCardSummary(ProspectIssue issue) {
  if (issue.sourceStatus == 'current_fallback') {
    return '${issue.recordCount} Angebote aus dem letzten geprüften '
        'Prospektstand. Automatische Aktualisierung aktuell nicht verfügbar.';
  }
  if (issue.recordCount > 0) return '${issue.recordCount} Angebote geladen';
  return _sourceStatusLabel(issue);
}

String _sourceStatusLabel(ProspectIssue issue) {
  if (issue.sourceStatus == 'no_current_offers') {
    return 'Keine aktuell gültigen Angebotsdaten geladen.';
  }
  if (issue.sourceStatus == 'current_fallback') {
    return 'Der letzte geprüfte Prospektstand wird verwendet; die automatische '
        'Aktualisierung ist aktuell nicht verfügbar.';
  }
  if (issue.sourceStatus == 'error') {
    return 'Automatischer Abruf aktuell nicht verfügbar. '
        'Der offizielle Prospekt bleibt direkt erreichbar.';
  }
  if (issue.sourceStatus == 'ok' && issue.recordCount > 0) {
    return '${issue.recordCount} Angebote automatisch geladen. '
        'Prospektseiten werden beim Händler geöffnet, wenn keine Bildseiten vorliegen.';
  }
  if (issue.sourceStatus == 'metadata_only') {
    return 'Prospektquelle gefunden; strukturierte Produktdaten fehlen aktuell.';
  }
  return 'Offizielle Prospektquelle verfügbar.';
}

class _ProspectViewer extends StatelessWidget {
  const _ProspectViewer({
    required this.issue,
    required this.records,
    required this.catalogProducts,
    this.onAddProduct,
  });

  final ProspectIssue issue;
  final List<OfferImportRecord> records;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final items = records
        .where((record) => record.storeName == issue.storeName)
        .toList(growable: false);
    final groupedItems = <String, List<OfferImportRecord>>{};
    for (final record in items) {
      groupedItems
          .putIfAbsent(_prospectCategoryForRecord(record), () => [])
          .add(record);
    }
    final categories = groupedItems.keys.toList()
      ..sort(
        (a, b) =>
            _prospectCategoryOrder(a).compareTo(_prospectCategoryOrder(b)),
      );

    return Scaffold(
      appBar: AppBar(title: Text(issue.storeName)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (issue.location?.trim().isNotEmpty == true)
            Card(
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.store_outlined),
                title: Text(issue.location!),
                subtitle: issue.address?.trim().isNotEmpty == true
                    ? Text(issue.address!)
                    : null,
              ),
            ),
          if (issue.url != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(issue.url!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Offiziellen Prospekt öffnen'),
              ),
            ),
          Text(issue.title, style: Theme.of(context).textTheme.titleLarge),
          if (issue.validFrom != null && issue.validUntil != null)
            Text(
              '${_prospectDate(issue.validFrom!)} – ${_prospectDate(issue.validUntil!)}',
              style: const TextStyle(color: Colors.black54),
            ),
          if (issue.pages.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Prospektseiten (${issue.pages.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
          if (issue.pages.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktuelle Angebote dieses Marktes. Durchblättern und '
                      'Produkte antippen, um sie zur Einkaufsliste hinzuzufügen.',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _sourceStatusLabel(issue),
                      style: TextStyle(
                        color: issue.sourceStatus == 'error'
                            ? Colors.orange.shade900
                            : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final page in issue.pages)
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Image.network(
                      page.zoomUrl ?? page.imageUrl,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                            height: 180,
                            child: Icon(Icons.broken_image),
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('Seite ${page.number}'),
                    ),
                  ],
                ),
              ),
          if (items.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 10),
              child: Text(
                'Produkte antippen und zur Einkaufsliste hinzufügen',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final category in categories) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  category,
                  key: ValueKey('prospect-category-$category'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      for (final record in groupedItems[category]!)
                        SizedBox(
                          width: width,
                          child: Builder(
                            builder: (context) {
                              final product = addableProductForProspectOffer(
                                record,
                                catalogProducts,
                              );
                              return ProspectOfferCard(
                                key: ValueKey(
                                  'prospect-offer-${record.sourceId}',
                                ),
                                record: record,
                                product: product,
                                onAdd: onAddProduct == null || product == null
                                    ? null
                                    : () => onAddProduct!(product),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

const _prospectCategoryRanks = <String, int>{
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
};

int _prospectCategoryOrder(String category) =>
    _prospectCategoryRanks[category] ?? 50;

String _prospectCategory(String label) {
  return fallbackProspectCategory(label);
}

String _prospectCategoryForRecord(OfferImportRecord record) {
  final sourceCategory = record.category?.trim();
  return sourceCategory == null || sourceCategory.isEmpty
      ? _prospectCategory(record.productLabel)
      : presentProspectCategory(sourceCategory);
}

String _prospectDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

