import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../offers/offer_import.dart';
import '../offers/prospect_offer_products.dart';
import '../offers/prospect_regular_price_persistence.dart';
import 'prospect_category_presentation.dart';
import 'prospect_cover_section.dart';
import 'prospect_issue_identity.dart';
import '../../services/branch_identity.dart';
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
    this.regularPriceCount,
    this.regularPricePersistenceStatus =
        ProspectRegularPricePersistenceStatus.standalone,
    this.persistedRegularPriceCounts,
    this.onSaveOffer,
    this.onSaveProspectRegularPrice,
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
  /// Count confirmed by the shell's local price-observation persistence.
  /// Null keeps standalone screens on their feed-derived fallback.
  final int? regularPriceCount;
  final ProspectRegularPricePersistenceStatus regularPricePersistenceStatus;
  /// Per-store counts confirmed by the local price-observation persistence.
  /// Null keeps standalone coverage on an explicitly unknown status.
  final Map<String, int>? persistedRegularPriceCounts;
  final Future<List<Offer>> Function(Offer offer)? onSaveOffer;
  final Future<void> Function(PriceObservation observation)?
      onSaveProspectRegularPrice;
  final ProspectFavoritesStore? favoriteStore;

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectDerivedData {
  const _ProspectDerivedData({
    required this.currentRecords,
    required this.regularPriceCount,
    required this.categories,
    required this.stores,
    required this.visibleProspects,
    required this.coverage,
  });

  final List<OfferImportRecord> currentRecords;
  final int regularPriceCount;
  final List<String> categories;
  final List<String> stores;
  final List<ProspectIssue> visibleProspects;
  final List<ProspectCoverage> coverage;
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  final searchController = TextEditingController();
  var query = '';
  String? selectedCategory;
  String? selectedStore;
  var _filtersExpanded = true;
  static const _prospectGridPageSize = 12;
  // Large feeds should not decode a speculative extra cover row while
  // the user scrolls; small feeds keep the short lead-in for responsiveness.
  static const _prospectHeavyFeedThreshold = _prospectGridPageSize * 2;
  var _visibleProspectCount = _prospectGridPageSize;
  final _bringScrollController = ScrollController();
  final _moreProspectsKey = GlobalKey();
  Set<String>? _favoriteStores;
  var _favoriteIndex = const ProspectFavoriteIndex.empty();
  late final ProspectFavoritesStore _favoriteStore;
  // Feed normalization and visible-card selection are independent from the
  // search query and favorite state. Reuse them while those controls change.
  List<OfferImportRecord>? _derivedRecordsInput;
  List<ProspectIssue>? _derivedProspectsInput;
  DateTime? _derivedDay;
  List<Product>? _derivedCatalogInput;
  Map<String, int>? _derivedPersistedCountsInput;
  _ProspectDerivedData? _derivedData;
  List<OfferImportRecord>? _searchIndexInput;
  Map<OfferImportRecord, String>? _searchIndexCache;

  Map<OfferImportRecord, String> _searchIndexFor(
    List<OfferImportRecord> records,
  ) {
    if (identical(_searchIndexInput, records)) {
      return _searchIndexCache ?? const <OfferImportRecord, String>{};
    }
    final index = <OfferImportRecord, String>{};
    for (final record in records) {
      index[record] = _prospectSearchText(record);
    }
    _searchIndexInput = records;
    _searchIndexCache = index;
    return index;
  }

  @override
  void initState() {
    super.initState();
    _favoriteStore = widget.favoriteStore ?? ProspectFavoritesStore();
    _loadFavoriteStores();
  }

  Future<void> _loadFavoriteStores() async {
    final loaded = await _favoriteStore.load();
    if (!mounted) return;
    setState(() {
      _favoriteStores = loaded;
      _favoriteIndex = ProspectFavoriteIndex.from(loaded ?? const <String>[]);
    });
  }

  Future<void> _toggleFavorite(ProspectIssue issue) async {
    final previous = _favoriteStores;
    final next = {...(_favoriteStores ?? const <String>{})};
    final exactKey = prospectFavoriteKey(issue);
    final legacyKey = issue.storeName.trim();
    if (next.contains(exactKey)) {
      next.remove(exactKey);
    } else if (exactKey != legacyKey && next.contains(legacyKey)) {
      // A legacy store-wide favorite is treated as the active branch's
      // favorite once. Removing it preserves the old user's intent without
      // silently favoriting every same-name branch forever.
      next.remove(legacyKey);
    } else {
      next.add(exactKey);
    }
    setState(() {
      _favoriteStores = next;
      _favoriteIndex = ProspectFavoriteIndex.from(next);
    });
    try {
      await _favoriteStore.save(next);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favoriteStores = previous;
        _favoriteIndex =
            ProspectFavoriteIndex.from(previous ?? const <String>[]);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorit konnte nicht gespeichert werden.')),
      );
    }
  }

  bool _isFavorite(ProspectIssue issue) => _favoriteIndex.matches(issue);

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
    final day = offerFilterDay(widget.now);
    final cached = _derivedData;
    if (cached != null &&
        identical(_derivedRecordsInput, widget.records) &&
        identical(_derivedProspectsInput, widget.prospects) &&
        identical(_derivedCatalogInput, widget.catalogProducts) &&
        identical(
          _derivedPersistedCountsInput,
          widget.persistedRegularPriceCounts,
        ) &&
        _derivedDay == day) {
      return cached;
    }

    final currentRecords = currentFoodProspectRecords(
      widget.records,
      now: widget.now,
    );
    final currentCounts = <String, int>{};
    final currentRegionalCounts = <String, int>{};
    final currentStoreCounts = <String, int>{};
    final currentRegionalStoreCounts = <String, int>{};
    final currentUnscopedStoreCounts = <String, int>{};
    final currentUnscopedRegionalStoreCounts = <String, int>{};
    var regularPriceCount = 0;
    for (final record in currentRecords) {
      if (hasLearnableProspectRegularPrice(record)) {
        regularPriceCount++;
      }
      currentCounts.update(
        prospectRecordMatchKey(record),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      currentStoreCounts.update(
        prospectStoreMatchKey(record.storeName),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final recordBranch = record.branchId?.trim();
      if (recordBranch == null || recordBranch.isEmpty) {
        currentUnscopedStoreCounts.update(
          prospectStoreMatchKey(record.storeName),
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      if (record.regionalOnly) {
        currentRegionalCounts.update(
          prospectRecordMatchKey(record),
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        currentRegionalStoreCounts.update(
          prospectStoreMatchKey(record.storeName),
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (recordBranch == null || recordBranch.isEmpty) {
          currentUnscopedRegionalStoreCounts.update(
            prospectStoreMatchKey(record.storeName),
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }
    final byIssue = <String, List<ProspectIssue>>{};
    for (final issue in widget.prospects) {
      byIssue.putIfAbsent(prospectIssueMatchKey(issue), () => []).add(issue);
    }
    final visibleProspects = <ProspectIssue>[];
    for (final entries in byIssue.values) {
      final issue = entries.first;
      final hasBranch = issue.branchId?.trim().isNotEmpty == true;
      final issueKey = prospectIssueMatchKey(issue);
      final recordCount = hasBranch
          ? (currentCounts[issueKey] ?? 0) +
              (currentUnscopedStoreCounts[prospectStoreMatchKey(issue.storeName)] ?? 0)
          : currentStoreCounts[prospectStoreMatchKey(issue.storeName)] ?? 0;
      final regionalRecordCount = hasBranch
          ? (currentRegionalCounts[issueKey] ?? 0) +
              (currentUnscopedRegionalStoreCounts[prospectStoreMatchKey(issue.storeName)] ?? 0)
          : currentRegionalStoreCounts[prospectStoreMatchKey(issue.storeName)] ?? 0;
      visibleProspects.add(
        _visibleIssue(
          entries,
          recordCount,
          currentRegionalRecordCount: regionalRecordCount,
          now: widget.now,
        ),
      );
    }
    final coverage = calculateProspectCoverage(
      issues: visibleProspects,
      records: currentRecords,
      now: widget.now,
      catalogProducts: widget.catalogProducts,
      persistedRegularPriceCounts: widget.persistedRegularPriceCounts,
    );
    final next = _ProspectDerivedData(
      currentRecords: currentRecords,
      regularPriceCount: regularPriceCount,
      categories: _prospectCategories(currentRecords),
      stores: _prospectStores(currentRecords, widget.prospects),
      visibleProspects: visibleProspects,
      coverage: coverage,
    );
    _derivedRecordsInput = widget.records;
    _derivedProspectsInput = widget.prospects;
    _derivedCatalogInput = widget.catalogProducts;
    _derivedPersistedCountsInput = widget.persistedRegularPriceCounts;
    _derivedDay = day;
    _derivedData = next;
    return next;
  }

  @override
  void didUpdateWidget(covariant ProspectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.records, widget.records) ||
        !identical(oldWidget.prospects, widget.prospects)) {
      _visibleProspectCount = _prospectGridPageSize;
    }
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
      searchIndex: _searchIndexFor(currentRecords),
    );
    final visibleProspects = derived.visibleProspects;
    final hasSelection = query.trim().isNotEmpty ||
        activeCategory != null ||
        activeStore != null;
    final favoriteProspects = _favoriteStores == null
        ? visibleProspects.take(2).toList(growable: false)
        : visibleProspects
              .where(_isFavorite)
              .toList(growable: false);
    final visibleProspectCount =
        _visibleProspectCount.clamp(0, visibleProspects.length).toInt();

    return Theme(
      data: _bringTheme(context),
      child: ColoredBox(
        key: const ValueKey('prospect-grid'),
        color: _bringBackground,
        child: CustomScrollView(
          controller: _bringScrollController,
          // Warm a short cover lead-in for small feeds. Once the current
          // feed reaches two visible grid pages, avoid speculative image
          // decodes so long prospect lists stay responsive while scrolling.
          scrollCacheExtent: ScrollCacheExtent.pixels(
            visibleProspects.length >= _prospectHeavyFeedThreshold ? 0 : 180,
          ),
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
                        onSelected: (category) => setState(() {
                          selectedCategory = category;
                          _visibleProspectCount = _prospectGridPageSize;
                        }),
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
                        onSelected: (store) => setState(() {
                          selectedStore = store;
                          _visibleProspectCount = _prospectGridPageSize;
                        }),
                      ),
                    ),
                  ],
                  if (!hasSelection)
                    ProspectFeedStatusCard(
                      generatedAt: widget.generatedAt,
                      now: widget.now,
                      fromCache: widget.fromCache,
                      regularPriceCount: widget.regularPriceCount ?? derived.regularPriceCount,
                      regularPricePersistenceStatus:
                          widget.regularPricePersistenceStatus,
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
                          key: const ValueKey('prospect-favorite-rail'),
                          scrollDirection: Axis.horizontal,
                          // The rail is a bounded preview, so offscreen cover
                          // cards must not stay alive or warm another image row
                          // while the parent prospect feed is moving.
                          scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: true,
                          itemCount: favoriteProspects.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final issue = favoriteProspects[index];
                            return _ProspectCard(
                              key: ValueKey(
                                'prospect-card-favorite-${prospectIssueKey(issue)}',
                              ),
                              issue: issue,
                              compact: false,
                              showLocation: true,
                              showSummary: true,
                              isFavorite: _isFavorite(issue),
                              onToggleFavorite: () =>
                                  _toggleFavorite(issue),
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
                          'prospect-card-grid-${prospectIssueKey(issue)}',
                        ),
                        issue: issue,
                        compact: true,
                        showLocation: false,
                        showSummary: true,
                        isFavorite: _isFavorite(issue),
                        onToggleFavorite: () =>
                            _toggleFavorite(issue),
                        onTap: () => _openProspect(
                          context,
                          issue,
                          currentRecords,
                        ),
                      );
                    },
                    childCount: visibleProspectCount,
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
            if (!hasSelection &&
                visibleProspects.isNotEmpty &&
                visibleProspectCount < visibleProspects.length)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const ValueKey('prospect-grid-load-more'),
                      onPressed: () => setState(() {
                        _visibleProspectCount = (_visibleProspectCount +
                                _prospectGridPageSize)
                            .clamp(0, visibleProspects.length)
                            .toInt();
                      }),
                      icon: const Icon(Icons.expand_more),
                      label: Text(
                        'Weitere Prospekte laden '
                        '(${visibleProspects.length - visibleProspectCount})',
                      ),
                    ),
                  ),
                ),
              ),
            if (query.trim().isEmpty && visibleProspects.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: ProspectCoverageCard(
                    coverage: derived.coverage,
                    regularPricePersistenceStatus:
                        widget.regularPricePersistenceStatus,
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
          onSaveProspectRegularPrice: widget.onSaveProspectRegularPrice,
        ),
      ),
    );
  }
}

