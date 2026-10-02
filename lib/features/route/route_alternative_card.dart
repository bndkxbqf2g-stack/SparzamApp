import 'package:flutter/material.dart';

import '../../models/route_plan.dart';

class RouteAlternativeCard extends StatelessWidget {
  const RouteAlternativeCard({
    super.key,
    required this.plan,
    required this.travelLabel,
  });

  final RoutePlan plan;
  final String travelLabel;

  @override
  Widget build(BuildContext context) {
    final single = plan.stores.length == 1;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: single
              ? Colors.grey.shade100
              : Colors.orange.shade50,
          child: Icon(
            single ? Icons.storefront : Icons.alt_route,
            color: single ? Colors.black54 : Colors.orange.shade700,
          ),
        ),
        title: Text(
          plan.stores.map((store) => store.name).join(' + '),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${plan.stores.length} ${single ? 'Markt' : 'Märkte'} · '
          '${plan.hasDataGaps ? 'bekannter Teilwarenkorb' : 'Warenkorb'} '
          '${plan.basket.toStringAsFixed(2)} € · '
          'Fahrt ${plan.travel.toStringAsFixed(2)} € · '
          'Wegezeit $travelLabel · '
          'Preisabdeckung ${(plan.priceCoverage * 100).round()} % · '
          '${plan.timeCost > 0 ? 'Zeitwert ${plan.timeCost.toStringAsFixed(2)} € · ' : ''}'
          'Planungswert ${plan.planningScore.toStringAsFixed(2)} €',
        ),
        trailing: Text(
          '${plan.total.toStringAsFixed(2)} €',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
