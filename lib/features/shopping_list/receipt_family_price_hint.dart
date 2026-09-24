import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import '../receipt/receipt_observation_builder.dart';

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
    final family = inferReceiptFamily(product.name);
    final matches = stats.where((stat) => stat.familyKey == family).toList();
    if (matches.isEmpty) return const SizedBox.shrink();

    matches.sort((a, b) {
      if (a.comparable != b.comparable) return a.comparable ? -1 : 1;
      return a.medianPrice.compareTo(b.medianPrice);
    });
    final best = matches.first;
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