class _ProspectSearchResultsSliver extends StatefulWidget {
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
  State<_ProspectSearchResultsSliver> createState() =>
      _ProspectSearchResultsSliverState();
}

class _ProspectSearchResultsSliverState
    extends State<_ProspectSearchResultsSliver> {
  static const _searchPageSize = 40;
  var _visibleCount = _searchPageSize;

  // Search/filter rebuilds can replace the list instance while retaining the
  // same immutable record objects. Keep identity resolution and collision-safe
  // widget keys tied to the record contents instead of the current build.
  final _resolvedProducts = <String, Product?>{};
  List<Product>? _resolvedProductsCatalogInput;
  OfferImportCatalogIndex? _catalogIndex;
  List<OfferImportRecord>? _widgetKeyInput;
  Map<OfferImportRecord, String>? _widgetKeyCache;

  bool _sameRecords(
    List<OfferImportRecord>? previous,
    List<OfferImportRecord> current,
  ) {
    if (previous == null || previous.length != current.length) return false;
    for (var index = 0; index < current.length; index++) {
      if (!identical(previous[index], current[index])) return false;
    }
    return true;
  }

  Map<OfferImportRecord, String> _widgetKeysFor(
    List<OfferImportRecord> records,
  ) {
    if (_sameRecords(_widgetKeyInput, records)) {
      return _widgetKeyCache ?? const <OfferImportRecord, String>{};
    }
    final keys = prospectOfferWidgetKeys(records);
    final indexed = <OfferImportRecord, String>{};
    for (var index = 0; index < records.length; index++) {
      indexed[records[index]] = keys[index];
    }
    _widgetKeyInput = List<OfferImportRecord>.unmodifiable(records);
    _widgetKeyCache = Map<OfferImportRecord, String>.unmodifiable(indexed);
    return _widgetKeyCache!;
  }

  void _prepareProductCache() {
    if (identical(_resolvedProductsCatalogInput, catalogProducts)) return;
    _resolvedProducts.clear();
    _resolvedProductsCatalogInput = catalogProducts;
    _catalogIndex = OfferImportCatalogIndex(catalogProducts);
  }

  List<OfferImportRecord> get records => widget.records;
  List<ProspectIssue> get prospects => widget.prospects;
  List<Product> get catalogProducts => widget.catalogProducts;
  ValueChanged<Product>? get onAddProduct => widget.onAddProduct;
  String get query => widget.query;

  @override
  void didUpdateWidget(covariant _ProspectSearchResultsSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.catalogProducts, widget.catalogProducts)) {
      _resolvedProducts.clear();
      _resolvedProductsCatalogInput = widget.catalogProducts;
      _catalogIndex = OfferImportCatalogIndex(widget.catalogProducts);
    }
    final oldFirst = oldWidget.records.isEmpty
        ? null
        : prospectOfferRecordKey(oldWidget.records.first);
    final newFirst = widget.records.isEmpty
        ? null
        : prospectOfferRecordKey(widget.records.first);
    final oldLast = oldWidget.records.isEmpty
        ? null
        : prospectOfferRecordKey(oldWidget.records.last);
    final newLast = widget.records.isEmpty
        ? null
        : prospectOfferRecordKey(widget.records.last);
    if (oldWidget.query != widget.query ||
        oldWidget.records.length != widget.records.length ||
        oldWidget.prospects.length != widget.prospects.length ||
        oldFirst != newFirst ||
        oldLast != newLast) {
      _visibleCount = _searchPageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    _prepareProductCache();
    final issuesByStore = <String, List<ProspectIssue>>{};
    for (final issue in prospects) {
      issuesByStore.putIfAbsent(prospectStoreMatchKey(issue.storeName), () => []).add(issue);
    }

    // A store can have multiple branch-specific records in the shared feed.
    // Match against every issue for that store so one branch cannot hide
    // another branch with the same visible retailer name.
    final matchingRecords = records
        .where((record) {
          final candidates = issuesByStore[prospectStoreMatchKey(record.storeName)];
          if (candidates == null || candidates.isEmpty) return true;
          return candidates.any(
            (issue) => _prospectRecordBelongsToIssue(record, issue),
          );
        })
        .toList(growable: false);
    if (matchingRecords.isEmpty) {
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

    final widgetKeysByRecord = _widgetKeysFor(records);

    final visibleCount =
        _visibleCount.clamp(0, matchingRecords.length).toInt();
    final visibleRecords = matchingRecords
        .take(visibleCount)
        .toList(growable: false);
    final byStore = <String, List<OfferImportRecord>>{};
    for (final record in visibleRecords) {
      // Use the exact store/branch key for grouping. The row still displays
      // the human-readable retailer name, while two same-name branches keep
      // independent locations and product lists.
      byStore.putIfAbsent(prospectRecordMatchKey(record), () => []).add(record);
    }

    // Product identity resolution is cached on the sliver state. Fast
    // scrolling and pagination can therefore reuse positive and negative
    // matches without scanning the catalog for every rebuilt child.
    final resolvedProducts = _resolvedProducts;

    final rows = <_ProspectSearchRow>[
      _ProspectSearchRow.heading(
        '${matchingRecords.length} passende Prospektartikel',
      ),
      const _ProspectSearchRow.description(
        'Artikel werden nur mit ihrem vorhandenen Händlernachweis und '
        'aktuellen Gültigkeitszeitraum angeboten.',
      ),
    ];
    for (final entry in byStore.entries) {
      final location = entry.value.every(
                (record) => record.location?.trim().isEmpty ?? true,
              )
              ? _prospectSearchLocation(entry.value, issuesByStore)
              : null;
      rows.add(
        _ProspectSearchRow.store(
          entry.value.first.storeName,
          location: location,
        ),
      );
      rows.addAll(
        entry.value.map((record) => _ProspectSearchRow.offer(record)),
      );
    }
    if (visibleCount < matchingRecords.length) {
      rows.add(
        _ProspectSearchRow.loadMore(
          remaining: matchingRecords.length - visibleCount,
          onPressed: () => setState(() {
            _visibleCount = (_visibleCount + _searchPageSize)
                .clamp(0, matchingRecords.length)
                .toInt();
          }),
        ),
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
                  widgetKeysByRecord,
                ),
              ),
            _ProspectSearchRowKind.loadMore => Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const ValueKey('prospect-search-load-more'),
                    onPressed: row.onPressed,
                    icon: const Icon(Icons.expand_more),
                    label: Text(
                      'Weitere Artikel laden (${row.remaining})',
                    ),
                  ),
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
    Map<OfferImportRecord, String> widgetKeysByRecord,
  ) {
    final product = _memoizedProspectProduct(
      record,
      catalogProducts,
      resolvedProducts,
      catalogIndex: _catalogIndex,
    );
    final manualProduct =
        product == null ? manualProductForProspectOffer(record) : null;
    final regionalProduct = record.regionalOnly
        ? listOnlyProductForRegionalProspectOffer(
            record,
            catalogProducts,
            catalogIndex: _catalogIndex,
          )
        : null;
    final selectableProduct =
        record.regionalOnly ? regionalProduct : product ?? manualProduct;
    final listOnlyWithoutBranch =
        record.regionalOnly && selectableProduct != null;
    final canAdd = onAddProduct != null && selectableProduct != null;
    final recordKey =
        widgetKeysByRecord[record] ?? prospectOfferRecordKey(record);
    return ProspectOfferCard(
      key: ValueKey('prospect-search-offer-$recordKey'),
      record: record,
      product: selectableProduct,
      compact: true,
      requiresManualConfirmation:
          listOnlyWithoutBranch || (product == null && manualProduct != null),
      listOnlyWithoutBranch: listOnlyWithoutBranch,
      onAdd: !canAdd ? null : () => onAddProduct!(selectableProduct),
    );
  }
}

