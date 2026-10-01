import 'package:flutter/material.dart';

import '../../design/sparzam_theme.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import 'offer_import.dart';
import 'prospect_offer_products.dart';
import '../../services/prospect_branch_resolver.dart';
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
      appBar: AppBar(
        title: const Text('Angebote'),
        centerTitle: true,
      ),
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
          Text('Aktuelles Prospekt',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('Es werden ausschließlich aktuell gültige Prospektangebote angezeigt.'),
          const SizedBox(height: 14),
          _ProspectOffers(
            records: currentProspectRecords(widget.prospectRecords, now: widget.now),
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
    required this.query,
    required this.catalogProducts,
    this.onAddToShoppingList,
  });

  final List<OfferImportRecord> records;
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
      final searchable = '${record.storeName} ${record.productLabel}'.toLowerCase();
      if (normalizedQuery.isNotEmpty && !searchable.contains(normalizedQuery)) {
        continue;
      }
      byStore.putIfAbsent(record.storeName, () => []).add(record);
    }

    if (byStore.isEmpty) {
      return const Text('Keine passenden Prospektangebote gefunden.');
    }

    return Column(
      children: [
        for (final entry in byStore.entries)
          ExpansionTile(
            key: PageStorageKey('prospect-store-${entry.key}'),
            initiallyExpanded: false,
            title: Text(entry.key,
                style: const TextStyle(fontWeight: FontWeight.w800)),
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
                            'prospect-category-${entry.key}-${category.key}'),
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
                        children: expandedCategories
                                .contains('${entry.key}|${category.key}')
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
    final product = resolution.product ??
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
                ? Image.network(record.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(_categoryIcon(_offerCategory(record.productLabel))))
                : Icon(_categoryIcon(_offerCategory(record.productLabel))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.productLabel,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${record.offerPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: SparzamTheme.deepGreen,
                            fontWeight: FontWeight.w800,
                          )),
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
    grouped.putIfAbsent(_offerCategory(record.productLabel), () => []).add(record);
  }
  final entries = grouped.entries.toList()
    ..sort((a, b) => _categoryRank(a.key).compareTo(_categoryRank(b.key)));
  return {for (final entry in entries) entry.key: entry.value};
}

String _offerCategory(String label) {
  final value = label.toLowerCase();
  if (RegExp(r'gemüse|salat|tomat|gurk|kartoff|obst|apfel|banane|traube').hasMatch(value)) {
    return 'Obst & Gemüse';
  }
  if (RegExp(r'milch|joghurt|käse|schmand|sahne|quark|butter').hasMatch(value)) {
    return 'Milchprodukte';
  }
  if (RegExp(r'hack|fleisch|wurst|schinken|fisch|lachs|hähnchen').hasMatch(value)) {
    return 'Fleisch & Fisch';
  }
  if (RegExp(r'brot|bröt|toast|backwaren|croissant').hasMatch(value)) {
    return 'Backwaren';
  }
  if (RegExp(r'getränk|wasser|saft|cola|bier|wein|kaffee|tee').hasMatch(value)) {
    return 'Getränke';
  }
  if (RegExp(r'tiefkühl|tk |pizza|eis ').hasMatch(value)) return 'Tiefkühl';
  if (RegExp(r'reis|nudel|mehl|zucker|dose|konserve|sauce|öl|gewürz').hasMatch(value)) {
    return 'Vorrat & Konserven';
  }
  if (RegExp(r'seife|shampoo|zahnpasta|deo|waschmittel|reiniger').hasMatch(value)) {
    return 'Drogerie';
  }
  if (RegExp(r'küche|haushalt|müll|papier|lampe|werkzeug|akku|bastel|raum-weiß').hasMatch(value)) {
    return 'Haushalt';
  }
  if (RegExp(r'non-food|bekleidung|schuh|spielzeug|dekoration').hasMatch(value)) {
    return 'Non-Food';
  }
  return 'Weitere Angebote';
}

int _categoryRank(String category) => const {
      'Obst & Gemüse': 0,
      'Milchprodukte': 1,
      'Fleisch & Fisch': 2,
      'Backwaren': 3,
      'Getränke': 4,
      'Vorrat & Konserven': 5,
      'Tiefkühl': 6,
      'Haushalt': 20,
      'Drogerie': 21,
      'Non-Food': 30,
      'Weitere Angebote': 40,
    }[category] ?? 50;

IconData _categoryIcon(String category) => switch (category) {
      'Obst & Gemüse' => Icons.eco_outlined,
      'Milchprodukte' => Icons.egg_alt_outlined,
      'Fleisch & Fisch' => Icons.set_meal_outlined,
      'Backwaren' => Icons.bakery_dining_outlined,
      'Getränke' => Icons.local_drink_outlined,
      'Tiefkühl' => Icons.ac_unit,
      'Haushalt' || 'Drogerie' => Icons.cleaning_services_outlined,
      _ => Icons.shopping_bag_outlined,
    };
