import 'package:flutter/material.dart';

import 'price_evaluator.dart';

class PriceBadge extends StatelessWidget {
  const PriceBadge({super.key, required this.level});
  final PriceLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      PriceLevel.great => ('Sehr günstig', Colors.green),
      PriceLevel.normal => ('Normal', Colors.amber.shade800),
      PriceLevel.expensive => ('Teuer', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
