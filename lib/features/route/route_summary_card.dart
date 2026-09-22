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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      multi ? Colors.orange.shade50 : Colors.green.shade50,
                  child: Icon(
                    multi ? Icons.alt_route : Icons.check_circle_outline,
                    color: multi
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    multi
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
              '${best.total.toStringAsFixed(2)} € wirtschaftliche Gesamtkosten',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Effektiver Warenkorb ${best.basket.toStringAsFixed(2)} € · '
              'Fahrt ${best.travel.toStringAsFixed(2)} €',
            ),
            if (multi && extraSavings > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Ersparnis gegenüber der günstigsten Einzelroute: '
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