ProspectIssue? _prospectSearchIssueForRecord(
  OfferImportRecord record,
  Map<String, List<ProspectIssue>> issuesByStore,
) {
  final candidates = issuesByStore[prospectStoreMatchKey(record.storeName)];
  if (candidates == null || candidates.isEmpty) return null;
  final recordKey = prospectRecordMatchKey(record);
  for (final issue in candidates) {
    if (prospectIssueMatchKey(issue) == recordKey) return issue;
  }
  final matching = candidates
      .where((issue) => _prospectRecordBelongsToIssue(record, issue))
      .toList(growable: false);
  return matching.length == 1 ? matching.single : null;
}

String? _prospectSearchLocation(
  List<OfferImportRecord> records,
  Map<String, List<ProspectIssue>> issuesByStore,
) {
  final issues = <ProspectIssue>{};
  for (final record in records) {
    final issue = _prospectSearchIssueForRecord(record, issuesByStore);
    if (issue != null) issues.add(issue);
  }
  if (issues.length != 1) return null;
  return issues.single.location?.trim();
}

enum _ProspectSearchRowKind { heading, description, store, offer, loadMore }

Product? _memoizedProspectProduct(
  OfferImportRecord record,
  Iterable<Product> catalogProducts,
  Map<String, Product?> cache, {
  OfferImportCatalogIndex? catalogIndex,
}) {
  final key = prospectOfferResolutionKey(record);
  if (cache.containsKey(key)) return cache[key];
  final product = addableProductForProspectOffer(
    record,
    catalogProducts,
    catalogIndex: catalogIndex,
  );
  cache[key] = product;
  return product;
}

