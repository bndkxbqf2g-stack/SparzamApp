import 'package:flutter/material.dart';

import 'shopping_offer_hint.dart';

class ShoppingOfferBadge extends StatelessWidget {
  const ShoppingOfferBadge({super.key, required this.hint});

  final ShoppingOfferHint hint;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${hint.storeName}: ${hint.unitPrice.toStringAsFixed(2)} €'
          '${hint.savings > 0 ? ' · spare ${hint.savings.toStringAsFixed(2)} €' : ''}',
          style: TextStyle(
            color: Colors.green.shade800,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
