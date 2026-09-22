import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../store/store_screen.dart';
import 'offer_card.dart';

class OfferDetailsScreen extends StatelessWidget {
  const OfferDetailsScreen({
    super.key,
    required this.offer,
    required this.priceHistory,
    required this.items,
    required this.offers,
  });

  final Offer offer;
  final List<PricePoint> priceHistory;
  final List<ListItem> items;
  final List<Offer> offers;

  @override
  Widget build(BuildContext context) {
    final store = stores.where((item) => item.name == offer.storeName).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Angebotsdetails')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OfferCard(
            offer: offer,
            priceHistory: priceHistory,
          ),
          if (store != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StoreScreen(
                      store: store,
                      items: items,
                      offers: offers,
                    ),
                  ),
                ),
                leading: const Icon(Icons.store_outlined),
                title: Text(store.name),
                subtitle: Text(
                  '${store.location} · ${store.distanceKm.toStringAsFixed(1)} km',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
