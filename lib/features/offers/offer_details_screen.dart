import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import 'offer_card.dart';

class OfferDetailsScreen extends StatelessWidget {
  const OfferDetailsScreen({
    super.key,
    required this.offer,
    required this.priceHistory,
  });

  final Offer offer;
  final List<PricePoint> priceHistory;

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
                leading: const Icon(Icons.store_outlined),
                title: Text(store.name),
                subtitle: Text(
                  '${store.location} · ${store.distanceKm.toStringAsFixed(1)} km',
                ),
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
