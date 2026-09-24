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
    final best = preferredReceiptStatForProduct(product, stats);
    if (best == null) return const SizedBox.shrink();
    final price = best.medianPrice.toStringAsFixed(2).replaceAll('.', ',');
    final suffix = best.comparable ? 'Median' : 'historisch, Packung prüfen';

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '${best.storeName}: $price € · $suffix · ${best.observationCount}×',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
