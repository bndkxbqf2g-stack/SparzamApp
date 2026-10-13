import 'package:flutter/material.dart';

import '../../models/route_plan.dart';

class RouteCostBreakdownCard extends StatelessWidget {
  const RouteCostBreakdownCard({
    super.key,
    required this.plan,
  });

  final RoutePlan plan;

  @override
  Widget build(BuildContext context) {
    String money(double value) =>
        '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kostenaufteilung',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _CostRow(label: 'Warenkorb', value: money(plan.basket)),
            _CostRow(label: 'Fahrt', value: money(plan.travel)),
            const Divider(height: 18),
            _CostRow(
              label: plan.hasDataGaps
                  ? 'Bekannte Gesamtkosten'
                  : 'Erwartete Gesamtkosten',
              value: money(plan.total),
              emphasized: true,
            ),
            if (plan.additionalStoreCost > 0)
              _CostRow(
                label: 'Zusätzliche Marktstopps (Planung)',
                value: money(plan.additionalStoreCost),
              ),
            if (plan.timeCost > 0)
              _CostRow(
                label: 'Zeitwert (Planung)',
                value: money(plan.timeCost),
              ),
            if (plan.uncertaintyReserve > 0)
              _CostRow(
                label: 'Preisunsicherheit (Vergleich)',
                value: money(plan.uncertaintyReserve),
              ),
            if (plan.additionalStoreCost > 0 ||
                plan.timeCost > 0 ||
                plan.uncertaintyReserve > 0) ...[
              const Divider(height: 18),
              _CostRow(
                label: 'Planungswert',
                value: money(plan.planningScore),
                emphasized: true,
              ),
              const SizedBox(height: 4),
              Text(
                'Der Planungswert hilft beim Vergleich. '
                'Zeitwert, Marktstopps und Unsicherheitsreserve sind keine '
                'zusätzlichen Kassenkosten.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
