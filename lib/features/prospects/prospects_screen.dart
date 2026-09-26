import 'package:flutter/material.dart';

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
                          Icons.menu_book_outlined,
                          size: 56,
                          color: SparzamTheme.deepGreen,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  issue.storeName + '\n' + issue.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

    return Scaffold(
      appBar: AppBar(title: Text(issue.storeName)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (issue.pages.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Für diesen Markt sind derzeit noch keine Bildseiten '
                  'verfügbar. Die Marktdaten werden automatisch aktualisiert.',
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
              padding: EdgeInsets.only(top: 12, bottom: 6),
              child: Text(
                'Produkte antippen und zur Einkaufsliste hinzufügen',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final record in items)
              Builder(
                builder: (context) {
                  final result = resolveOfferImport(record, catalogProducts);
                  return ListTile(
                    title: Text(record.productLabel),
                    subtitle: result.isResolved
                        ? const Text('Zur Einkaufsliste hinzufügen')
                        : const Text('Noch nicht eindeutig zugeordnet'),
                    trailing: result.isResolved
                        ? const Icon(Icons.add_shopping_cart)
                        : null,
                    onTap: result.isResolved
                        ? () => onAddProduct?.call(result.product!)
                        : null,
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
