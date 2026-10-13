import 'package:flutter/material.dart';

import '../../services/prospect_favorites_store.dart';
import '../../services/prospect_feed_service.dart';

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
  Set<String>? _favoriteStores;
  String? _selectedStore;

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
    setState(() => _selectedStore = selected == 'all' ? null : selected);
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
            .where((issue) => _favoriteStores!.contains(issue.storeName))
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
              itemCount: favorites.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final issue = favorites[index];
                return ProspectCoverCard(
                  key: ValueKey(
                    'offer-cover-favorite-${issue.storeName}',
                  ),
                  issue: issue,
                  compact: false,
                  isFavorite: _isFavorite(issue),
                  onToggleFavorite: () => _toggleFavorite(issue.storeName),
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
            return GridView.builder(
              itemCount: issues.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 300,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final issue = issues[index];
                return ProspectCoverCard(
                  key: ValueKey('offer-cover-grid-${issue.storeName}'),
                  issue: issue,
                  compact: true,
                  isFavorite: _isFavorite(issue),
                  onToggleFavorite: () => _toggleFavorite(issue.storeName),
                  onOpen: () => widget.onOpen(issue),
                );
              },
            );
          },
        ),
      ],
    );
  }

  bool _isFavorite(ProspectIssue issue) =>
      (_favoriteStores ?? const <String>{}).contains(issue.storeName);
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
        : Image.network(
            previewUrl,
            key: ValueKey(
              'offer-cover-image-$scope-${issue.storeName}',
            ),
            cacheWidth: compact ? 480 : 640,
            cacheHeight: compact ? 400 : 480,
            filterQuality: FilterQuality.low,
            // Overview covers stay on the Canvas renderer. A browser
            // platform view for every retailer CDN image can make fast
            // vertical and horizontal scrolling unstable on Flutter web;
            // the full viewer keeps its explicit fallback boundary.
            webHtmlElementStrategy: WebHtmlElementStrategy.never,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => _coverPlaceholder(),
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
                  'offer-cover-open-$scope-${issue.storeName}',
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
                    'offer-cover-favorite-$scope-${issue.storeName}',
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

List<ProspectIssue> _uniqueIssues(Iterable<ProspectIssue> issues) {
  final byStore = <String, ProspectIssue>{};
  for (final issue in issues) {
    final previous = byStore[issue.storeName];
    if (previous == null || _issueScore(issue) > _issueScore(previous)) {
      byStore[issue.storeName] = issue;
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