class _ProspectSearchRow {
  const _ProspectSearchRow.heading(this.text)
      : kind = _ProspectSearchRowKind.heading,
        location = null,
        record = null,
        remaining = null,
        onPressed = null;

  const _ProspectSearchRow.description(this.text)
      : kind = _ProspectSearchRowKind.description,
        location = null,
        record = null,
        remaining = null,
        onPressed = null;

  const _ProspectSearchRow.store(this.text, {this.location})
      : kind = _ProspectSearchRowKind.store,
        record = null,
        remaining = null,
        onPressed = null;

  const _ProspectSearchRow.offer(this.record)
      : kind = _ProspectSearchRowKind.offer,
        text = null,
        location = null,
        remaining = null,
        onPressed = null;

  const _ProspectSearchRow.loadMore({
    required this.remaining,
    required this.onPressed,
  })  : kind = _ProspectSearchRowKind.loadMore,
        text = null,
        location = null,
        record = null;

  final _ProspectSearchRowKind kind;
  final String? text;
  final String? location;
  final OfferImportRecord? record;
  final int? remaining;
  final VoidCallback? onPressed;
}

List<OfferImportRecord> _matchingProspectRecords(
  Iterable<OfferImportRecord> records,
  String query, {
  String? category,
  String? storeName,
  Map<OfferImportRecord, String>? searchIndex,
}) {
  final normalized = query.trim().toLowerCase();
  return records
      .where((record) {
        if (storeName != null &&
            prospectStoreMatchKey(record.storeName) !=
                prospectStoreMatchKey(storeName)) {
          return false;
        }
        if (category != null && _prospectCategoryForRecord(record) != category) {
          return false;
        }
        if (normalized.isEmpty) return true;
        final searchable =
            searchIndex?[record] ?? _prospectSearchText(record);
        return searchable.contains(normalized);
      })
      .toList(growable: false);
}

String _prospectSearchText(OfferImportRecord record) {
  final sourceCategory = record.category?.trim() ?? '';
  return [
    record.productLabel,
    record.storeName,
    sourceCategory,
    presentProspectCategory(sourceCategory),
    fallbackProspectCategory(record.productLabel),
    record.ean ?? '',
    record.packageSize ?? '',
    record.priceByBaseUnit ?? '',
  ].join(' ').toLowerCase();
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
  final storesByKey = <String, String>{};
  for (final name in [
    ...issues.map((issue) => issue.storeName),
    ...records.map((record) => record.storeName),
  ]) {
    if (name.trim().isEmpty) continue;
    storesByKey.putIfAbsent(prospectStoreMatchKey(name), () => name.trim());
  }
  return storesByKey.values.toList(growable: false);
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
    sourceAdapter: current?.sourceAdapter ?? selected.sourceAdapter,
    sourceStatus: sourceStatus,
    recordCount: currentRecordCount,
    availablePageCount:
        current?.availablePageCount ?? selected.availablePageCount,
    loadedPageCount: current?.loadedPageCount ?? selected.loadedPageCount,
    missingPageNumbers:
        current?.missingPageNumbers ?? selected.missingPageNumbers,
    pageStatus: current?.pageStatus ?? selected.pageStatus,
    pageCountKnown: current?.pageCountKnown ?? selected.pageCountKnown,
    uncertainProductCount:
        current?.uncertainProductCount ?? selected.uncertainProductCount,
    validFrom: current?.validFrom,
    validUntil: current?.validUntil,
  );
}

ProspectIssue _bestVisibleProspect(Iterable<ProspectIssue> entries) {
  final sorted = entries.toList(growable: false)
    ..sort(_compareVisibleProspects);
  return sorted.first;
}

