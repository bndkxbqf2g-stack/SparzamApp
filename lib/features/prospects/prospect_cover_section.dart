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
  String? _selectedStore;
  var _visibleGridCount = _gridPageSize;

  @override
  void initState() {
    super.initState();
    _favoriteStore = widget.favoriteStore ?? ProspectFavoritesStore();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoriteStore.load();
    if (!mounted) return;
    setState(() => _favoriteStores = favorites);
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
      (_favoriteStores ?? const <String>{}).any(
        (storedKey) =>
            prospectFavoriteMatches(storedKey: storedKey, issue: issue),
      );

  Future<void> _chooseStore() async {
    final stores = _uniqueIssues(widget.issues)
        .map((issue) => issue.storeName)
        .toSet()
        .toList()
      ..sort();
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
    final allIssues = _uniqueIssues(widget.issues);
    final issues = _selectedStore == null
        ? allIssues
        : allIssues
            .where((issue) => issue.storeName == _selectedStore)
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
              scrollCacheExtent: const ScrollCacheExtent.pixels(0),
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
                    return ProspectCoverCard(
                      key: ValueKey(
                        'offer-cover-grid-${prospectIssueKey(issue)}',
                      ),
                      issue: issue,
                      compact: true,
                      isFavorite: _isFavorite(issue),
                      onToggleFavorite: () => _toggleFavorite(issue),
                      onOpen: () => widget.onOpen(issue),
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
    final previewUrl = _safeImageUrl(issue.thumbnailUrl) ??
        (issue.pages.isEmpty ? null : _safeImageUrl(issue.pages.first.imageUrl));
    final imageHeight = compact ? 168.0 : 181.0;
    final scope = compact ? 'grid' : 'favorite';
    final image = previewUrl == null
        ? _coverPlaceholder()
        : ProspectAdaptiveImage(
            key: ValueKey(
              'offer-cover-image-$scope-${prospectIssueKey(issue)}',
            ),
            url: previewUrl,
            // Use one bounded decode size for favorites and the grid so the
            // same cover does not occupy two decoded browser-cache entries.
            cacheWidth: 480,
            cacheHeight: 400,
            fit: BoxFit.cover,
            placeholder: _coverPlaceholder(),
          );

    final validity = _validity(issue);
    return RepaintBoundary(
      child: SizedBox(
        width: compact ? double.infinity : 214,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InkWell(
                key: ValueKey(
                  'offer-cover-open-$scope-${prospectIssueKey(issue)}',
                ),
                onTap: onOpen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: imageHeight, child: image),
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
                          SizedBox(
                            height: 32,
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
                          if (issue.location?.trim().isNotEmpty == true)
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
                          if (_sourceLabel(issue) case final sourceLabel?)
                            Text(
                              sourceLabel,
                              key: ValueKey(
                                'prospect-cover-source-$scope-${prospectIssueKey(issue)}',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6F7C80),
                                fontSize: 11,
                              ),
                            ),
                          if (_pageCoverage(issue) case final pageCoverage?)
                            Text(
                              pageCoverage,
                              key: ValueKey(
                                'prospect-cover-pages-$scope-${prospectIssueKey(issue)}',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6F7C80),
                                fontSize: 11,
                              ),
                            ),
                          Text(
                            issue.recordCount > 0
                                ? '${issue.recordCount} Angebote geladen'
                                : 'Prospekt öffnen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6F7C80),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    this.fallbackBudget,
  });

  final String url;
  final int cacheWidth;
  final int cacheHeight;
  final BoxFit fit;
  final Widget placeholder;
  final ProspectImageFallbackBudget? fallbackBudget;

  @override
  State<ProspectAdaptiveImage> createState() => _ProspectAdaptiveImageState();
}

class _ProspectAdaptiveImageState extends State<ProspectAdaptiveImage> {
  bool _useHtmlFallback = false;
  bool _fallbackDenied = false;
  ProspectImageFallbackBudget? _reservedBudget;

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
        oldWidget.fallbackBudget != widget.fallbackBudget) {
      _releaseFallbackSlot();
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
    return Image.network(
      widget.url,
      key: ValueKey('prospect-adaptive-image-${widget.url}'),
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
        if (!_useHtmlFallback &&
            !_fallbackDenied &&
            _reservedBudget == null) {
          if (!_budget.tryAcquire()) {
            _fallbackDenied = true;
            return widget.placeholder;
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

String? _sourceLabel(ProspectIssue issue) {
  final adapter = issue.sourceAdapter?.trim();
  if (adapter == null || adapter.isEmpty) return null;
  return 'Quelle: $adapter';
}

String? _pageCoverage(ProspectIssue issue) {
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
    final previous = byStore[prospectIssueKey(issue)];
    if (previous == null || _issueScore(issue) > _issueScore(previous)) {
      byStore[prospectIssueKey(issue)] = issue;
    }
  }
  return byStore.values.toList(growable: false);
}

int _issueScore(ProspectIssue issue) {
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
