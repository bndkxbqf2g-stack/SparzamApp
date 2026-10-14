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
    final matches = receiptHintsForProduct(product, stats);
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
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _summary(List<ReceiptPriceStat> matches) {
    String price(ReceiptPriceStat stat) =>
        stat.medianPrice.toStringAsFixed(2).replaceAll('.', ',');
    final confirmed = matches.where((stat) => stat.identityConfirmed).length;
    final provisional = matches.length - confirmed;

    if (matches.length == 1) {
      final stat = matches.first;
      final date = _date(stat.latestAt);
      final label = stat.identityConfirmed
          ? (stat.comparable ? 'Bon-Median (historisch)' : 'Bonpreis historisch')
          : 'Bon-Hinweis · Variante prüfen';
      return '${stat.storeName}: ${price(stat)} € · $label · '
          '${stat.observationCount}× · Stand $date';
    }

    final preview = matches
        .take(2)
        .map((stat) => '${stat.storeName} ${price(stat)} €')
        .join(' · ');
    final more = matches.length > 2 ? ' · +${matches.length - 2} Märkte' : '';
    final status = provisional == 0
        ? 'Bon-Mediane (historisch)'
        : '$confirmed bestätigt · $provisional Hinweis';
    return '$preview · $status$more ›';
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

  void _showMarketPrices(BuildContext context, List<ReceiptPriceStat> matches) {
    final confirmed = matches.where((stat) => stat.identityConfirmed).length;
    final provisional = matches.length - confirmed;
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
              Text(
                '$confirmed bestätigt · $provisional unbestätigte Hinweise. '
                'Unbestätigte Varianten werden nicht für die Route verwendet.',
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final stat in matches)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          stat.identityConfirmed
                              ? stat.storeName
                              : '${stat.storeName} · Variante prüfen',
                        ),
                        subtitle: Text(
                          stat.identityConfirmed
                              ? (stat.comparable
                                  ? '${stat.observationCount} Bonbeobachtung(en) · ${stat.priceBasis}'
                                  : '${stat.observationCount} Bonbeobachtung(en) · Packung prüfen')
                              : '${stat.observationCount} Bonbeobachtung(en) · '
                                  'automatische Zuordnung, nicht routenfähig',
                        ),
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
