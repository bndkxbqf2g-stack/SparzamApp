import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import '../store/store_screen.dart';
import '../price_gaps/price_gap_priority.dart';
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
    this.openPricesMaxAgeDays = 60,
    this.onResolvePriceGap,
  });

  final Offer offer;
  final List<PricePoint> priceHistory;
  final List<ListItem> items;
  final List<Offer> offers;
  final MobilitySettings mobility;
  final List<Product> catalogProducts;
  final List<MarketPrice> marketPrices;
  final int openPricesMaxAgeDays;
  final Future<void> Function(PriceGapPriority gap)? onResolvePriceGap;

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
                      openPricesMaxAgeDays: openPricesMaxAgeDays,
                      onResolvePriceGap: onResolvePriceGap,
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
