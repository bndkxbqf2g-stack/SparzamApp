import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'prospect_page_ocr.dart';
import '../../services/prospect_favorites_store.dart';

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
    this.favoriteStore,
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
  final ProspectFavoritesStore? favoriteStore;

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectDerivedData {
  const _ProspectDerivedData({
    required this.currentRecords,
    required this.categories,
    required this.stores,
    required this.visibleProspects,
  });

  final List<OfferImportRecord> currentRecords;
  final List<String> categories;
  final List<String> stores;
  final List<ProspectIssue> visibleProspects;
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  final searchController = TextEditingController();
  var query = '';
  String? selectedCategory;
  String? selectedStore;
  var _filtersExpanded = true;
  final _bringScrollController = ScrollController();
  final _moreProspectsKey = GlobalKey();
  Set<String>? _favoriteStores;
  late final ProspectFavoritesStore _favoriteStore;
  // Feed normalization and visible-card selection are independent from the
  // search query and favorite state. Reuse them while those controls change.
  List<OfferImportRecord>? _derivedRecordsInput;
  List<ProspectIssue>? _derivedProspectsInput;
  DateTime? _derivedNow;
  _ProspectDerivedData? _derivedData;

  @override
  void initState() {
    super.initState();
    _favoriteStore = widget.favoriteStore ?? ProspectFavoritesStore();
    _loadFavoriteStores();
  }

  Future<void> _loadFavoriteStores() async {
    final loaded = await _favoriteStore.load();
    if (!mounted) return;
    setState(() => _favoriteStores = loaded);
  }

  Future<void> _toggleFavorite(String storeName) async {
    final previous = _favoriteStores;
    final next = {...(_favoriteStores ?? const <String>{})};
    if (!next.add(storeName)) next.remove(storeName);
    setState(() => _favoriteStores = next);
    try {
      await _favoriteStore.save(next);
    } catch (_) {
      if (!mounted) return;
      setState(() => _favoriteStores = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorit konnte nicht gespeichert werden.')),
      );
    }
  }

  bool _isFavorite(ProspectIssue issue) =>
      (_favoriteStores ?? const <String>{}).contains(issue.storeName);

  void _scrollToMoreProspects() {
    final target = _moreProspectsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  _ProspectDerivedData _prospectViewData() {
    final cached = _derivedData;
    if (cached != null &&
        identical(_derivedRecordsInput, widget.records) &&
        identical(_derivedProspectsInput, widget.prospects) &&
        _derivedNow == widget.now) {
      return cached;
    }

    final currentRecords = currentProspectRecords(
      widget.records,
      now: widget.now,
    );
    final currentCounts = <String, int>{};
    final currentRegionalCounts = <String, int>{};
    for (final record in currentRecords) {
      currentCounts.update(
        record.storeName,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (record.regionalOnly) {
        currentRegionalCounts.update(
          record.storeName,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
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
          currentRegionalRecordCount:
              currentRegionalCounts[entries.first.storeName] ?? 0,
          now: widget.now,
        ),
    ];
    final next = _ProspectDerivedData(
      currentRecords: currentRecords,
      categories: _prospectCategories(currentRecords),
      stores: _prospectStores(currentRecords, widget.prospects),
      visibleProspects: visibleProspects,
    );
    _derivedRecordsInput = widget.records;
    _derivedProspectsInput = widget.prospects;
    _derivedNow = widget.now;
    _derivedData = next;
    return next;
  }

  @override
  void dispose() {
    searchController.dispose();
    _bringScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final derived = _prospectViewData();
    final currentRecords = derived.currentRecords;
    final categories = derived.categories;
    final stores = derived.stores;
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
    final visibleProspects = derived.visibleProspects;
    final hasSelection = query.trim().isNotEmpty ||
        activeCategory != null ||
        activeStore != null;
    final favoriteProspects = _favoriteStores == null
        ? visibleProspects.take(2).toList(growable: false)
        : visibleProspects
              .where((issue) => _favoriteStores!.contains(issue.storeName))
              .toList(growable: false);

    return Theme(
      data: _bringTheme(context),
      child: ColoredBox(
        key: const ValueKey('prospect-grid'),
        color: _bringBackground,
        child: CustomScrollView(
          controller: _bringScrollController,
          scrollCacheExtent: const ScrollCacheExtent.pixels(0),
          key: const ValueKey('prospect-bring-scroll'),
          slivers: [
            if (hasSelection)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: _ProspectSearchResultsSliver(
                  records: matchingRecords,
                  prospects: visibleProspects,
                  catalogProducts: widget.catalogProducts,
                  onAddProduct: widget.onAddProduct,
                  query: query,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                  if (!hasSelection &&
                      _filtersExpanded &&
                      categories.isNotEmpty) ...[
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
                  if (!hasSelection && _filtersExpanded && stores.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Material(
                      type: MaterialType.transparency,
                      child: _ProspectStoreChips(
                        stores: stores,
                        selectedStore: activeStore,
                        onSelected: (store) =>
                            setState(() => selectedStore = store),
                      ),
                    ),
                  ],
                  if (!hasSelection)
                    ProspectFeedStatusCard(
                      generatedAt: widget.generatedAt,
                      now: widget.now,
                      fromCache: widget.fromCache,
                      regularPriceCount: currentRecords
                          .where(hasLearnableProspectRegularPrice)
                          .length,
                      onRefresh: widget.onRefreshProspects,
                      refreshing: widget.prospectsRefreshing,
                    ),
                  const SizedBox(height: 18),
                  if (!hasSelection && visibleProspects.isEmpty)
                    const Card(
                      color: _bringSurface,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Noch keine Prospekte geladen.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (!hasSelection && visibleProspects.isNotEmpty) ...[
                    _BringSectionTitle(
                      title: 'Deine Favoriten',
                      actionLabel: 'Mehr ›',
                      onAction: _scrollToMoreProspects,
                    ),
                    const SizedBox(height: 10),
                    if (_favoriteStores != null && favoriteProspects.isEmpty)
                      const _EmptyFavoritesCard()
                    else
                      SizedBox(
                        height: 340,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: favoriteProspects.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final issue = favoriteProspects[index];
                            return _ProspectCard(
                              key: ValueKey(
                                'prospect-card-favorite-${issue.storeName}',
                              ),
                              issue: issue,
                              compact: false,
                              showLocation: true,
                              showSummary: true,
                              isFavorite: _isFavorite(issue),
                              onToggleFavorite: () =>
                                  _toggleFavorite(issue.storeName),
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
                      key: _moreProspectsKey,
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
                  ],
                ]),
              ),
            ),
            if (!hasSelection && visibleProspects.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final issue = visibleProspects[index];
                      return _ProspectCard(
                        key: ValueKey(
                          'prospect-card-grid-${issue.storeName}',
                        ),
                        issue: issue,
                        compact: true,
                        showLocation: false,
                        showSummary: true,
                        isFavorite: _isFavorite(issue),
                        onToggleFavorite: () =>
                            _toggleFavorite(issue.storeName),
                        onTap: () => _openProspect(
                          context,
                          issue,
                          currentRecords,
                        ),
                      );
                    },
                    childCount: visibleProspects.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.sizeOf(context).width >= 650
                        ? 3
                        : 2,
                    mainAxisExtent: 300,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                ),
              ),
            if (query.trim().isEmpty && visibleProspects.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: ProspectCoverageCard(
                    coverage: calculateProspectCoverage(
                      issues: visibleProspects,
                      records: currentRecords,
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
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
        builder: (_) => ProspectViewerScreen(
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

class _ProspectSearchResultsSliver extends StatelessWidget {
  const _ProspectSearchResultsSliver({
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
      return SliverToBoxAdapter(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              trimmedQuery.isEmpty
                  ? 'Keine aktuellen Prospektartikel für diese Auswahl gefunden.'
                  : 'Keine aktuellen Prospektartikel für „$trimmedQuery“ gefunden.',
              textAlign: TextAlign.center,
            ),
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

    // Keep product identity resolution out of repeated sliver child builds. The
    // map lives for the lifetime of this delegate build, so fast scrolling can
    // reuse both positive and negative matches without changing the identity
    // rules used by addableProductForProspectOffer.
    final resolvedProducts = <String, Product?>{};

    final rows = <_ProspectSearchRow>[
      _ProspectSearchRow.heading('${records.length} passende Prospektartikel'),
      const _ProspectSearchRow.description(
        'Artikel werden nur mit ihrem vorhandenen Händlernachweis und '
        'aktuellen Gültigkeitszeitraum angeboten.',
      ),
    ];
    for (final entry in byStore.entries) {
      final location = entry.value.every(
                (record) => record.location?.trim().isEmpty ?? true,
              )
              ? issueByStore[entry.key]?.location?.trim()
              : null;
      rows.add(_ProspectSearchRow.store(entry.key, location: location));
      rows.addAll(
        entry.value.map((record) => _ProspectSearchRow.offer(record)),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final row = rows[index];
          return switch (row.kind) {
            _ProspectSearchRowKind.heading => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  row.text!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            _ProspectSearchRowKind.description => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Artikel werden nur mit ihrem vorhandenen Händlernachweis und '
                  'aktuellen Gültigkeitszeitraum angeboten.',
                ),
              ),
            _ProspectSearchRowKind.store => Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.text!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (row.location != null && row.location!.isNotEmpty)
                      Text(
                        row.location!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            _ProspectSearchRowKind.offer => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildOffer(
                context,
                row.record!,
                resolvedProducts,
              ),
              ),
          };
        },
        childCount: rows.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
      ),
    );
  }

  Widget _buildOffer(
    BuildContext context,
    OfferImportRecord record,
    Map<String, Product?> resolvedProducts,
  ) {
    final product = _memoizedProspectProduct(
      record,
      catalogProducts,
      resolvedProducts,
    );
    return ProspectOfferCard(
      key: ValueKey('prospect-search-offer-${prospectOfferRecordKey(record)}'),
      record: record,
      product: product,
      compact: true,
      onAdd: onAddProduct == null || product == null
          ? null
          : () {
              onAddProduct!(product);
            },
    );
  }
}

enum _ProspectSearchRowKind { heading, description, store, offer }

Product? _memoizedProspectProduct(
  OfferImportRecord record,
  Iterable<Product> catalogProducts,
  Map<String, Product?> cache,
) {
  final sourceId = record.sourceId.trim();
  final key = sourceId.isEmpty
      ? '${record.storeName}|${record.productLabel}|${record.offerPrice}|${record.validUntil.toIso8601String()}'
      : sourceId;
  if (cache.containsKey(key)) return cache[key];
  final product = addableProductForProspectOffer(record, catalogProducts);
  cache[key] = product;
  return product;
}

class _ProspectSearchRow {
  const _ProspectSearchRow.heading(this.text)
      : kind = _ProspectSearchRowKind.heading,
        location = null,
        record = null;

  const _ProspectSearchRow.description(this.text)
      : kind = _ProspectSearchRowKind.description,
        location = null,
        record = null;

  const _ProspectSearchRow.store(this.text, {this.location})
      : kind = _ProspectSearchRowKind.store,
        record = null;

  const _ProspectSearchRow.offer(this.record)
      : kind = _ProspectSearchRowKind.offer,
        text = null,
        location = null;

  final _ProspectSearchRowKind kind;
  final String? text;
  final String? location;
  final OfferImportRecord? record;
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
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('Alle Märkte'),
              selected: selectedStore == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final store = stores[index - 1];
          return ChoiceChip(
            label: Text(store),
            selected: selectedStore == store,
            onSelected: (_) => onSelected(store),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }
}

ProspectIssue _visibleIssue(
  List<ProspectIssue> entries,
  int currentRecordCount, {
  int currentRegionalRecordCount = 0,
  DateTime? now,
}) {
  final currentEntries = entries
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
      .toList(growable: false);
  final current = currentEntries.isEmpty
      ? null
      : _bestVisibleProspect(currentEntries);
  final selected = current ?? _bestVisibleProspect(entries);

  // A stale issue may still carry a perfectly valid-looking cover image.
  // Never expose that image as the current prospect once its period ended:
  // the card remains useful as a source/status entry, while the old pages
  // are removed from the visible evidence path.
  final String sourceStatus;
  if (currentRecordCount > 0 &&
      currentRegionalRecordCount == currentRecordCount &&
      selected.sourceStatus != 'error') {
    sourceStatus = 'regional_only';
  } else if (currentRecordCount == 0 &&
      selected.sourceStatus != 'error' &&
      selected.sourceStatus != 'regional_only') {
    // A current metadata-only prospect is still a valid source card, but
    // it has no structured items to display as current offers.
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

ProspectIssue _bestVisibleProspect(Iterable<ProspectIssue> entries) {
  final sorted = entries.toList(growable: false)
    ..sort(_compareVisibleProspects);
  return sorted.first;
}

int _compareVisibleProspects(ProspectIssue a, ProspectIssue b) {
  final status = _prospectStatusRank(b.sourceStatus).compareTo(
    _prospectStatusRank(a.sourceStatus),
  );
  if (status != 0) return status;

  final pages = b.pages.length.compareTo(a.pages.length);
  if (pages != 0) return pages;

  final aHasThumbnail = a.thumbnailUrl?.trim().isNotEmpty == true;
  final bHasThumbnail = b.thumbnailUrl?.trim().isNotEmpty == true;
  final thumbnails = (bHasThumbnail ? 1 : 0).compareTo(
    aHasThumbnail ? 1 : 0,
  );
  if (thumbnails != 0) return thumbnails;

  final records = b.recordCount.compareTo(a.recordCount);
  if (records != 0) return records;

  final endDates = (b.validUntil ?? DateTime.fromMillisecondsSinceEpoch(0))
      .compareTo(a.validUntil ?? DateTime.fromMillisecondsSinceEpoch(0));
  if (endDates != 0) return endDates;

  final urls = (a.url ?? '').compareTo(b.url ?? '');
  if (urls != 0) return urls;
  return a.title.compareTo(b.title);
}

int _prospectStatusRank(String status) => switch (status) {
  'ok' => 4,
  'metadata_only' => 3,
  'current_fallback' => 2,
  'regional_only' => 1,
  _ => 0,
};

class _ProspectCard extends StatelessWidget {
  const _ProspectCard({
    super.key,
    required this.issue,
    required this.onTap,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.compact = false,
    this.showLocation = true,
    this.showSummary = true,
  });

  final ProspectIssue issue;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final bool compact;
  final bool showLocation;
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    // Cards are visible in both the horizontal favorites rail and the grid.
    // Prefer the source thumbnail there; full page images stay available in
    // the viewer and should not all be decoded while the overview scrolls.
    final thumbnail = _officialProspectUri(issue.thumbnailUrl)?.toString();
    String? previewUrl;
    if (thumbnail != null && thumbnail.isNotEmpty) {
      previewUrl = thumbnail;
    } else if (issue.pages.isNotEmpty) {
      previewUrl = _officialProspectUri(issue.pages.first.imageUrl)?.toString();
    }
    final imageHeight = compact ? 168.0 : 181.0;
    final validity = _prospectValidityLabel(issue);
    final cover = previewUrl == null || previewUrl.isEmpty
        ? _bringCoverPlaceholder()
        : Image.network(
            previewUrl,
            key: ValueKey(
              'prospect-cover-image-${compact ? "grid" : "favorite"}-${issue.storeName}',
            ),
            // Keep the overview cheap: a platform view for every cover makes
            // the horizontal rail and grid jank on Flutter web.
            cacheWidth: compact ? 480 : 640,
            cacheHeight: compact ? 400 : 480,
            filterQuality: FilterQuality.low,
            // Overview covers stay on the Canvas renderer. A browser
            // platform view for every retailer CDN image can make fast
            // vertical and horizontal scrolling unstable on Flutter web.
            // The full viewer keeps its explicit fallback boundary.
            webHtmlElementStrategy: WebHtmlElementStrategy.never,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _bringCoverPlaceholder(),
          );

    return RepaintBoundary(
      child: SizedBox(
        width: compact ? double.infinity : 214,
        child: Card(
          color: _bringSurface,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Stack(
          children: [
            InkWell(
              key: ValueKey(
                'prospect-open-${compact ? 'grid' : 'favorite'}-${issue.storeName}',
              ),
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: imageHeight,
                    child: compact
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              cover,
                              Positioned(
                                top: 8,
                                left: 8,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      issue.storeName,
                                      style: const TextStyle(
                                        color: Color(0xFF27343A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : cover,
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
                        if (!compact)
                          SizedBox(
                            height: 36,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 40),
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
                            ),
                          )
                        else
                          const SizedBox(height: 32),
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
            Positioned(
              top: imageHeight + 10,
              right: compact ? 10 : 12,
              child: _ProspectFavoriteButton(
                storeName: issue.storeName,
                isFavorite: isFavorite,
                onPressed: onToggleFavorite,
                compact: compact,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _ProspectFavoriteButton extends StatelessWidget {
  const _ProspectFavoriteButton({
    required this.storeName,
    required this.isFavorite,
    required this.onPressed,
    required this.compact,
  });

  final String storeName;
  final bool isFavorite;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final action = isFavorite
        ? '$storeName aus Favoriten entfernen'
        : '$storeName zu Favoriten hinzufügen';
    return IconButton(
      key: ValueKey('prospect-favorite-$storeName'),
      tooltip: action,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: compact ? 32 : 36,
        height: compact ? 32 : 36,
      ),