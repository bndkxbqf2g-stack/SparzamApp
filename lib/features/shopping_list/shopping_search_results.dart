import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../catalog/product_hierarchy.dart';
import '../../models/recent_purchase.dart';

class ShoppingSearchResults extends StatelessWidget {
  const ShoppingSearchResults({
    super.key,
    required this.query,
    required this.suggestions,
    required this.relatedInterpretations,
    required this.preferredProductByGroup,
    required this.recentPurchases,
    required this.onAdd,
    required this.onAddCustom,
  });

  final String query;
  final List<Product> suggestions;
  final List<Product> relatedInterpretations;
  final Map<String, String> preferredProductByGroup;
  final List<RecentPurchase> recentPurchases;
  final ValueChanged<Product> onAdd;
  final VoidCallback onAddCustom;

  RecentPurchase? _recentPurchase(String productId) {
    for (final purchase in recentPurchases) {
      if (purchase.id == productId) return purchase;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        child: Column(
          children: [
            for (final product in suggestions)
              _productTile(product),
            if (relatedInterpretations.isNotEmpty) ...[
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Weitere Interpretationen',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              for (final product in relatedInterpretations)
                _productTile(product, related: true),
            ],
            ListTile(
              onTap: onAddCustom,
              leading: const CircleAvatar(
                radius: 18,
                child: Icon(Icons.playlist_add),
              ),
              title: Text(
                suggestions.isEmpty
                    ? '„$query“ hinzufügen'
                    : '„$query“ zur Liste hinzufügen',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Noch kein bekanntes Produkt – wird trotzdem gespeichert.',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productTile(Product product, {bool related = false}) {
    final preferred = preferredProductByGroup[product.group] == product.id;
    return ListTile(
      onTap: () => onAdd(product),
      leading: CircleAvatar(
        radius: 18,
        child: Icon(
          related
              ? Icons.alt_route
              : preferred
                  ? Icons.auto_awesome
                  : Icons.add,
          size: 18,
        ),
      ),
      title: Text(
        preferred ? '${product.name} · deine Auswahl' : product.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_subtitle(product)),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  String _subtitle(Product product) {
    final hierarchy = productHierarchyLabel(product).path;
    final purchase = _recentPurchase(product.id);
    if (purchase == null) return '$hierarchy · ${product.unit}';
    final quantity = purchase.averageQuantity.round();
    return quantity > 1
        ? '$hierarchy · ${product.unit} · meist ×$quantity'
        : '$hierarchy · ${product.unit}';
  }
}
