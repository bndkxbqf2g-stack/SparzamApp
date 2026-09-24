import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import 'receipt_product_price_match.dart';

class ReceiptFamilyPriceHint extends StatelessWidget {
  const ReceiptFamilyPriceHint({
    super.key,
    required this.product,
    required this.stats,
  });

  final Product product;
  final List<ReceiptPriceStat> stats;

  @override
  Widget build(BuildContext context) {
    final matches = receiptStatsForProduct(product, stats);
    if (matches.isEmpty) return const SizedBox.shrink();
    matches.sort((a, b) => a.storeName.compareTo(b.storeName));

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: InkWell(
        onTap: () => _showMarketPrices(context, matches),
        child: Text(
          _summary(matches),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  String _summary(List<ReceiptPriceStat> matches) {
    String price(ReceiptPriceStat stat) =>
        stat.medianPrice.toStringAsFixed(2).replaceAll('.', ',');
    if (matches.length == 1) {
      final stat = matches.first;
      final suffix = stat.comparable ? 'Median' : 'historisch, Packung prüfen';
      return '${stat.storeName}: ${price(stat)} € · $suffix · ${stat.observationCount}×';
    }
    final preview = matches.take(2)
        .map((stat) => '${stat.storeName} ${price(stat)} €')
        .join(' · ');
    final more = matches.length > 2 ? ' · +${matches.length - 2} Märkte' : '';
    return '$preview$more ›';
  }

  void _showMarketPrices(BuildContext context, List<ReceiptPriceStat> matches) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Belegte Preise aus deinen Kassenbons nach Markt. Nicht vergleichbare Packungen sind gekennzeichnet.'),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final stat in matches)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(stat.storeName),
                        subtitle: Text(stat.comparable
                            ? '${stat.observationCount} Bonbeobachtung(en) · ${stat.priceBasis}'
                            : '${stat.observationCount} Bonbeobachtung(en) · Packung prüfen'),
                        trailing: Text(
                          '${stat.medianPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
