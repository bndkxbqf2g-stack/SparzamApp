import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import '../store/store_screen.dart';
import 'offer_card.dart';

class OfferDetailsScreen extends StatelessWidget {
  const OfferDetailsScreen({
    super.key,
    required this.offer,
    required this.priceHistory,
    required this.items,
    required this.offers,
    required this.mobility,
    required this.catalogProducts,
    required this.marketPrices,
  });

  final Offer offer;
  final List<PricePoint> priceHistory;
  final List<ListItem> items;
  final List<Offer> offers;
  final MobilitySettings mobility;
  final List<Product> catalogProducts;
  final List<MarketPrice> marketPrices;

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
            catalogProducts: catalogProducts,
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
                      mobility: mobility,
                      marketPrices: marketPrices,
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
