import 'package:flutter/material.dart';

import '../../models/list_item.dart';
import '../../models/store.dart';
import 'route_price_resolver.dart';

class RouteStoreCard extends StatelessWidget {
  const RouteStoreCard({
    super.key,
    required this.store,
    required this.items,
    required this.prices,
  });

  final Store store;
  final List<ListItem> items;
  final RoutePriceResolver prices;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + (prices.quote(store, item)?.total ?? 0),
    );

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              store.isBigShop ? Colors.orange.shade50 : Colors.blue.shade50,
          child: Icon(
            store.isBigShop ? Icons.local_mall : Icons.storefront,
            color:
                store.isBigShop ? Colors.orange.shade700 : Colors.blue.shade700,
          ),
        ),
        title: Text(
          '${store.name} · ${store.location}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${items.length} Artikel · ${total.toStringAsFixed(2)} €'),
        children: [
          for (final item in items) _RouteItemTile(store, item, prices),
        ],
      ),
    );
  }
}

class _RouteItemTile extends StatelessWidget {
  const _RouteItemTile(this.store, this.item, this.prices);

  final Store store;
  final ListItem item;
  final RoutePriceResolver prices;

  @override
  Widget build(BuildContext context) {
    final quote = prices.quote(store, item)!;
    return ListTile(
      dense: true,
      title: Text(item.product.name),
      subtitle: Text(
        '${item.product.unit}${item.quantity > 1 ? ' · ×${item.quantity}' : ''}'
        '${quote.usesOffer ? ' · Angebot eingerechnet' : ''}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${quote.total.toStringAsFixed(2)} €',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (quote.usesOffer)
            Text(
              '-${quote.savings.toStringAsFixed(2)} €',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
