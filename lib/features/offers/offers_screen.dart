import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/sparzam_theme.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import 'offer_import.dart';
import 'prospect_offer_products.dart';
import '../prospects/prospect_category_presentation.dart';
import '../../services/prospect_branch_resolver.dart';
import '../../services/prospect_feed_service.dart';
import '../prospects/prospect_feed_status.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Angebote'), centerTitle: true),
      body: ListView(
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
            fromCache: widget.fromCache,
          ),
          const SizedBox(height: 12),
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
              '${configuredProspectBranch(entry.key)?.location ?? 'Filiale'} · '
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
                                  _ProspectOfferCard(
                                    record: record,
                                    catalogProducts: widget.catalogProducts,
                                    onAddToShoppingList:
                                        widget.onAddToShoppingList,
                                  ),
                              ]
                            : const [],
                      ),
                  ]
                : const [],
          ),
      ],
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
      final usesCurrentFallback = issue.sourceStatus == 'error' && count > 0;
      if (count > 0 && !usesCurrentFallback) continue;
      final String status;
      if (issue.sourceStatus == 'ok') {
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
      _ => 'Für diesen Markt sind aktuell keine Angebotsdaten verfügbar.',
    };
    final location = issue.location?.trim();
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
                  if (issue.url?.trim().isNotEmpty == true)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(issue.url!),
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

class _ProspectOfferCard extends StatelessWidget {
  const _ProspectOfferCard({
    required this.record,
    required this.catalogProducts,
    this.onAddToShoppingList,
  });

  final OfferImportRecord record;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddToShoppingList;

  @override
  Widget build(BuildContext context) {
    final resolution = resolveOfferImport(record, catalogProducts);
    // A verified current offer may still describe a product that is not in
    // the local catalog yet. Keep that exact retailer label selectable. The
    // fallback deliberately carries no aliases or inferred variant; adding
    // it is the user's explicit decision and the catalog can learn it later.
    final product =
        resolution.product ??
        (resolution.reason == 'unknown_identity' &&
                record.proofRef?.trim().isNotEmpty == true
            ? productForProspectOffer(record, catalogProducts)
            : null);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: record.imageUrl?.isNotEmpty == true
                ? Image.network(
                    record.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(_categoryIcon(_offerCategory(record))),
                  )
                : Icon(_categoryIcon(_offerCategory(record))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.productLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${record.offerPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: SparzamTheme.deepGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onAddToShoppingList != null)
            IconButton(
              tooltip: 'Zur Einkaufsliste',
              onPressed: product == null
                  ? null
                  : () => onAddToShoppingList!(product),
              icon: const Icon(Icons.add_shopping_cart_outlined),
            ),
        ],
      ),
    );
  }
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
  final label = record.productLabel;
  final value = label.toLowerCase();
  if (RegExp(r'gemüse|salat|tomat|gurk|kartoff|obst|apfel|banane|traube')
      .hasMatch(value)) {
    return 'Obst & Gemüse';
  }
  if (RegExp(r'milch|joghurt|käse|schmand|sahne|quark|butter')
      .hasMatch(value)) {
    return 'Milchprodukte';
  }
  if (RegExp(r'hack|fleisch|wurst|schinken|fisch|lachs|hähnchen')
      .hasMatch(value)) {
    return 'Fleisch & Fisch';
  }
  if (RegExp(r'brot|bröt|toast|backwaren|croissant').hasMatch(value)) {
    return 'Backwaren';
  }
  if (RegExp(r'kaffee|espresso|tee|snack|chips|knabber').hasMatch(value)) {
    return 'Kaffee & Snacks';
  }
  if (RegExp(r'getränk|wasser|saft|cola|bier|wein').hasMatch(value)) {
    return 'Getränke';
  }
  if (RegExp(r'tiefkühl|tk |pizza|eis ').hasMatch(value)) return 'Tiefkühl';
  if (RegExp(r'reis|nudel|mehl|zucker|dose|konserve|sauce|öl|gewürz')
      .hasMatch(value)) {
    return 'Vorrat & Konserven';
  }
  if (RegExp(r'seife|shampoo|zahnpasta|deo|waschmittel|reiniger')
      .hasMatch(value)) {
    return 'Drogerie';
  }
  if (RegExp(r'küche|haushalt|müll|papier|lampe|werkzeug|akku|bastel|raum-weiß')
      .hasMatch(value)) {
    return 'Haushalt';
  }
  if (RegExp(r'non-food|bekleidung|schuh|spielzeug|dekoration')
      .hasMatch(value)) {
    return 'Non-Food';
  }
  return 'Weitere Angebote';
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

IconData _categoryIcon(String category) => switch (category) {
  'Obst & Gemüse' => Icons.eco_outlined,
  'Milchprodukte' => Icons.egg_alt_outlined,
  'Fleisch & Fisch' => Icons.set_meal_outlined,
  'Backwaren' => Icons.bakery_dining_outlined,
  'Kaffee & Snacks' => Icons.local_cafe_outlined,
  'Getränke' => Icons.local_drink_outlined,
  'Tiefkühl' => Icons.ac_unit,
  'Kühlregal' => Icons.kitchen_outlined,
  'Garten & Pflanzen' => Icons.local_florist_outlined,
  'Haushalt' || 'Drogerie' => Icons.cleaning_services_outlined,
  _ => Icons.shopping_bag_outlined,
};
