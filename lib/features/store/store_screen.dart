import 'package:flutter/material.dart';

import '../../models/list_item.dart';
import '../../models/offer.dart';
import '../../models/store.dart';
import 'store_shopping_summary.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({
    super.key,
    required this.store,
    required this.items,
    required this.offers,
  });

  final Store store;
  final List<ListItem> items;
  final List<Offer> offers;

  @override
  Widget build(BuildContext context) {
    final summary = buildStoreShoppingSummary(store, items, offers);

    return Scaffold(
      appBar: AppBar(title: Text(store.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${store.location} · ${store.distanceKm.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${summary.total.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    summary.savings > 0
                        ? 'Für deine Liste · spare ${summary.savings.toStringAsFixed(2)} €'
                        : 'Für deine Liste',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Deine Artikel in diesem Markt',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          if (summary.lines.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Für deine aktuelle Liste sind hier keine Preise hinterlegt.'),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < summary.lines.length; index++) ...[
                    _StoreLine(line: summary.lines[index]),
                    if (index < summary.lines.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreLine extends StatelessWidget {
  const _StoreLine({required this.line});

  final StoreShoppingLine line;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(
          line.usesOffer ? Icons.local_offer_outlined : Icons.shopping_bag_outlined,
        ),
        title: Text(
          line.item.product.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          line.item.quantity > 1
              ? '${line.item.product.unit} · ×${line.item.quantity}'
              : line.item.product.unit,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${line.total.toStringAsFixed(2)} €',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (line.usesOffer)
              Text(
                'Angebot · -${line.savings.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Text(
                '${line.unitPrice.toStringAsFixed(2)} € / Einheit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      );
}
