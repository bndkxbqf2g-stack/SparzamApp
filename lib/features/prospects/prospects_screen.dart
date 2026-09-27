import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/sparzam_theme.dart';
import '../offers/offer_import.dart';
import '../../models/product.dart';
import '../../services/prospect_feed_service.dart';

class ProspectsScreen extends StatelessWidget {
  const ProspectsScreen({
    super.key,
    required this.records,
    this.prospects = const [],
    this.catalogProducts = const [],
    this.onAddProduct,
  });

  final List<OfferImportRecord> records;
  final List<ProspectIssue> prospects;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final byStore = <String, ProspectIssue>{};
    for (final issue in prospects) {
      byStore.putIfAbsent(issue.storeName, () => issue);
    }
    final visibleProspects = byStore.values.toList(growable: false);

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
        const SizedBox(height: 20),
        if (visibleProspects.isEmpty)
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
          Text(
            'Alle Märkte',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleProspects.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final issue = visibleProspects[index];
                return _ProspectCard(
                  issue: issue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ProspectViewer(
                        issue: issue,
                        records: records,
                        catalogProducts: catalogProducts,
                        onAddProduct: onAddProduct,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
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
                        webHtmlElementStrategy:
                            WebHtmlElementStrategy.prefer,
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
                    Text(
                      issue.recordCount > 0
                          ? '${issue.recordCount} Angebote geladen'
                          : _sourceStatusLabel(issue),
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

String _sourceStatusLabel(ProspectIssue issue) {
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
      groupedItems.putIfAbsent(_prospectCategory(record.productLabel), () => [])
          .add(record);
    }
    final categories = groupedItems.keys.toList()
      ..sort((a, b) => _prospectCategoryOrder(a).compareTo(_prospectCategoryOrder(b)));

    return Scaffold(
      appBar: AppBar(title: Text(issue.storeName)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedItems[category]!.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final record = groupedItems[category]![index];
                  final result = resolveOfferImport(record, catalogProducts);
                  final product = result.product ?? Product(
                    id: '${record.storeName}|${record.sourceId}',
                    name: record.productLabel,
                    unit: 'Stück',
                    group: category,
                  );
                  return _ProspectProductCard(
                    record: record,
                    category: category,
                    onTap: onAddProduct == null ? null : () => onAddProduct!(product),
                  );
                },
              ),
            ],
          ],        ],
      ),
    );
  }
}

const _prospectCategoryRanks = <String, int>{
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
};

int _prospectCategoryOrder(String category) =>
    _prospectCategoryRanks[category] ?? 50;

String _prospectCategory(String label) {
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
  if (RegExp(r'brot|bröt|toast|backwaren|croissant').hasMatch(value)) return 'Backwaren';
  if (RegExp(r'getränk|wasser|saft|cola|bier|wein|kaffee|tee').hasMatch(value)) return 'Getränke';
  if (RegExp(r'tiefkühl|tk |pizza|eis ').hasMatch(value)) return 'Tiefkühl';
  if (RegExp(r'reis|nudel|mehl|zucker|dose|konserve|sauce|öl|gewürz').hasMatch(value)) {
    return 'Vorrat & Konserven';
  }
  if (RegExp(r'seife|shampoo|zahnpasta|deo|waschmittel|reiniger').hasMatch(value)) return 'Drogerie';
  if (RegExp(r'küche|haushalt|müll|papier|lampe|werkzeug|akku|bastel|raum-weiß').hasMatch(value)) return 'Haushalt';
  if (RegExp(r'non-food|bekleidung|schuh|spielzeug|dekoration').hasMatch(value)) return 'Non-Food';
  return 'Weitere Angebote';
}

class _ProspectProductCard extends StatelessWidget {
  const _ProspectProductCard({required this.record, required this.category, required this.onTap});

  final OfferImportRecord record;
  final String category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final oldPrice = record.originalPrice;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: record.imageUrl != null
                        ? Image.network(
                            record.imageUrl!,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(child: Icon(_categoryIcon(category), size: 42)),
                          )
                        : Center(
                            child: Icon(_categoryIcon(category), size: 42),
                          ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      radius: 23,
                      backgroundColor: Colors.green.shade400,
                      child: const Icon(Icons.add, color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.offerPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
                    style: const TextStyle(
                      color: Color(0xffdf5963),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    record.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    record.productLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (oldPrice != null)
                    Text(
                      '${oldPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: const TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
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

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Obst & Gemüse': return Icons.eco_outlined;
    case 'Milchprodukte': return Icons.local_drink_outlined;
    case 'Fleisch & Fisch': return Icons.restaurant_outlined;
    case 'Getränke': return Icons.local_bar_outlined;
    case 'Haushalt': return Icons.home_outlined;
    case 'Drogerie': return Icons.clean_hands_outlined;
    case 'Non-Food': return Icons.shopping_bag_outlined;
    default: return Icons.local_offer_outlined;
  }
}
