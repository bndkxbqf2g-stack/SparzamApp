import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../services/prospect_favorites_store.dart';
import '../../services/prospect_feed_service.dart';
import 'prospect_issue_identity.dart';

/// Returns whether a delayed browser-image fallback still belongs to the
/// image currently mounted in a recycled prospect card.
bool prospectImageFallbackMatches({
  required String currentUrl,
  required String failedUrl,
}) => currentUrl == failedUrl;

/// Limits expensive HTML platform views created after a Canvas image fails.
/// A recycled cover releases its slot when it leaves the tree, so a short
/// scroll cannot accumulate one browser view per failed retailer image.
class ProspectImageFallbackBudget {
  ProspectImageFallbackBudget({this.maxActiveFallbacks = 4})
      : assert(maxActiveFallbacks > 0);

  final int maxActiveFallbacks;
  var _activeFallbacks = 0;

  int get activeFallbacks => _activeFallbacks;

  bool tryAcquire() {
    if (_activeFallbacks >= maxActiveFallbacks) return false;
    _activeFallbacks++;
    return true;
  }

  void release() {
    if (_activeFallbacks == 0) return;
    _activeFallbacks--;
  }
}

/// Shared by the cover cards in the overview and the favorite rail.
final prospectImageFallbackBudget = ProspectImageFallbackBudget();

/// A Bring-style overview of validated prospect covers.
///
/// The section deliberately receives already validated [ProspectIssue] data.
/// It never invents a cover URL or a validity period and keeps the full page
/// viewer behind an explicit tap.
class ProspectCoverSection extends StatefulWidget {
  const ProspectCoverSection({
    super.key,
    required this.issues,
    required this.onOpen,
    this.favoriteStore,
  });

  final List<ProspectIssue> issues;
  final ValueChanged<ProspectIssue> onOpen;
  final ProspectFavoritesStore? favoriteStore;

  @override
  State<ProspectCoverSection> createState() => _ProspectCoverSectionState();
}

class _ProspectCoverSectionState extends State<ProspectCoverSection> {
  final _allProspectsKey = GlobalKey();
  late final ProspectFavoritesStore _favoriteStore;
  static const _gridPageSize = 12;
  Set<String>? _favoriteStores;
  var _favoriteIndex = const ProspectFavoriteIndex.empty();
  String? _selectedStore;
  var _visibleGridCount = _gridPageSize;
  List<ProspectIssue>? _uniqueIssuesInput;
  List<ProspectIssue>? _uniqueIssuesCache;

  List<ProspectIssue> _uniqueIssueList() {
    if (identical(_uniqueIssuesInput, widget.issues)) {
      return _uniqueIssuesCache ?? const <ProspectIssue>[];
    }
    final next = _uniqueIssues(widget.issues);
    _uniqueIssuesInput = widget.issues;
    _uniqueIssuesCache = next;
    return next;
  }

