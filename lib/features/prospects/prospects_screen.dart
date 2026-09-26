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
                child: Text(
                  '${issue.storeName}\\n${issue.title}',
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
                    if (issue.url != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(issue.url!),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Offiziellen Prospekt öffnen'),
                      ),
                    ],
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) {
                final record = items[index];
                final result = resolveOfferImport(record, catalogProducts);
                final product = result.product ??
                    Product(
                      id: 'prospect|' + record.storeName + '|' + record.sourceId,
                      name: record.productLabel,
                      unit: 'Stück',
                      group: 'Sonstiges',
                    );
                return _ProspectProductCard(
                  record: record,
                  onTap: onAddProduct == null
                      ? null
                      : () => onAddProduct!(product),
                );
              },
            ),
          ],        ],
      ),
    );
  }
}


class _ProspectProductCard extends StatelessWidget {
  const _ProspectProductCard({required this.record, required this.onTap});

  final OfferImportRecord record;
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
                                const Center(
                              child: Icon(Icons.local_offer_outlined, size: 42),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.local_offer_outlined, size: 42),
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

String _offerPriceLabel(OfferImportRecord record) {
  final offer = record.offerPrice.toStringAsFixed(2).replaceAll('.', ',');
  final regular = record.originalPrice;
  if (regular != null) {
    final normal = regular.toStringAsFixed(2).replaceAll('.', ',');
    return 'Angebot $offer € · Normalpreis $normal €';
  }
  return 'Angebot $offer €';
}
