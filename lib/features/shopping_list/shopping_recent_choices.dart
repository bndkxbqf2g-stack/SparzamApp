import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/recent_purchase.dart';

class ShoppingRecentChoices extends StatelessWidget {
  const ShoppingRecentChoices({
    super.key,
    required this.recentPurchases,
    required this.quickProducts,
    required this.onAddRecent,
    required this.onAddProduct,
  });

  final List<RecentPurchase> recentPurchases;
  final List<Product> quickProducts;
  final ValueChanged<RecentPurchase> onAddRecent;
  final ValueChanged<Product> onAddProduct;

  @override
  Widget build(BuildContext context) {
    if (recentPurchases.isNotEmpty) {
      return _ChoiceSection(
        title: 'Zuletzt gekauft',
        height: 48,
        children: [
          for (final purchase in recentPurchases)
            ActionChip(
              onPressed: () => onAddRecent(purchase),
              avatar: const Icon(Icons.history, size: 18),
              label: Text(
                purchase.averageQuantity > 1.5
                    ? '${purchase.name} · meist ×${purchase.averageQuantity.round()}'
                    : purchase.name,
              ),
            ),
        ],
      );
    }
    if (quickProducts.isEmpty) return const SizedBox.shrink();

    return _ChoiceSection(
      title: 'Schnell hinzufügen',
      height: 44,
      children: [
        for (final product in quickProducts)
          ActionChip(
            onPressed: () => onAddProduct(product),
            avatar: const Icon(Icons.add, size: 18),
            label: Text(product.name),
          ),
      ],
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.height,
    required this.children,
  });

  final String title;
  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) => children[index],
            ),
          ),
        ],
      );
}
