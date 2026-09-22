import 'package:flutter/material.dart';

import '../../models/offer.dart';
import '../../models/price_point.dart';
import 'offer_card.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({
    super.key,
    required this.offers,
    required this.priceHistory,
  });

  final List<Offer> offers;
  final List<PricePoint> priceHistory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Angebote')),
      body: offers.isEmpty
          ? const Center(child: Text('Noch keine Angebote gespeichert.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: offers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (_, index) => OfferCard(
                offer: offers[index],
                priceHistory: priceHistory,
              ),
            ),
    );
  }
}
