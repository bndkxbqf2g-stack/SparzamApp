import 'package:flutter/material.dart';

import '../../data/products.dart';
import '../../models/offer.dart';
import '../../models/price_point.dart';
import 'cashback_calculator.dart';
import 'coupon_calculator.dart';
import 'effective_price.dart';
import 'price_badge.dart';
import 'price_evaluator.dart';
import 'price_history_sheet.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.priceHistory,
    this.onEdit,
    this.onDelete,
  });

  final Offer offer;
  final List<PricePoint> priceHistory;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final product = products.where((item) => item.id == offer.productId).firstOrNull;
    final history = priceHistory
        .where((p) => p.productId == offer.productId && p.storeName == offer.storeName)
        .toList();
    final price = effectivePrice(offer);
    final evaluation = evaluatePrice(
      offer,
      history,
      currentPrice: price.finalPrice,
    );
    final name = product?.name ?? offer.productId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                _Price(offer: offer, price: price),
                PopupMenuButton<String>(
                  tooltip: 'Angebotsoptionen',
                  onSelected: (value) => value == 'edit' ? onEdit?.call() : onDelete?.call(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                    PopupMenuItem(value: 'delete', child: Text('Löschen')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${offer.storeName} · statt ${offer.originalPrice.toStringAsFixed(2)} €'),
            const SizedBox(height: 10),
            Row(
              children: [
                PriceBadge(level: evaluation.level),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Normal ${evaluation.normalPrice.toStringAsFixed(2)} € · Best ${evaluation.bestPrice.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showPriceHistory(context, name, history),
                icon: const Icon(Icons.show_chart, size: 18),
                label: Text('Preisentwicklung (${history.length})'),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Tag('bis ${_date(offer.validUntil)}'),
                if (offer.hasMultiBuy) _Tag('${offer.buyQuantity} für ${offer.payQuantity}'),
                if (offer.hasCoupon) _Tag(couponLabel(offer)),
                if (offer.hasCashback) _Tag(cashbackLabel(offer)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

class _Price extends StatelessWidget {
  const _Price({required this.offer, required this.price});

  final Offer offer;
  final EffectivePrice price;

  @override
  Widget build(BuildContext context) {
    final discounted = price.finalPrice < offer.offerPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${price.finalPrice.toStringAsFixed(2)} €',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (discounted)
          Text(
            _detail(),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  String _detail() {
    if (price.cashback > 0) {
      return 'effektiv · an Kasse ${price.checkout.toStringAsFixed(2)} €';
    }
    return 'mit Coupon · sonst ${offer.offerPrice.toStringAsFixed(2)} €';
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