  @override
  void initState() {
    super.initState();
    _favoriteStore = widget.favoriteStore ?? ProspectFavoritesStore();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoriteStore.load();
    if (!mounted) return;
    setState(() {
      _favoriteStores = favorites;
      _favoriteIndex =
          ProspectFavoriteIndex.from(favorites ?? const <String>[]);
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
  

  Future<void> _chooseStore() async {
    final storesByKey = <String, String>{};
    for (final issue in _uniqueIssueList()) {
      storesByKey.putIfAbsent(
        prospectStoreMatchKey(issue.storeName),
        () => issue.storeName,
      );
    }
    final stores = storesByKey.values.toList()..sort();
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Prospektfilter'),
              subtitle: Text('Einen Markt für die Coveransicht auswählen'),
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Alle Märkte'),
              onTap: () => Navigator.of(context).pop('all'),
            ),
            for (final store in stores)
              ListTile(
                leading: const Icon(Icons.store_outlined),
                title: Text(store),
                onTap: () => Navigator.of(context).pop(store),
              ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _selectedStore = selected == 'all' ? null : selected;
      _visibleGridCount = _gridPageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allIssues = _uniqueIssueList();
    final selectedStoreKey = _selectedStore == null
        ? null
        : prospectStoreMatchKey(_selectedStore!);
    final issues = selectedStoreKey == null
        ? allIssues
        : allIssues
            .where(
              (issue) =>
                  prospectStoreMatchKey(issue.storeName) == selectedStoreKey,
            )
            .toList(growable: false);
    if (issues.isEmpty) return const SizedBox.shrink();

    final favorites = _favoriteStores == null
        ? issues.take(2).toList(growable: false)
        : issues
            .where(_isFavorite)
            .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Deine Favoriten',
          actionLabel: 'Mehr ›',
          onAction: () {
            final target = _allProspectsKey.currentContext;
            if (target != null) {
              Scrollable.ensureVisible(
                target,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
              );
            }
          },
        ),
        const SizedBox(height: 10),
        if (_favoriteStores != null && favorites.isEmpty)
          const _EmptyFavorites()
        else
          SizedBox(
            height: 340,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Favorites are a bounded rail. Do not retain offscreen cards or
              // decode an additional image row while the parent feed moves.
              scrollCacheExtent: const ScrollCacheExtent.pixels(0),
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemCount: favorites.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final issue = favorites[index];
                return ProspectCoverCard(
                  key: ValueKey(
                    'offer-cover-favorite-${prospectIssueKey(issue)}',
                  ),
                  issue: issue,
                  compact: false,
                  isFavorite: _isFavorite(issue),
                  onToggleFavorite: () => _toggleFavorite(issue),
                  onOpen: () => widget.onOpen(issue),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        _SectionHeader(
          key: _allProspectsKey,
          title: 'Weitere Prospekte',
          showFilter: true,
          onFilter: _chooseStore,
        ),
        const SizedBox(height: 2),
        const Text(
          'Alle Prospekte',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 650 ? 3 : 2;
            final visibleCount = _visibleGridCount.clamp(0, issues.length);
            return Column(
              children: [
                GridView.builder(
                  // The cover section lives inside the Offers scroll. A
                  // shrink-wrapped grid otherwise lays out every feed item at
                  // once, which is expensive for large public prospect feeds.
                  // Keep the first page small and add further cards on demand.
                  itemCount: visibleCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // The outer ListView owns scrolling and its bounded cache.
                  // Avoid a second grid cache retaining decoded cover cards.
                  scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    // Leave room for source and page-completeness metadata
                    // without allowing a card to overflow during grid layout.
                    mainAxisExtent: 324,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    // Paint the whole sliver tile. Recycled cover content can
                    // be smaller than the fixed grid extent for one frame; the
                    // tile must keep the card surface white in that gap.
                    return SizedBox.expand(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ColoredBox(
                          color: Colors.white,
                          child: ProspectCoverCard(
                            key: ValueKey(
                              'offer-cover-grid-${prospectIssueKey(issue)}',
                            ),
                            issue: issue,
                            compact: true,
                            isFavorite: _isFavorite(issue),
                            onToggleFavorite: () => _toggleFavorite(issue),
                            onOpen: () => widget.onOpen(issue),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (visibleCount < issues.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton.icon(
                      key: const ValueKey('prospect-covers-load-more'),
                      onPressed: () => setState(
                        () => _visibleGridCount =
                            (_visibleGridCount + _gridPageSize).clamp(
                              0,
                              issues.length,
                            ),
                      ),
                      icon: const Icon(Icons.expand_more),
                      label: Text(
                        'Weitere Prospekte laden (${issues.length - visibleCount})',
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

}

class ProspectCoverCard extends StatelessWidget {
  const ProspectCoverCard({
    super.key,
    required this.issue,
    required this.onOpen,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.compact = false,
  });

  final ProspectIssue issue;
  final VoidCallback onOpen;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final previewUrl = prospectCoverPreviewUrl(issue);
    final fallbackUrl = prospectCoverPageFallbackUrl(issue);
    final imageHeight = compact ? 168.0 : 181.0;
    final scope = compact ? 'grid' : 'favorite';
    final image = previewUrl == null
        ? _coverPlaceholder()
        : ProspectAdaptiveImage(
            key: ValueKey(
              'offer-cover-image-$scope-${prospectIssueKey(issue)}',
            ),
            url: previewUrl,
            fallbackUrl: fallbackUrl,
            // Use one bounded decode size for favorites and the grid so the
            // same cover does not occupy two decoded browser-cache entries.
            cacheWidth: 480,
            cacheHeight: 400,
            fit: BoxFit.cover,
            placeholder: _coverPlaceholder(),
          );

    final validity = _validity(issue);
    final cardHeight = compact ? 324.0 : 340.0;
    final titleStyle = TextStyle(
      color: const Color(0xFF27343A),
      fontSize: 16.0,
      fontWeight: FontWeight.w800,
    );
    final primaryMetaStyle = TextStyle(
      color: const Color(0xFF6F7C80),
      fontSize: 12.0,
    );
    final secondaryMetaStyle = TextStyle(
      color: const Color(0xFF6F7C80),
      fontSize: 11.0,
    );
    return RepaintBoundary(
      child: SizedBox(
        width: compact ? double.infinity : 214,
        height: cardHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: ClipRRect(
            key: ValueKey(
              'offer-cover-surface-$scope-${prospectIssueKey(issue)}',
            ),
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(
            color: Colors.white,
            child: Material(
              key: ValueKey(
                'offer-cover-material-$scope-${prospectIssueKey(issue)}',
              ),
              type: MaterialType.card,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: SizedBox.expand(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: Colors.white),
                    ),
                    Positioned.fill(
                      child: InkWell(
                        key: ValueKey(
                          'offer-cover-open-$scope-${prospectIssueKey(issue)}',
                        ),
                        onTap: onOpen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: imageHeight, child: image),
                            Expanded(
                              child: Container(
                                key: ValueKey(
                                  'offer-cover-details-$scope-${prospectIssueKey(issue)}',
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
                                    SizedBox(
                                      height: 32,
                                      child: Text(
                                        issue.storeName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: titleStyle,
                                      ),
                                    ),
                                    if (issue.location?.trim().isNotEmpty == true)
                                      Text(
                                        issue.location!.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: primaryMetaStyle,
                                      ),
                                    if (validity != null)
                                      Text(
                                        validity,
                                        style: primaryMetaStyle,
                                      ),
                                    if (prospectSourceLabel(issue)
                                        case final sourceLabel?)
                                      Text(
                                        sourceLabel,
                                        key: ValueKey(
                                          'prospect-cover-source-$scope-${prospectIssueKey(issue)}',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: secondaryMetaStyle,
                                      ),
                                    if (prospectPageCoverage(issue)
                                        case final pageCoverage?)
                                      Text(
                                        pageCoverage,
                                        key: ValueKey(
                                          'prospect-cover-pages-$scope-${prospectIssueKey(issue)}',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: secondaryMetaStyle,
                                      ),
                                    Text(
                                      issue.recordCount > 0
                                          ? '${issue.recordCount} Angebote geladen'
                                          : 'Prospekt öffnen',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: secondaryMetaStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: imageHeight + 8,
                      right: compact ? 8 : 10,
                      child: IconButton(
                        key: ValueKey(
                          'offer-cover-favorite-$scope-${prospectIssueKey(issue)}',
                        ),
                        tooltip: isFavorite
                            ? '${issue.storeName} aus Favoriten entfernen'
                            : '${issue.storeName} zu Favoriten hinzufügen',
                        onPressed: onToggleFavorite,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tightFor(
                          width: compact ? 32 : 36,
                          height: compact ? 32 : 36,
                        ),
                        color: const Color(0xFFE96A73),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: compact ? 20 : 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Displays a prospect cover on the cheap Canvas path and retries only
/// failed decodes with a single HTML image element. This keeps CORS-sensitive
/// retailer covers visible without creating platform views for every card.
class ProspectAdaptiveImage extends StatefulWidget {
  const ProspectAdaptiveImage({
    super.key,
    required this.url,
    required this.cacheWidth,
    required this.cacheHeight,
    required this.fit,
    required this.placeholder,
    this.fallbackUrl,
    this.fallbackBudget,
  });

  final String url;
  final int cacheWidth;
  final int cacheHeight;
  final BoxFit fit;
  final Widget placeholder;
  final String? fallbackUrl;
  final ProspectImageFallbackBudget? fallbackBudget;

  @override
  State<ProspectAdaptiveImage> createState() => _ProspectAdaptiveImageState();
}

class _ProspectAdaptiveImageState extends State<ProspectAdaptiveImage> {
  bool _useAlternateUrl = false;
  bool _useHtmlFallback = false;
  bool _fallbackDenied = false;
  ProspectImageFallbackBudget? _reservedBudget;

  String get _activeUrl =>
      _useAlternateUrl ? widget.fallbackUrl ?? widget.url : widget.url;

  ProspectImageFallbackBudget get _budget =>
      widget.fallbackBudget ?? prospectImageFallbackBudget;

  void _releaseFallbackSlot() {
    final budget = _reservedBudget;
    if (budget == null) return;
    budget.release();
    _reservedBudget = null;
  }

  @override
  void didUpdateWidget(covariant ProspectAdaptiveImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.fallbackUrl != widget.fallbackUrl ||
        oldWidget.fallbackBudget != widget.fallbackBudget) {
      _releaseFallbackSlot();
      _useAlternateUrl = false;
      _useHtmlFallback = false;
      _fallbackDenied = false;
    }
  }

  @override
  void dispose() {
    _releaseFallbackSlot();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeUrl = _activeUrl;
    return Image.network(
      activeUrl,
      key: ValueKey('prospect-adaptive-image-$activeUrl'),
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      filterQuality: FilterQuality.low,
      fit: widget.fit,
      // Successful images stay on Canvas. A browser platform view is created
      // only after this exact URL failed to decode there.
      webHtmlElementStrategy: _useHtmlFallback
          ? WebHtmlElementStrategy.fallback
          : WebHtmlElementStrategy.never,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return widget.placeholder;
      },
      errorBuilder: (context, error, stackTrace) {
        final alternateUrl = _safeImageUrl(widget.fallbackUrl);
        if (!_useAlternateUrl &&
            alternateUrl != null &&
            alternateUrl != widget.url) {
          final primaryUrl = widget.url;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                _useAlternateUrl ||
                widget.url != primaryUrl ||
                widget.fallbackUrl != alternateUrl) {
              return;
            }
            setState(() => _useAlternateUrl = true);
          });
          return widget.placeholder;
        }
        if (!_useHtmlFallback &&
            !_fallbackDenied &&
            _reservedBudget == null) {
          if (!_budget.tryAcquire()) {
            _fallbackDenied = true;
            return widget.placeholder;
          }
          _reservedBudget = _budget;
          final failedUrl = activeUrl;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                _useHtmlFallback ||
                !prospectImageFallbackMatches(
                  currentUrl: _activeUrl,
                  failedUrl: failedUrl,
                )) {
              return;
            }
            setState(() => _useHtmlFallback = true);
          });
        }
        return widget.placeholder;
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
        if (showFilter)
          IconButton(
            tooltip: 'Prospektfilter',
            onPressed: onFilter,
            icon: const Icon(Icons.tune),
          ),
      ],
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Noch keine Favoriten. Tippe auf das Herz, um einen Markt zu speichern.',
          ),
        ),
      );
}

/// Returns the first validated image that can represent a prospect cover.

/// A dedicated thumbnail wins; otherwise the first valid page image is used.
/// The fallback does not change page numbering or create a new source record.
String? prospectCoverPreviewUrl(ProspectIssue issue) {
  final thumbnail = _safeImageUrl(issue.thumbnailUrl);
  if (thumbnail != null) return thumbnail;
  for (final page in issue.pages) {
    final image = _safeImageUrl(page.imageUrl);
    if (image != null) return image;
  }
  return null;
}

/// Returns a second validated page image to try when the preferred cover fails.
String? prospectCoverPageFallbackUrl(ProspectIssue issue) {
  final preview = prospectCoverPreviewUrl(issue);
  for (final page in issue.pages) {
    final image = _safeImageUrl(page.imageUrl);
    if (image != null && image != preview) return image;
  }
  return null;
}

Widget _coverPlaceholder() => const ColoredBox(
      color: Color(0xFF435A64),
      child: Center(
        child: Icon(
          Icons.local_offer_outlined,
          color: Color(0xFF9DE5D8),
          size: 52,
        ),
      ),
    );

String? _safeImageUrl(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      uri.host.trim().isEmpty ||
      (scheme != 'http' && scheme != 'https')) {
    return null;
  }
  return raw;
}

String? _validity(ProspectIssue issue) {
  final from = issue.validFrom;
  final until = issue.validUntil;
  if (from == null || until == null) return null;
  String date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  return '${date(from)} – ${date(until)}';
}

String? prospectSourceLabel(ProspectIssue issue) {
  final adapter = issue.sourceAdapter?.trim();
  final adapterLabel = adapter == null || adapter.isEmpty
      ? null
      : 'Quelle: $adapter';
  final branch = issue.branchId?.trim();
  final branchLabel = branch == null || branch.isEmpty
      ? null
      : 'Filiale: $branch';
  final labels = <String>[
    ?adapterLabel,
    ?branchLabel,
  ];
  return labels.isEmpty ? null : labels.join(' · ');
}

String? prospectPageCoverage(ProspectIssue issue) {
  final loaded = issue.loadedPageCount ?? issue.pages.length;
  final available = issue.availablePageCount;
  if (available != null && available > 0) {
    final missing = issue.missingPageNumbers.length;
    final missingLabel = missing == 0
        ? ''
        : missing == 1
            ? ' · 1 fehlt'
            : ' · $missing fehlen';
    return '$loaded/$available Seiten geladen$missingLabel';
  }
  if (loaded > 0) return '$loaded Seiten geladen';
  if (issue.pageStatus.trim().toLowerCase() == 'unavailable') {
    return 'Seiten nicht verfügbar';
  }
  return null;
}

List<ProspectIssue> _uniqueIssues(Iterable<ProspectIssue> issues) {
  final byStore = <String, ProspectIssue>{};
  for (final issue in issues) {
    final key = prospectIssueMatchKey(issue);
    final previous = byStore[key];
    if (previous == null || _issueScore(issue) > _issueScore(previous)) {
      byStore[key] = issue;
    }
  }
  return byStore.values.toList(growable: false);
}

int _issueScore(ProspectIssue issue) {
  final status = switch (issue.sourceStatus) {
    'ok' => 4,
    'metadata_only' => 3,
    'current_fallback' => 2,
    'stale_fallback' => 1,
    'regional_only' => 1,
    _ => 0,
  };
  return status * 100000 +
      issue.pages.length * 1000 +
      (issue.thumbnailUrl?.trim().isNotEmpty == true ? 100 : 0) +
      issue.recordCount;
}