int _prospectComparablePageCount(ProspectIssue issue) {
  final loadedPageCount = issue.loadedPageCount ?? issue.pages.length;
  final reportedPageCount =
      issue.pageCountKnown ? issue.availablePageCount : null;
  if (reportedPageCount != null && reportedPageCount > loadedPageCount) {
    return reportedPageCount;
  }
  return loadedPageCount;
}

int _compareVisibleProspects(ProspectIssue a, ProspectIssue b) {
  final status = _prospectStatusRank(b.sourceStatus).compareTo(
    _prospectStatusRank(a.sourceStatus),
  );
  if (status != 0) return status;

  final pages = _prospectComparablePageCount(
    b,
  ).compareTo(_prospectComparablePageCount(a));
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
    // Include the exact branch in child keys so lazy grid recycling cannot
    // reuse an image or action from another same-name market.
    final issueKey = prospectIssueKey(issue);
    final thumbnail = _officialProspectUri(issue.thumbnailUrl)?.toString();
    String? previewUrl;
    if (thumbnail != null && thumbnail.isNotEmpty) {
      previewUrl = thumbnail;
    } else if (issue.pages.isNotEmpty) {
      previewUrl = _officialProspectUri(issue.pages.first.imageUrl)?.toString();
    }
    final imageHeight = compact ? 168.0 : 181.0;
    final validity = _prospectValidityLabel(issue);
    final cover = previewUrl == null
        ? _bringCoverPlaceholder()
        : ProspectAdaptiveImage(
            key: ValueKey(
              'prospect-cover-image-${compact ? "grid" : "favorite"}-$issueKey',
            ),
            url: previewUrl,
            // Use one bounded decode size for both cover layouts to avoid
            // duplicate decoded images while the user scrolls quickly.
            cacheWidth: 480,
            cacheHeight: 400,
            fit: BoxFit.cover,
            placeholder: _bringCoverPlaceholder(),
          );

    return RepaintBoundary(
      child: SizedBox(
        width: compact ? double.infinity : 214,
        height: compact ? 300.0 : 340.0,
        child: Card(
          color: _bringSurface,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
            InkWell(
              key: ValueKey(
                'prospect-open-${compact ? 'grid' : 'favorite'}-$issueKey',
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
                  Expanded(
                    child: Container(
                      key: ValueKey(
                        'prospect-details-${compact ? 'grid' : 'favorite'}-$issueKey',
                      ),
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
                  ),
                ],
              ),
            ),
            Positioned(
              top: imageHeight + 10,
              right: compact ? 10 : 12,
              child: _ProspectFavoriteButton(
                storeName: issue.storeName,
                issueKey: issueKey,
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
    required this.issueKey,
    required this.isFavorite,
    required this.onPressed,
    required this.compact,
  });

  final String storeName;
  final String issueKey;
  final bool isFavorite;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final action = isFavorite
        ? '$storeName aus Favoriten entfernen'
        : '$storeName zu Favoriten hinzufügen';
    return IconButton(
      key: ValueKey('prospect-favorite-$issueKey'),
      tooltip: action,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: compact ? 32 : 36,
        height: compact ? 32 : 36,
      ),
      splashRadius: compact ? 17 : 19,
      color: const Color(0xFFE96A73),
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        size: compact ? 20 : 22,
      ),
    );
  }
}

class _EmptyFavoritesCard extends StatelessWidget {
  const _EmptyFavoritesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _bringSurface,
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Noch keine Favoriten. Tippe auf das Herz, um einen Markt zu speichern.',
          style: TextStyle(color: _bringMuted, height: 1.35),
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
  return '${_prospectDate(from)} – ${_prospectDate(until)}';
}

String _ocrCandidatePrice(double value) =>
    '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

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
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.showFilter = false,
    this.onFilter,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
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
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: _bringMuted,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: _bringMuted,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
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
  final String summary;
  if (issue.sourceStatus == 'current_fallback') {
    summary = '${issue.recordCount} Angebote aus dem letzten geprüften '
        'Prospektstand. Automatische Aktualisierung aktuell nicht verfügbar.';
  } else if (issue.sourceStatus == 'regional_only') {
    summary = 'Nur regional erkannt · Filiale noch nicht bestätigt.';
  } else if (issue.recordCount > 0) {
    summary = '${issue.recordCount} Angebote geladen';
  } else {
    summary = _sourceStatusLabel(issue);
  }

  final sourceLabel = prospectSourceLabel(issue);
  final pageLabel = _hasPageCompletenessMetadata(issue)
      ? prospectPageCoverage(issue)
      : null;
  final evidence = <String>[
    ?sourceLabel,
    ?pageLabel,
  ];
  if (evidence.isEmpty) return summary;
  return '$summary · ${evidence.join(' · ')}';
}

