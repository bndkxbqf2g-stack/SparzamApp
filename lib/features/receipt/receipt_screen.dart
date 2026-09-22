import 'package:flutter/material.dart';

import '../../models/purchase_record.dart';
import '../../models/route_plan.dart';
import 'purchase_history_card.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({
    super.key,
    required this.plan,
    required this.baselineTotal,
    required this.history,
    required this.onComplete,
  });

  final RoutePlan? plan;
  final double baselineTotal;
  final List<PurchaseRecord> history;
  final Future<void> Function() onComplete;

  String euro(double value) => '${value.toStringAsFixed(2)} €';

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('Einkauf abschließen', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (plan == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Fülle zuerst deine Einkaufsliste. Danach kannst du den berechneten Einkauf hier bestätigen.'),
              ),
            )
          else
            _CheckoutCard(
              plan: plan!,
              baselineTotal: baselineTotal,
              onComplete: onComplete,
            ),
          const SizedBox(height: 22),
          Text('Letzte Einkäufe', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text('Noch kein bestätigter Einkauf.')
          else
            ...history.take(10).map((record) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PurchaseHistoryCard(record: record),
                )),
        ],
      );
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({required this.plan, required this.baselineTotal, required this.onComplete});

  final RoutePlan plan;
  final double baselineTotal;
  final Future<void> Function() onComplete;

  String euro(double value) => '${value.toStringAsFixed(2)} €';

  @override
  Widget build(BuildContext context) {
    final savings = (baselineTotal - plan.total).clamp(0.0, double.infinity).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.stores.map((store) => store.name).join(' + '), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('Warenkorb: ${euro(plan.basket)}'),
            Text('Fahrt: ${euro(plan.travel)}'),
            Text('Gesamt: ${euro(plan.total)}', style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('Ersparnis: ${euro(savings)}'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await onComplete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Einkauf gespeichert.')));
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Einkauf bestätigen'),
            ),
          ],
        ),
      ),
    );
  }
}
