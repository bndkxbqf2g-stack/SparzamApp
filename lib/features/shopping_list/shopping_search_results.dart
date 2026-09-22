import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/recent_purchase.dart';

class ShoppingSearchResults extends StatelessWidget {
  const ShoppingSearchResults({
    super.key,
    required this.query,
    required this.suggestions,
    required this.preferredProductByGroup,
    required this.recentPurchases,
    required this.onAdd,
    required this.onAddCustom,
  });

  final String query;
  final List<Product> suggestions;
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
              ListTile(
                onTap: () => onAdd(product),
                leading: CircleAvatar(
                  radius: 18,
                  child: Icon(
                    preferredProductByGroup[product.group] == product.id
                        ? Icons.auto_awesome
                        : Icons.add,
                    size: 18,
                  ),
                ),
                title: Text(
                  preferredProductByGroup[product.group] == product.id
                      ? '${product.name} · deine Auswahl'
                      : product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(_subtitle(product)),
                trailing: const Icon(Icons.chevron_right),
              ),
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

  String _subtitle(Product product) {
    final purchase = _recentPurchase(product.id);
    if (purchase == null) return product.unit;
    final quantity = purchase.averageQuantity.round();
    return quantity > 1
        ? '${product.unit} · meist ×$quantity'
        : product.unit;
  }
}
