import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/offer.dart';
import '../offers/offer_import.dart';
import '../offers/prospect_offer_products.dart';
import 'prospect_category_presentation.dart';
import '../../models/product.dart';
import '../../services/prospect_feed_service.dart';
import '../offers/offer_filter.dart';
import 'prospect_offer_card.dart';
import 'prospect_feed_status.dart';
import 'prospect_page_offer_dialog.dart';

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
    this.onSaveOffer,
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
  final Future<List<Offer>> Function(Offer offer)? onSaveOffer;

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  final searchController = TextEditingController();
  var query = '';
  String? selectedCategory;
  String? selectedStore;
  var _filtersExpanded = true;

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
    final categories = _prospectCategories(currentRecords);
    final stores = _prospectStores(currentRecords, widget.prospects);
    final activeCategory = categories.contains(selectedCategory)
        ? selectedCategory
        : null;
    final activeStore = stores.contains(selectedStore) ? selectedStore : null;
    final matchingRecords = _matchingProspectRecords(
      currentRecords,
      query,
      category: activeCategory,
      storeName: activeStore,
    );
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
    final hasSelection = query.trim().isNotEmpty ||
        activeCategory != null ||
        activeStore != null;

    return Theme(
      data: _bringTheme(context),
      child: ColoredBox(
        color: _bringBackground,
        child: ListView(
          key: const ValueKey('prospect-bring-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _BringHeader(location: _prospectPostalCode(visibleProspects)),
            const SizedBox(height: 8),
            Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: searchController,
                onChanged: (value) => setState(() => query = value),
                style: const TextStyle(color: _bringWhite),
                decoration: InputDecoration(
                  hintText: 'Prospekte und Artikel durchsuchen',
                  hintStyle: const TextStyle(color: _bringMuted),
                  prefixIcon: const Icon(Icons.search, color: _bringMuted),
                  suffixIcon: query.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Suche löschen',
                          onPressed: () {
                            searchController.clear();
                            setState(() => query = '');
                          },
                          icon: const Icon(Icons.close, color: _bringMuted),
                        ),
                  filled: true,
                  fillColor: _bringSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_filtersExpanded && categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Material(
                type: MaterialType.transparency,
                child: _ProspectCategoryChips(
                  categories: categories,
                  selectedCategory: activeCategory,
                  onSelected: (category) =>
                      setState(() => selectedCategory = category),
                ),
              ),
            ],
            if (_filtersExpanded && stores.isNotEmpty) ...[
              const SizedBox(height: 8),
              Material(
                type: MaterialType.transparency,
                child: _ProspectStoreChips(
                  stores: stores,
                  selectedStore: activeStore,
                  onSelected: (store) => setState(() => selectedStore = store),
                ),
              ),
            ],
            ProspectFeedStatusCard(
              generatedAt: widget.generatedAt,
              now: widget.now,
              fromCache: widget.fromCache,
              onRefresh: widget.onRefreshProspects,
              refreshing: widget.prospectsRefreshing,
            ),
            const SizedBox(height: 18),
            if (hasSelection)
              _ProspectSearchResults(
                records: matchingRecords,
                prospects: visibleProspects,
                catalogProducts: widget.catalogProducts,
                onAddProduct: widget.onAddProduct,
                query: query,
              )
            else if (visibleProspects.isEmpty)
              const Card(
                color: _bringSurface,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Noch keine Prospekte geladen.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              _BringSectionTitle(
                title: 'Deine Favoriten',
                actionLabel: 'Mehr ›',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleProspects.length > 2 ? 2 : visibleProspects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final issue = visibleProspects[index];
                    return _ProspectCard(
                      issue: issue,
                      compact: false,
                      showLocation: false,
                      showSummary: false,
                      onTap: () => _openProspect(
                        context,
                        issue,
                        currentRecords,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _BringSectionTitle(
                title: 'Weitere Prospekte',
                showFilter: true,
                onFilter: () => setState(
                  () => _filtersExpanded = !_filtersExpanded,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Alle Prospekte',
                key: ValueKey('prospect-grid-label'),
                style: TextStyle(
                  color: _bringWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 650 ? 3 : 2;
                  final gap = 12.0;
                  final width =
                      (constraints.maxWidth - (columns - 1) * gap) / columns;
                  return Wrap(
                    key: const ValueKey('prospect-grid'),
                    spacing: gap,
                    runSpacing: 14,
                    children: [
                      for (final issue in visibleProspects)
                        SizedBox(
                          width: width,
                          child: _ProspectCard(
                            issue: issue,
                            compact: true,
                            showLocation: true,
                            showSummary: true,
                            onTap: () => _openProspect(
                              context,
                              issue,
                              currentRecords,
                            ),
                          ),
                        ),
                    ],
                  );
                },
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
        ),
      ),
    );
  }

  void _openProspect(
    BuildContext context,
    ProspectIssue issue,
    List<OfferImportRecord> currentRecords,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ProspectViewer(
          issue: issue,
          records: currentRecords,
          catalogProducts: widget.catalogProducts,
          onAddProduct: widget.onAddProduct,
          now: widget.now,
          onSaveOffer: widget.onSaveOffer,
        ),
      ),
    );
  }
}

class _ProspectSearchResults extends StatelessWidget {
  const _ProspectSearchResults({
    required this.records,
    required this.prospects,
    required this.catalogProducts,
    required this.onAddProduct,
    required this.query,
  });

  final List<OfferImportRecord> records;
  final List<ProspectIssue> prospects;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddProduct;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      final trimmedQuery = query.trim();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            trimmedQuery.isEmpty
                ? 'Keine aktuellen Prospektartikel für diese Auswahl gefunden.'
                : 'Keine aktuellen Prospektartikel für „$trimmedQuery“ gefunden.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final byStore = <String, List<OfferImportRecord>>{};
    for (final record in records) {
      byStore.putIfAbsent(record.storeName, () => []).add(record);
    }
    final issueByStore = <String, ProspectIssue>{};
    for (final issue in prospects) {
      issueByStore.putIfAbsent(issue.storeName, () => issue);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (entry.value.every(
                      (record) => record.location?.trim().isEmpty ?? true,
                    ) &&
                    issueByStore[entry.key]?.location?.trim().isNotEmpty ==
                        true)
                  Text(
                    issueByStore[entry.key]!.location!.trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
              ],
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
  String query, {
  String? category,
  String? storeName,
}) {
  final normalized = query.trim().toLowerCase();
  return records
      .where((record) {
        if (storeName != null && record.storeName != storeName) {
          return false;
        }
        if (category != null && _prospectCategoryForRecord(record) != category) {
          return false;
        }
        if (normalized.isEmpty) return true;
        final sourceCategory = record.category?.trim() ?? '';
        final searchable = [
          record.productLabel,
          record.storeName,
          sourceCategory,
          presentProspectCategory(sourceCategory),
          fallbackProspectCategory(record.productLabel),
        ].join(' ').toLowerCase();
        return searchable.contains(normalized);
      })
      .toList(growable: false);
}

List<String> _prospectCategories(Iterable<OfferImportRecord> records) {
  final categories = <String>{
    for (final record in records) _prospectCategoryForRecord(record),
  };
  return categories.toList()..sort();
}

List<String> _prospectStores(
  Iterable<OfferImportRecord> records,
  Iterable<ProspectIssue> issues,
) {
  final stores = <String>[];
  for (final name in [
    ...issues.map((issue) => issue.storeName),
    ...records.map((record) => record.storeName),
  ]) {
    if (name.trim().isNotEmpty && !stores.contains(name)) stores.add(name);
  }
  return stores;
}

class _ProspectCategoryChips extends StatelessWidget {
  const _ProspectCategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Alle Kategorien'),
            selected: selectedCategory == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            ChoiceChip(
              label: Text(category),
              selected: selectedCategory == category,
              onSelected: (_) => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ProspectStoreChips extends StatelessWidget {
  const _ProspectStoreChips({
    required this.stores,
    required this.selectedStore,
    required this.onSelected,
  });

  final List<String> stores;
  final String? selectedStore;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Alle Märkte'),
            selected: selectedStore == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final store in stores) ...[
            ChoiceChip(
              label: Text(store),
              selected: selectedStore == store,
              onSelected: (_) => onSelected(store),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
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
  const _ProspectCard({
    required this.issue,
    required this.onTap,
    this.compact = false,
    this.showLocation = true,
    this.showSummary = true,
  });

  final ProspectIssue issue;
  final VoidCallback onTap;
  final bool compact;
  final bool showLocation;
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    final previewUrl = issue.pages.isNotEmpty
        ? issue.pages.first.imageUrl.trim()
        : issue.thumbnailUrl?.trim();
    final imageHeight = compact ? 168.0 : 190.0;
    final validity = _prospectValidityLabel(issue);

    return SizedBox(
      width: compact ? double.infinity : 214,
      child: Card(
        color: _bringSurface,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: imageHeight,
                child: previewUrl == null || previewUrl.isEmpty
                    ? _bringCoverPlaceholder()
                    : Image.network(
                        previewUrl,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _bringCoverPlaceholder(),
                      ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 12,
                  10,
                  compact ? 10 : 12,
                  11,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            issue.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF27343A),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.favorite_border,
                          color: Color(0xFFE96A73),
                          size: 22,
                        ),
                      ],
                    ),
                    if (showLocation &&
                        issue.location?.trim().isNotEmpty == true)
                      Text(
                        issue.location!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6F7C80),
                          fontSize: 12,
                        ),
                      ),
                    if (validity != null)
                      Text(
                        validity,
                        style: const TextStyle(
                          color: Color(0xFF6F7C80),
                          fontSize: 12,
                        ),
                      ),
                    if (showSummary)
                      Text(
                        _prospectCardSummary(issue),
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: issue.sourceStatus == 'error'
                              ? Colors.deepOrange.shade700
                              : const Color(0xFF6F7C80),
                          fontSize: 11,
                          height: 1.2,
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

Widget _bringCoverPlaceholder() {
  return const ColoredBox(
    color: Color(0xFF435A64),
    child: Center(
      child: Icon(
        Icons.local_offer_outlined,
        color: _bringAccent,
        size: 52,
      ),
    ),
  );
}
String? _prospectPostalCode(Iterable<ProspectIssue> issues) {
  final pattern = RegExp(r'\b\d{5}\b');
  for (final issue in issues) {
    final address = issue.address?.trim();
    if (address == null || address.isEmpty) continue;
    final match = pattern.firstMatch(address);
    if (match != null) return match.group(0);
  }
  return null;
}

String? _prospectValidityLabel(ProspectIssue issue) {
  final from = issue.validFrom;
  final until = issue.validUntil;
  if (from == null || until == null) return null;
  return _prospectDate(from) + ' – ' + _prospectDate(until);
}

const _bringBackground = Color(0xFF283A44);
const _bringSurface = Color(0xFF344953);
const _bringAccent = Color(0xFF9DE5D8);
const _bringMuted = Color(0xFFB7C5C8);
const _bringWhite = Color(0xFFF7FBFA);

ThemeData _bringTheme(BuildContext context) {
  final base = Theme.of(context);
  final scheme = ColorScheme.fromSeed(
    seedColor: _bringAccent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: _bringAccent,
    onPrimary: _bringBackground,
    secondary: _bringAccent,
    onSecondary: _bringBackground,
    surface: _bringSurface,
    onSurface: _bringWhite,
    surfaceContainerHighest: const Color(0xFF405761),
    onSurfaceVariant: _bringMuted,
  );
  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: _bringBackground,
    textTheme: base.textTheme.apply(
      bodyColor: _bringWhite,
      displayColor: _bringWhite,
    ),
    cardTheme: const CardThemeData(
      color: _bringSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: _bringSurface,
      hintStyle: const TextStyle(color: _bringMuted),
      prefixIconColor: _bringMuted,
      suffixIconColor: _bringMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _BringHeader extends StatelessWidget {
  const _BringHeader({this.location});

  final String? location;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Prospekte',
                key: ValueKey('prospect-kicker'),
                style: TextStyle(
                  color: _bringMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Angebote',
                style: TextStyle(
                  color: _bringWhite,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aktuelle Prospekte. Produkte antippen und vormerken.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _bringMuted, fontSize: 13),
              ),
            ],
          ),
          if (location != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                key: const ValueKey('prospect-location-pill'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2D35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF58727B)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: _bringWhite,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      location!,
                      style: const TextStyle(
                        color: _bringWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BringSectionTitle extends StatelessWidget {
  const _BringSectionTitle({
    required this.title,
    this.actionLabel,
    this.showFilter = false,
    this.onFilter,
  });

  final String title;
  final String? actionLabel;
  final bool showFilter;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _bringWhite,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          Text(
            actionLabel!,
            style: const TextStyle(
              color: _bringMuted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (showFilter)
          IconButton(
            key: const ValueKey('prospect-filter-button'),
            tooltip: 'Prospektfilter',
            onPressed: onFilter,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1E2D35),
              foregroundColor: _bringWhite,
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(Icons.tune, size: 20),
          ),
      ],
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
    this.now,
    this.onSaveOffer,
  });

  final ProspectIssue issue;
  final List<OfferImportRecord> records;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddProduct;
  final DateTime? now;
  final Future<List<Offer>> Function(Offer offer)? onSaveOffer;

  Future<void> _addPageOffer(BuildContext context, ProspectPage page) async {
    final saveOffer = onSaveOffer;
    final addProduct = onAddProduct;
    if (saveOffer == null || addProduct == null) return;
    final draft = await showProspectPageOfferDialog(
      context,
      initialValidUntil: issue.validUntil,
    );
    if (draft == null || !context.mounted) return;

    final record = OfferImportRecord(
      sourceId:
          'manual-page|${issue.storeName}|${page.number}|${DateTime.now().microsecondsSinceEpoch}',
      productLabel: draft.productLabel,
      storeName: issue.storeName,
      originalPrice: draft.originalPrice,
      offerPrice: draft.offerPrice,
      validFrom: issue.validFrom,
      validUntil: draft.validUntil,
      source: 'leaflet',
      proofRef: page.zoomUrl ?? page.imageUrl,
      imageUrl: page.imageUrl,
      branchId: issue.branchId,
      location: issue.location,
      address: issue.address,
    );
    final entries = prospectOfferProducts(
      records: [record],
      catalogProducts: catalogProducts,
      now: now ?? DateTime.now(),
    );
    if (entries.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Artikel konnte mit diesen Angaben nicht als aktuelles Angebot '
            'gespeichert werden.',
          ),
        ),
      );
      return;
    }
    final entry = entries.single;
    // This is a user-reviewed page claim. Give it a stable non-import ID so
    // the next automatic feed refresh cannot delete it as a transient feed
    // projection.
    final reviewedOffer = Offer(
      id:
          'manual-page|${issue.storeName}|${page.number}|${DateTime.now().microsecondsSinceEpoch}',
      productId: entry.offer.productId,
      storeName: entry.offer.storeName,
      originalPrice: entry.offer.originalPrice,
      originalPriceVerified: entry.offer.originalPriceVerified,
      offerPrice: entry.offer.offerPrice,
      validFrom: entry.offer.validFrom,
      validUntil: entry.offer.validUntil,
      source: entry.offer.source,
      proofRef: entry.offer.proofRef,
      imageUrl: entry.offer.imageUrl,
      locationId: entry.offer.locationId,
      region: entry.offer.region,
      address: entry.offer.address,
    );
    try {
      await saveOffer(reviewedOffer);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angebot konnte nicht gespeichert werden.')),
        );
      }
      return;
    }
    addProduct(entry.product);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.product.name} hinzugefügt')),
    );
  }

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
          if (_officialProspectUri(issue.url) != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(
                  _officialProspectUri(issue.url)!,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Seite ${page.number}'),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: onSaveOffer == null || onAddProduct == null
                                ? null
                                : () => _addPageOffer(context, page),
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                            label: const Text('Artikel von Seite hinzufügen'),
                          ),
                        ],
                      ),
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

Uri? _officialProspectUri(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return null;
  }
  return uri;
}

