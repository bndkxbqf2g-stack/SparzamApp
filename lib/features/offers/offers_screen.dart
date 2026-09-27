import 'package:flutter/material.dart';

import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import 'offer_import.dart';
import 'offer_card.dart';
import 'offer_editor_screen.dart';
import 'offer_filter.dart';
import 'offer_filter_bar.dart';
import 'official_offer_links.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({
    super.key,
    required this.offers,
    required this.priceHistory,
    required this.onSave,
    required this.onDelete,
    required this.catalogProducts,
    this.prospectRecords = const [],
    this.onAddToShoppingList,
  });

  final List<Offer> offers;
  final List<PricePoint> priceHistory;
  final Future<List<Offer>> Function(Offer offer) onSave;
  final Future<List<Offer>> Function(Offer offer) onDelete;
  final List<Product> catalogProducts;
  final List<OfferImportRecord> prospectRecords;
  final ValueChanged<Product>? onAddToShoppingList;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final searchController = TextEditingController();
  late List<Offer> offers;
  var filter = OfferStatusFilter.active;
  var query = '';
  var busy = false;

  @override
  void initState() {
    super.initState();
    offers = [...widget.offers];
  }

  @override
  void didUpdateWidget(covariant OffersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offers != widget.offers) {
      offers = [...widget.offers];
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _edit([Offer? offer]) async {
    if (busy || widget.catalogProducts.isEmpty) return;
    setState(() => busy = true);
    try {
      final result = await Navigator.of(context).push<Offer>(
        MaterialPageRoute(
          builder: (_) => OfferEditorScreen(
            offer: offer,
            catalogProducts: widget.catalogProducts,
          ),
        ),
      );
      if (!mounted || result == null) return;
      final next = await widget.onSave(result);
      if (mounted) setState(() => offers = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angebot konnte nicht gespeichert werden.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _delete(Offer offer) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Angebot löschen?'),
            content: const Text('Das Angebot wird dauerhaft aus der App entfernt.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ??
        false;
      if (!mounted || !confirmed) return;

      final next = await widget.onDelete(offer);
      if (mounted) setState(() => offers = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angebot konnte nicht gelöscht werden.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = filterOffers(
      offers,
      status: filter,
      query: query,
      catalogProducts: widget.catalogProducts,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Angebote'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy || widget.catalogProducts.isEmpty ? null : _edit,
        icon: const Icon(Icons.add),
        label: const Text('Angebot'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const Center(child: Text('Die besten Preise. Für dich.')),
          const SizedBox(height: 18),
          OfferFilterBar(
            controller: searchController,
            filter: filter,
            onQueryChanged: (value) => setState(() => query = value),
            onFilterChanged: (value) => setState(() => filter = value),
          ),
          const SizedBox(height: 18),
          const OfficialOfferLinks(),
          const SizedBox(height: 26),
          if (widget.prospectRecords.isNotEmpty) ...[
            Text('Prospektangebote nach Markt',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Lebensmittel stehen zuerst und sind sinnvoll gruppiert.'),
            const SizedBox(height: 14),
            _ProspectOffers(
              records: widget.prospectRecords,
              query: query,
              catalogProducts: widget.catalogProducts,
              onAddToShoppingList: widget.onAddToShoppingList,
            ),
            const SizedBox(height: 26),
          ],
          Text('${visible.length} gespeicherte Angebote',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('Bei einer Neuinstallation sind drei Beispielangebote enthalten.'),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            _EmptyOffers(filter: filter, hasQuery: query.trim().isNotEmpty)
          else
            for (var index = 0; index < visible.length; index++) ...[
              OfferCard(
                offer: visible[index],
                priceHistory: widget.priceHistory,
                catalogProducts: widget.catalogProducts,
                onEdit: busy ? null : () => _edit(visible[index]),
                onDelete: busy ? null : () => _delete(visible[index]),
                onAddToShoppingList: widget.onAddToShoppingList,
              ),
              if (index < visible.length - 1) const SizedBox(height: 10),
            ],

        ],
      ),
    );
  }
}

class _ProspectOffers extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final byStore = <String, List<OfferImportRecord>>{};
    for (final record in records) {
      if (record.validUntil.isBefore(DateTime.now())) continue;
      final searchable = '${record.storeName} ${record.productLabel}'.toLowerCase();
      if (normalizedQuery.isNotEmpty && !searchable.contains(normalizedQuery)) continue;
      byStore.putIfAbsent(record.storeName, () => []).add(record);
    }

    if (byStore.isEmpty) {
      return const Text('Keine passenden Prospektangebote gefunden.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in byStore.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(entry.key,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
          ),
          ..._grouped(entry.value).entries.expand((category) => [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 6),
                  child: Text(category.key,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                ),
                for (final record in category.value)
                  _ProspectOfferCard(
                    record: record,
                    catalogProducts: catalogProducts,
                    onAddToShoppingList: onAddToShoppingList,
                  ),
                const SizedBox(height: 8),
              ]),
          const SizedBox(height: 8),
        ],
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
    final product = resolveOfferImport(record, catalogProducts).product;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: record.imageUrl?.isNotEmpty == true
                ? Image.network(record.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(_categoryIcon(_offerCategory(record.productLabel))))
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
              onPressed: product == null ? null : () => onAddToShoppingList!(product),
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
  if (RegExp(r'gemüse|salat|tomat|gurk|kartoff|obst|apfel|banane|traube').hasMatch(value)) return 'Obst & Gemüse';
  if (RegExp(r'milch|joghurt|käse|schmand|sahne|quark|butter').hasMatch(value)) return 'Milchprodukte';
  if (RegExp(r'hack|fleisch|wurst|schinken|fisch|lachs|hähnchen').hasMatch(value)) return 'Fleisch & Fisch';
  if (RegExp(r'brot|bröt|toast|backwaren|croissant').hasMatch(value)) return 'Backwaren';
  if (RegExp(r'getränk|wasser|saft|cola|bier|wein|kaffee|tee').hasMatch(value)) return 'Getränke';
  if (RegExp(r'tiefkühl|tk |pizza|eis ').hasMatch(value)) return 'Tiefkühl';
  if (RegExp(r'reis|nudel|mehl|zucker|dose|konserve|sauce|öl|gewürz').hasMatch(value)) return 'Vorrat & Konserven';
  if (RegExp(r'seife|shampoo|zahnpasta|deo|waschmittel|reiniger').hasMatch(value)) return 'Drogerie';
  if (RegExp(r'küche|haushalt|müll|papier|lampe|werkzeug|akku|bastel|raum-weiß').hasMatch(value)) return 'Haushalt';
  if (RegExp(r'non-food|bekleidung|schuh|spielzeug|dekoration').hasMatch(value)) return 'Non-Food';
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

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers({required this.filter, required this.hasQuery});

  final OfferStatusFilter filter;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final text = hasQuery
        ? 'Keine passenden Angebote gefunden.'
        : switch (filter) {
            OfferStatusFilter.active => 'Keine aktiven Angebote.',
            OfferStatusFilter.expired => 'Keine abgelaufenen Angebote.',
            OfferStatusFilter.all => 'Noch keine Angebote gespeichert.',
          };

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(child: Text(text)),
    );
  }
}
