import 'package:flutter/material.dart';

import '../../design/sparzam_theme.dart';
import '../offers/offer_import.dart';
import '../../models/product.dart';
import '../../services/prospect_feed_service.dart';

class ProspectsScreen extends StatelessWidget {
  const ProspectsScreen({super.key, required this.records, this.prospects = const [], this.catalogProducts = const [], this.onAddProduct});

  final List<OfferImportRecord> records;
  final List<ProspectIssue> prospects;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final today = _day(DateTime.now());
    final active = records
        .where((record) => !_day(record.validUntil).isBefore(today))
        .toList(growable: false)
      ..sort((a, b) {
        final store = a.storeName.compareTo(b.storeName);
        return store != 0 ? store : a.productLabel.compareTo(b.productLabel);
      });

    final grouped = <String, List<OfferImportRecord>>{};
    for (final record in active) {
      grouped.putIfAbsent(record.storeName, () => []).add(record);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        const Icon(Icons.menu_book_outlined,
            color: SparzamTheme.deepGreen, size: 28),
        const SizedBox(height: 8),
        Text('Prospekte',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        const Center(child: Text('Aktuelle Prospektpreise. Automatisch gelesen.')),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined,
                    color: SparzamTheme.deepGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${active.length} aktuelle Prospektartikel aus ${grouped.length} Märkten',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (prospects.isNotEmpty) ...[
          Text('Aktuelle Prospekte', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prospects.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _ProspectCard(issue: prospects[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ProspectViewer(issue: prospects[index], records: active, catalogProducts: catalogProducts, onAddProduct: onAddProduct)))),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (active.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Noch keine aktuellen Prospektdaten geladen.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final entry in grouped.entries) ...[
            Card(
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text('${entry.key} · ${entry.value.length}'),
                children: [
                  for (var index = 0; index < entry.value.length; index++) ...[
                    _ProspectRow(record: entry.value[index]),
                    if (index < entry.value.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
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
  Widget build(BuildContext context) => SizedBox(width: 250, child: Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Image.network(issue.thumbnailUrl ?? issue.pages.first.imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, _, _) => const Icon(Icons.menu_book, size: 56))), Padding(padding: const EdgeInsets.all(12), child: Text('${issue.storeName}\n${issue.title}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)))]))));
}

class _ProspectViewer extends StatelessWidget {
  const _ProspectViewer({required this.issue, required this.records, required this.catalogProducts, this.onAddProduct});
  final ProspectIssue issue;
  final List<OfferImportRecord> records;
  final List<Product> catalogProducts;
  final ValueChanged<Product>? onAddProduct;
  @override
  Widget build(BuildContext context) {
    final items = records.where((r) => r.storeName == issue.storeName).toList();
    return Scaffold(appBar: AppBar(title: Text(issue.storeName)), body: ListView(padding: const EdgeInsets.all(12), children: [for (final page in issue.pages) Card(clipBehavior: Clip.antiAlias, child: Column(children: [Image.network(page.zoomUrl ?? page.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox(height: 180, child: Icon(Icons.broken_image)),), Padding(padding: const EdgeInsets.all(8), child: Text('Seite ${page.number}'))])), if (items.isNotEmpty) ...[const Padding(padding: EdgeInsets.only(top: 12, bottom: 6), child: Text('Erkannte Produkte antippen und zur Einkaufsliste hinzufügen', style: TextStyle(fontWeight: FontWeight.w700))), for (final record in items) Builder(builder: (context) { final result = resolveOfferImport(record, catalogProducts); return ListTile(title: Text(record.productLabel), subtitle: result.isResolved ? const Text('Zur Einkaufsliste hinzufügen') : const Text('Noch nicht eindeutig im Katalog zugeordnet'), trailing: result.isResolved ? const Icon(Icons.add_shopping_cart) : null, onTap: result.isResolved ? () => onAddProduct?.call(result.product!) : null); })]]));
  }
}

class _ProspectRow extends StatelessWidget {
  const _ProspectRow({required this.record});

  final OfferImportRecord record;

  @override
  Widget build(BuildContext context) {
    final from = record.validFrom;
    final validity = from == null
        ? 'bis ${_date(record.validUntil)}'
        : '${_date(from)}–${_date(record.validUntil)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.productLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(validity, style: Theme.of(context).textTheme.bodySmall),
                if (record.originalPrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Normalpreis ${record.originalPrice!.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${record.offerPrice.toStringAsFixed(2)} €',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SparzamTheme.deepGreen,
                ),
          ),
        ],
      ),
    );
  }
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.';
