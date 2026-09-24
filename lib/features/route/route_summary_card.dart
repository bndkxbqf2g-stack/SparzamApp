import 'package:flutter/material.dart';

import '../../models/route_plan.dart';

class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    super.key,
    required this.best,
    required this.extraSavings,
  });

  final RoutePlan best;
  final double extraSavings;

  @override
  Widget build(BuildContext context) {
    final multi = best.stores.length > 1;
    final complete = !best.hasDataGaps;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: !complete
                      ? Colors.amber.shade50
                      : multi ? Colors.orange.shade50 : Colors.green.shade50,
                  child: Icon(
                    !complete
                        ? Icons.info_outline
                        : multi ? Icons.alt_route : Icons.check_circle_outline,
                    color: !complete
                        ? Colors.amber.shade800
                        : multi ? Colors.orange.shade700 : Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    !complete
                        ? 'Vorläufige Teilroute'
                        : multi
                            ? 'Wirtschaftlich sinnvoll: mehrere Märkte'
                            : 'Wirtschaftlich sinnvoll: ein Markt',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              best.stores
                  .map((store) => '${store.name} · ${store.location}')
                  .join(' + '),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              complete
                  ? '${best.total.toStringAsFixed(2)} € erwartete Gesamtkosten'
                  : '${best.total.toStringAsFixed(2)} € bekannte Teilkosten',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Effektiver Warenkorb ${best.basket.toStringAsFixed(2)} € · '
              'Fahrt ${best.travel.toStringAsFixed(2)} €',
            ),
            if (best.hasDataGaps) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${best.pricedItemCount} von ${best.totalItemCount} Artikeln '
                  'preislich belegt. Noch ohne belastbaren Preis: '
                  '${best.unassigned.map((item) => item.product.name).join(', ')}. '
                  'Die angezeigten Kosten enthalten diese Artikel nicht.',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (best.uncertaintyReserve > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Preisunsicherheit: ${best.uncertaintyReserve.toStringAsFixed(2)} € '
                'Rechenaufschlag nur für den Vergleich, keine zusätzlichen Kosten.',
              ),
            ],
            if (multi && extraSavings > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Planungsvorteil gegenüber der besten Einzelroute: '
                '${extraSavings.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