bool _hasPageCompletenessMetadata(ProspectIssue issue) =>
    issue.pageCountKnown ||
    issue.availablePageCount != null ||
    issue.missingPageNumbers.isNotEmpty ||
    issue.pageStatus.trim().toLowerCase() == 'unavailable';

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
  if (issue.sourceStatus == 'regional_only') {
    return 'Nur regional erkannt. Eine exakte Filiale ist noch nicht bestätigt.';
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

/// Keeps a record on the selected prospect's exact branch when the
/// source supplied that branch. If the issue has no branch assertion, retain
/// the legacy store-level view without inventing one.
bool _prospectRecordBelongsToIssue(
  OfferImportRecord record,
  ProspectIssue issue,
) {
  if (prospectStoreMatchKey(record.storeName) !=
      prospectStoreMatchKey(issue.storeName)) {
    return false;
  }
  final issueBranchId = issue.branchId?.trim();
  if (issueBranchId == null || issueBranchId.isEmpty) return true;
  final recordBranchId = record.branchId?.trim();
  // A record without branch context stays store-level evidence. Only an
  // explicitly different branch is rejected at this UI boundary.
  return recordBranchId == null ||
      recordBranchId.isEmpty ||
      canonicalBranchId(recordBranchId) == canonicalBranchId(issueBranchId);
}

class ProspectViewerScreen extends StatelessWidget {
  const ProspectViewerScreen({
    super.key,
    required this.issue,
    required this.records,
    required this.catalogProducts,
    this.onAddProduct,
    this.now,
    this.onSaveOffer,
    this.onSaveProspectRegularPrice,
    this.ocrRunner,
  });

  final ProspectIssue issue;
  final List<OfferImportRecord> records;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddProduct;
  final DateTime? now;
  final Future<List<Offer>> Function(Offer offer)? onSaveOffer;
  final Future<void> Function(PriceObservation observation)?
      onSaveProspectRegularPrice;
  final Future<ProspectPageOcrResult> Function(ProspectPage page)? ocrRunner;

  Future<void> _addPageOffer(
    BuildContext context,
    ProspectPage page, {
    ProspectPageOcrCandidate? initialCandidate,
  }) async {
    final addProduct = onAddProduct;
    if (addProduct == null) return;
    final draft = await showProspectPageOfferDialog(
      context,
      initialValidUntil: issue.validUntil,
      initialCandidate: initialCandidate,
    );
    if (draft == null || !context.mounted) return;

    final capturedAt = DateTime.now();
    final record = OfferImportRecord(
      sourceId:
          'manual-page|${issue.storeName}|${page.number}|${capturedAt.microsecondsSinceEpoch}',
      productLabel: draft.productLabel,
      storeName: issue.storeName,
      originalPrice: draft.originalPrice,
      regularPriceSource:
          draft.originalPrice == null ? null : 'manualPage',
      offerPrice: draft.offerPrice,
      validFrom: issue.validFrom,
      validUntil: draft.validUntil,
      source: 'leaflet',
      sourceAdapter: issue.sourceAdapter,
      proofRef: page.zoomUrl ?? page.imageUrl,
      imageUrl: page.imageUrl,
      capturedAt: capturedAt,
      branchId: issue.branchId,
      location: issue.location,
      address: issue.address,
      // A publisher-level KaufDA claim may still add the exact typed
      // product to the shopping list, but it must not become a route price.
      regionalOnly: issue.sourceAdapter?.trim().toLowerCase() == 'kaufda' &&
          issue.branchId?.trim().isNotEmpty != true,
    );
    final requiresExactBranch =
        record.sourceAdapter?.trim().toLowerCase() == 'kaufda';
    final hasExactBranch = hasExactOfferRecordBranch(record);
    // A manually reviewed page item is always listable. Price/route
    // persistence remains a separate, stricter path below.
    final listProduct = productForProspectOffer(record, catalogProducts);
    var regularPriceSaveFailed = false;
    final saveRegularPrice = onSaveProspectRegularPrice;
    if (saveRegularPrice != null) {
      final observation = reviewedProspectRegularPriceObservation(
        record: record,
        catalogProducts: catalogProducts,
        now: now ?? capturedAt,
      );
      if (observation != null) {
        try {
          await saveRegularPrice(observation);
        } catch (_) {
          // The user action remains useful as a list/offer action even when
          // local price storage is temporarily unavailable.
          regularPriceSaveFailed = true;
        }
      }
    }
    if (!context.mounted) return;
    final saveOffer = onSaveOffer;
    if ((requiresExactBranch && !hasExactBranch) || saveOffer == null) {
      addProduct(listProduct);
      final message = requiresExactBranch && !hasExactBranch
          ? 'Artikel zur Einkaufsliste hinzugefügt. Für einen Routenpreis '
              'fehlt die exakte Filiale.'
          : regularPriceSaveFailed
              ? 'Artikel zur Einkaufsliste hinzugefügt. Der geprüfte Normalpreis '
                  'konnte lokal nicht gespeichert werden.'
              : 'Artikel zur Einkaufsliste hinzugefügt. Das Angebot konnte '
                  'ohne Speicherverbindung nicht abgelegt werden.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    final entries = prospectOfferProducts(
      records: [record],
      catalogProducts: catalogProducts,
      now: now ?? DateTime.now(),
    );
    if (entries.length != 1) {
      addProduct(listProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Artikel zur Einkaufsliste hinzugefügt. Das Angebot konnte '
            'mit diesen Angaben nicht als aktueller Preisbeleg gespeichert werden.',
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
      // The OCR candidate was reviewed and explicitly saved by the user.
      evidenceConfidence: EvidenceConfidence.manuallyConfirmed,
      offerPrice: entry.offer.offerPrice,
      validFrom: entry.offer.validFrom,
      validUntil: entry.offer.validUntil,
      source: entry.offer.source,
      sourceAdapter: entry.offer.sourceAdapter,
      capturedAt: entry.offer.capturedAt,
      proofRef: entry.offer.proofRef,
      imageUrl: entry.offer.imageUrl,
      packageAmount: entry.offer.packageAmount,
      packageUnit: entry.offer.packageUnit,
      unitPrice: entry.offer.unitPrice,
      locationId: entry.offer.locationId,
      region: entry.offer.region,
      address: entry.offer.address,
    );
    try {
      await saveOffer(reviewedOffer);
    } catch (_) {
      if (context.mounted) {
        addProduct(listProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Artikel zur Einkaufsliste hinzugefügt. Das Angebot konnte nicht '
              'gespeichert werden.',
            ),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    addProduct(entry.product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.product.name} hinzugefügt')),
    );
  }

  Future<ProspectPageOcrCandidate?> _selectOcrCandidate(
    BuildContext context,
    List<ProspectPageOcrCandidate> candidates,
  ) async {
    if (candidates.length == 1) return candidates.single;
    return showDialog<ProspectPageOcrCandidate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OCR-Vorschlag auswählen'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: candidates.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              final offer = _ocrCandidatePrice(candidate.offerPrice);
              final original = candidate.originalPrice == null
                  ? null
                  : _ocrCandidatePrice(candidate.originalPrice!);
              final prices = original == null
                  ? offer
                  : '$offer · vorher $original';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(candidate.productLabel),
                subtitle: Text(
                  '$prices\n${prospectPageOcrConfidenceLabel(candidate.confidence)}',
                ),
                isThreeLine: true,
                onTap: () => Navigator.of(context).pop(candidate),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Future<void> _runPageOcr(
    BuildContext context,
    ProspectPage page,
  ) async {
    if (onAddProduct == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Seite wird lokal geprüft …')),
      );
    final runner = ocrRunner ?? (value) => analyzeProspectPage(value);
    try {
      final result = await runner(page);
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      if (!result.isReady) {
        messenger.showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }
      final candidate = await _selectOcrCandidate(
        context,
        result.candidates,
      );
      if (!context.mounted || candidate == null) return;
      await _addPageOffer(
        context,
        page,
        initialCandidate: candidate,
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Die lokale Seitenprüfung ist fehlgeschlagen.'),
          ),
        );
    }
  }

  Widget _buildPageCard(
    BuildContext context,
    ProspectPage page, {
    required int pageIndex,
    required bool allowHtmlFallback,
  }) {
    final pageUrl = _officialProspectUri(page.imageUrl)?.toString() ?? '';
    final zoomUri = _officialProspectUri(page.zoomUrl);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 240,
            child: pageUrl.isEmpty
                ? const Center(child: Icon(Icons.broken_image_outlined, size: 48))
                : _ProspectPageImage(
                    url: pageUrl,
                    pageNumber: page.number,
                    pageIndex: pageIndex,
                    allowHtmlFallback: allowHtmlFallback,
                    fallbackBudget: prospectViewerImageFallbackBudget,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Seite ${page.number}'),
                if (zoomUri != null)
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      zoomUri,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.zoom_in),
                    label: const Text('Großansicht öffnen'),
                  ),
                OutlinedButton.icon(
                  onPressed: onAddProduct == null
                      ? null
                      : () => _addPageOffer(context, page),
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('Artikel von Seite hinzufügen'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddProduct == null
                      ? null
                      : () => _runPageOcr(context, page),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Seite per OCR prüfen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _viewerPages(issue);
    final loadedPageCount = pages.length;
    final reportedPageCount =
        issue.pageCountKnown ? issue.availablePageCount : null;
    final visiblePageCount =
        reportedPageCount != null && reportedPageCount > loadedPageCount
            ? reportedPageCount
            : loadedPageCount;
    final hasUnloadedPageSamples =
        reportedPageCount != null && loadedPageCount < reportedPageCount;
    final items = records
        .where((record) => _prospectRecordBelongsToIssue(record, issue))
        .toList(growable: false);
    final groupedItems = <String, List<OfferImportRecord>>{};
    for (final record in items) {
      groupedItems
          .putIfAbsent(_prospectCategoryForRecord(record), () => [])
          .add(record);
    }
    final resolvedProducts = <String, Product?>{};
    final catalogIndex = OfferImportCatalogIndex(catalogProducts);
    final categories = groupedItems.keys.toList()
      ..sort(
        (a, b) =>
            _prospectCategoryOrder(a).compareTo(_prospectCategoryOrder(b)),
      );

    final widgetKeysByCategory =
        <String, Map<OfferImportRecord, String>>{};
    for (final category in categories) {
      final categoryRecords = groupedItems[category]!;
      final keys = prospectOfferWidgetKeys(categoryRecords);
      final indexed = <OfferImportRecord, String>{};
      for (var index = 0; index < categoryRecords.length; index++) {
        indexed[categoryRecords[index]] = keys[index];
      }
      widgetKeysByCategory[category] = indexed;
    }


    final header = <Widget>[
      if (issue.location?.trim().isNotEmpty == true)
        Card(
          key: const ValueKey('prospect-viewer-location'),
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
      if (visiblePageCount > 0) ...[
        const SizedBox(height: 14),
        Text(
          'Prospektseiten ($visiblePageCount)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (hasUnloadedPageSamples)
          Text(
            '$loadedPageCount Bildvorschauen geladen; weitere Seiten beim Händler öffnen.',
            style: const TextStyle(color: Colors.black54),
          ),
      ],
      if (pages.isEmpty)
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
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(issue.storeName)),
      body: CustomScrollView(
        key: const ValueKey('prospect-viewer-scroll'),
        // Do not prebuild network-heavy page cards beyond the viewport. The
        // overview and viewer can contain dozens of retailer pages, and a
        // zero scroll cache keeps image decoding bounded during fast swipes.
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(header),
            ),
          ),
          if (pages.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              sliver: _ProspectPagesSliver(
                pages: pages,
                pageBuilder: (context, page, index) => _buildPageCard(
                  context,
                  page,
                  pageIndex: index,
                  // Every validated page may use the HTML fallback when
                  // its Canvas image cannot decode. The shared budget below
                  // bounds active platform views and releases each slot when
                  // a recycled page leaves the tree.
                  allowHtmlFallback: true,
                ),
              ),
            ),
          if (items.isNotEmpty) ...[
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Produkte antippen und zur Einkaufsliste hinzufügen',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            for (final category in categories) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    category,
                    key: ValueKey('prospect-category-$category'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record = groupedItems[category]![index];
                      final recordKey =
                          widgetKeysByCategory[category]?[record] ??
                          prospectOfferRecordKey(record);
                      final product = _memoizedProspectProduct(
                        record,
                        catalogProducts,
                        resolvedProducts,
                        catalogIndex: catalogIndex,
                      );
                      final manualProduct = product == null
                          ? manualProductForProspectOffer(record)
                          : null;
                      final regionalProduct = record.regionalOnly
                          ? listOnlyProductForRegionalProspectOffer(
                              record,
                              catalogProducts,
                              catalogIndex: catalogIndex,
                            )
                          : null;
                      final selectableProduct = record.regionalOnly
                          ? regionalProduct
                          : product ?? manualProduct;
                      final listOnlyWithoutBranch =
                          record.regionalOnly && selectableProduct != null;
                      final canAdd = onAddProduct != null &&
                          selectableProduct != null;
                      return ProspectOfferCard(
                        key: ValueKey('prospect-offer-$recordKey'),
                        record: record,
                        product: selectableProduct,
                        requiresManualConfirmation: listOnlyWithoutBranch ||
                            (product == null && manualProduct != null),
                        listOnlyWithoutBranch: listOnlyWithoutBranch,
                        onAdd: !canAdd
                            ? null
                            : () => onAddProduct!(selectableProduct),
                      );
                    },
                    childCount: groupedItems[category]!.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    // Leave room for the full evidence block, including
                    // the optional validity start date.
                    mainAxisExtent: 580,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}


const _prospectViewerPageBatchSize = 12;

/// Keeps long prospect viewers responsive by materializing a bounded first
/// batch and adding the remaining page cards only after an explicit action.
/// The source still owns the complete validated page list; this only controls
/// the UI build window and never changes page numbers or evidence.
class _ProspectPagesSliver extends StatefulWidget {
  const _ProspectPagesSliver({
    required this.pages,
    required this.pageBuilder,
  });

  final List<ProspectPage> pages;
  final Widget Function(
    BuildContext context,
    ProspectPage page,
    int index,
  ) pageBuilder;

  @override
  State<_ProspectPagesSliver> createState() => _ProspectPagesSliverState();
}

class _ProspectPagesSliverState extends State<_ProspectPagesSliver> {
  var _visiblePageCount = _prospectViewerPageBatchSize;

  @override
  void didUpdateWidget(covariant _ProspectPagesSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pages, widget.pages)) {
      _visiblePageCount = _prospectViewerPageBatchSize;
    }
  }

  void _loadMore() {
    if (_visiblePageCount >= widget.pages.length) return;
    setState(() {
      final next = _visiblePageCount + _prospectViewerPageBatchSize;
      _visiblePageCount =
          next < widget.pages.length ? next : widget.pages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = _visiblePageCount < widget.pages.length
        ? _visiblePageCount
        : widget.pages.length;
    final remaining = widget.pages.length - visibleCount;
    final itemCount = visibleCount + (remaining > 0 ? 1 : 0);

    return SliverList.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < visibleCount) {
          return widget.pageBuilder(
            context,
            widget.pages[index],
            index,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            key: const ValueKey('prospect-viewer-load-more'),
            onPressed: _loadMore,
            icon: const Icon(Icons.expand_more),
            label: Text('Weitere Seiten laden ($remaining)'),
          ),
        );
      },
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
    );
  }
}

const prospectPageHtmlFallbackBudget = 2;

/// Retained as a deterministic helper for callers that want to reserve the
/// first two page slots. The viewer itself uses the releasing shared budget
/// below, so later pages can also recover from a Canvas/CORS failure after the
/// user scrolls them into view.
bool prospectPageHtmlFallbackAllowed(int pageIndex) =>
    pageIndex >= 0 && pageIndex < prospectPageHtmlFallbackBudget;

/// A page viewer may have a different failure pattern from the cover rail.
/// Keep its platform-view allowance separate and release slots when pages are
/// recycled, so scrolling through a long prospect cannot accumulate views.
final prospectViewerImageFallbackBudget =
    ProspectImageFallbackBudget(maxActiveFallbacks: prospectPageHtmlFallbackBudget);

class _ProspectPageImage extends StatefulWidget {
  const _ProspectPageImage({
    required this.url,
    required this.pageNumber,
    required this.pageIndex,
    required this.allowHtmlFallback,
    this.fallbackBudget,
  });

  final String url;
  final int pageNumber;
  final int pageIndex;
  final bool allowHtmlFallback;
  final ProspectImageFallbackBudget? fallbackBudget;

  @override
  State<_ProspectPageImage> createState() => _ProspectPageImageState();
}

class _ProspectPageImageState extends State<_ProspectPageImage> {
  bool _useHtmlFallback = false;
  ProspectImageFallbackBudget? _reservedBudget;

  ProspectImageFallbackBudget get _budget =>
      widget.fallbackBudget ?? prospectViewerImageFallbackBudget;

  void _releaseFallbackSlot() {
    final budget = _reservedBudget;
    if (budget == null) return;
    budget.release();
    _reservedBudget = null;
  }

  @override
  void didUpdateWidget(covariant _ProspectPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.allowHtmlFallback != widget.allowHtmlFallback ||
        oldWidget.fallbackBudget != widget.fallbackBudget) {
      _releaseFallbackSlot();
      _useHtmlFallback = false;
    }
  }

  @override
  void dispose() {
    _releaseFallbackSlot();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strategy = _useHtmlFallback
        ? WebHtmlElementStrategy.fallback
        : WebHtmlElementStrategy.never;
    return Image.network(
      widget.url,
      // Include the rendered index as well as the source number. A stale
      // cache can contain duplicate page numbers; the image state must stay
      // unique while the sliver recycles children during scrolling.
      key: ValueKey(
        'prospect-page-image-${widget.pageNumber}-${widget.pageIndex}',
      ),
      // Keep decoded page previews bounded for the long scroll path.
      // The viewer renders a 240 px high preview; 560×380 keeps it sharp
      // on high-density screens without retaining a full-size page bitmap.
      cacheWidth: 560,
      cacheHeight: 380,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.low,
      // Canvas is the cheap path. A platform-view fallback is created only
      // after this exact image failed to decode (usually because the retailer
      // CDN omitted Canvas-CORS headers).
      webHtmlElementStrategy: strategy,
      // Use one stable placeholder until the first decoded frame is
      // available. A loadingBuilder reacts to every network chunk and can
      // trigger repeated rebuilds while a long page list is being scrolled.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          if (_useHtmlFallback) {
            // Release after the browser element has produced its first frame;
            // a successful fallback no longer consumes a concurrency slot.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _releaseFallbackSlot();
            });
          }
          return child;
        }
        return const ColoredBox(
          color: Color(0xFFEAF0F1),
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (!widget.allowHtmlFallback) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, size: 48),
          );
        }
        if (!_useHtmlFallback && _reservedBudget == null) {
          if (!_budget.tryAcquire()) {
            return const Center(
              child: Icon(Icons.broken_image_outlined, size: 48),
            );
          }
          _reservedBudget = _budget;
          final failedUrl = widget.url;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                _useHtmlFallback ||
                !prospectImageFallbackMatches(
                  currentUrl: widget.url,
                  failedUrl: failedUrl,
                )) {
              return;
            }
            setState(() => _useHtmlFallback = true);
          });
          return const Center(child: CircularProgressIndicator());
        }
        return const Center(
          child: Icon(Icons.broken_image_outlined, size: 48),
        );
      },
    );
  }
}

List<ProspectPage> _viewerPages(ProspectIssue issue) {
  if (issue.pages.isNotEmpty) {
    final pages = issue.pages;
    // Some public feeds expose a cover separately and only include the
    // interior samples in `pages` (starting at page 2). Keep the source
    // page numbers intact and add the cover as the missing first page.
    final hasFirstPage = pages.any((page) => page.number == 1);
    if (hasFirstPage) return pages;
    final thumbnail = issue.thumbnailUrl?.trim();
    final cover = thumbnail == null || thumbnail.isEmpty
        ? null
        : _officialProspectUri(thumbnail)?.toString();
    if (cover == null || cover == pages.first.imageUrl.trim()) return pages;
    return [
      ProspectPage(number: 1, imageUrl: cover),
      ...pages,
    ];
  }
  final thumbnail = issue.thumbnailUrl?.trim();
  if (thumbnail == null || thumbnail.isEmpty) {
    return const <ProspectPage>[];
  }
  final uri = _officialProspectUri(thumbnail);
  if (uri == null) return const <ProspectPage>[];
  return [ProspectPage(number: 1, imageUrl: uri.toString())];
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
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      (scheme != 'http' && scheme != 'https') ||
      uri.host.isEmpty) {
    return null;
  }
  return uri;
}