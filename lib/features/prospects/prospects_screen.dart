import 'package:flutter/material.dart';

import '../../design/sparzam_theme.dart';
import '../offers/offer_import.dart';

class ProspectsScreen extends StatelessWidget {
  const ProspectsScreen({super.key, required this.records});

  final List<OfferImportRecord> records;

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
