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
    this.recommendedProductId,
    this.priceHintFor,
    required this.onAdd,
    required this.onAddCustom,
  });

  final String query;
  final List<Product> suggestions;
  final List<Product> relatedInterpretations;
  final Map<String, String> preferredProductByGroup;
  final List<RecentPurchase> recentPurchases;
  final String? recommendedProductId;
  final String? Function(Product product)? priceHintFor;
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
            for (final product in suggestions) _productTile(product),
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
    final recommended = !related && recommendedProductId == product.id;
    final labels = <String>[
      if (preferred) 'deine Auswahl',
      if (recommended) 'Empfehlung',
    ];
    return ListTile(
      onTap: () => onAdd(product),
      leading: _ProductSuggestionImage(product: product, related: related),
      title: Text(
        labels.isEmpty
            ? product.name
            : '${product.name} · ${labels.join(' · ')}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_subtitle(product)),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  String _subtitle(Product product) {
    final hierarchy = productHierarchyLabel(product).path;
    final purchase = _recentPurchase(product.id);
    final parts = <String>['$hierarchy · ${product.unit}'];
    if (product.id.startsWith('receipt_suggestion_')) {
      parts.add('Früher gekauft · Sorte und Packung prüfen');
    }
    if (purchase != null && purchase.averageQuantity.round() > 1) {
      parts.add('meist ×${purchase.averageQuantity.round()}');
    }
    final price = priceHintFor?.call(product);
    if (price != null) parts.add(price);
    return parts.join(' · ');
  }
}

class _ProductSuggestionImage extends StatelessWidget {
  const _ProductSuggestionImage({required this.product, required this.related});

  final Product product;
  final bool related;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: 22,
        child: Icon(related ? Icons.alt_route : Icons.add, size: 18),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }
}
