import 'package:flutter/material.dart';

import 'route_price_evidence.dart';

class RoutePriceEvidenceCard extends StatelessWidget {
  const RoutePriceEvidenceCard({super.key, required this.summary});

  final RoutePriceEvidenceSummary summary;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasEvidence) return const SizedBox.shrink();

    final chips = <Widget>[
      if (summary.offers > 0)
        _EvidenceChip(
          icon: Icons.local_offer_outlined,
          label: '${summary.offers} aktive Angebote',
          color: Colors.green,
        ),
      if (summary.receipts > 0)
        _EvidenceChip(
          icon: Icons.receipt_long_outlined,
          label: '${summary.receipts} Bonpreise',
          color: Colors.blue,
        ),
      if (summary.ownPrices > 0)
        _EvidenceChip(
          icon: Icons.edit_note_outlined,
          label: '${summary.ownPrices} eigene Preise',
          color: Colors.indigo,
        ),
      if (summary.openPrices > 0)
        _EvidenceChip(
          icon: Icons.public_outlined,
          label: '${summary.openPrices} Open Prices',
          color: Colors.teal,
        ),
      if (summary.undocumented > 0)
        _EvidenceChip(
          icon: Icons.help_outline,
          label: '${summary.undocumented} ohne Quellenstand',
          color: Colors.orange,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Preisgrundlage dieser Route',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.pricedPositions} bepreiste '
              '${summary.pricedPositions == 1 ? 'Position' : 'Positionen'} · '
              'Quelle und Preisstand bleiben je Artikel sichtbar.',
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
            if (summary.oldestObservation != null) ...[
              const SizedBox(height: 10),
              Text(
                'Ältester beobachteter Preisstand: '
                '${_date(summary.oldestObservation!)} · '
                'Qualität wird für knappe Preisvergleiche berücksichtigt.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (summary.undocumented > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Preise ohne dokumentierten Quellenstand bleiben sichtbar, '
                'werden aber nicht als aktuelle Bon- oder Prospektbelege ausgegeben.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}

class _EvidenceChip extends StatelessWidget {
  const _EvidenceChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18, color: color.shade700),
    label: Text(label),
    backgroundColor: color.shade50,
    side: BorderSide(color: color.shade100),
  );
}
