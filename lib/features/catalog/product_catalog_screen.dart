import 'package:flutter/material.dart';

import '../../data/products.dart' as demo;
import '../../models/market_price.dart';
import '../../models/product.dart';
import 'market_price_editor_screen.dart';
import 'product_editor_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({
    super.key,
    required this.customProducts,
    required this.marketPrices,
    required this.onSaveProduct,
    required this.onDeleteProduct,
    required this.onSavePrice,
    required this.onDeletePrice,
  });

  final List<Product> customProducts;
  final List<MarketPrice> marketPrices;
  final Future<List<Product>> Function(Product product) onSaveProduct;
  final Future<List<Product>> Function(Product product) onDeleteProduct;
  final Future<List<MarketPrice>> Function(MarketPrice price) onSavePrice;
  final Future<List<MarketPrice>> Function(
    String productId,
    String storeName,
  ) onDeletePrice;

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  late List<Product> customProducts;
  late List<MarketPrice> marketPrices;
  String query = '';

  @override
  void initState() {
    super.initState();
    customProducts = [...widget.customProducts];
    marketPrices = [...widget.marketPrices];
  }

  List<Product> get allProducts => [...demo.products, ...customProducts];

  List<Product> get visible {
    final q = query.trim().toLowerCase();
    final items = allProducts.where((product) {
      if (q.isEmpty) return true;
      return [
        product.name,
        product.brand ?? '',
        product.group,
        ...product.aliases,
      ].any((value) => value.toLowerCase().contains(q));
    }).toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  bool isCustom(Product product) =>
      customProducts.any((item) => item.id == product.id);

  Future<void> edit([Product? product]) async {
    final result = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => ProductEditorScreen(product: product),
      ),
    );
    if (result == null) return;

    final duplicateEan = result.ean != null &&
        allProducts.any(
          (item) =>
              item.id != result.id &&
              item.ean != null &&
              item.ean == result.ean,
        );
    if (duplicateEan) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dieser Barcode ist bereits einem Produkt zugeordnet.'),
          ),
        );
      }
      return;
    }

    final next = await widget.onSaveProduct(result);
    if (mounted) setState(() => customProducts = next);
  }

  Future<void> delete(Product product) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Produkt löschen?'),
            content: const Text(
              'Eigene Marktpreise und Angebote für dieses Produkt '
              'werden ebenfalls entfernt.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final next = await widget.onDeleteProduct(product);
    if (mounted) setState(() => customProducts = next);
  }

  Future<void> editPrices(Product product) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MarketPriceEditorScreen(
          product: product,
          prices: marketPrices,
          onSave: (price) async {
            final next = await widget.onSavePrice(price);
            if (mounted) setState(() => marketPrices = next);
            return next;
          },
          onDelete: (productId, storeName) async {
            final next = await widget.onDeletePrice(productId, storeName);
            if (mounted) setState(() => marketPrices = next);
            return next;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Produktkatalog')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: edit,
          icon: const Icon(Icons.add),
          label: const Text('Produkt'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                hintText: 'Produkt, Marke oder Kategorie suchen',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            for (final product in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      product.isFavorite
                          ? Icons.star
                          : Icons.inventory_2_outlined,
                    ),
                    title: Text(product.name),
                    subtitle: Text([
                      if ((product.brand ?? '').isNotEmpty) product.brand!,
                      product.unit,
                      isCustom(product) ? 'Eigenes Produkt' : 'Basisprodukt',
                    ].join(' · ')),
                    onTap: () => editPrices(product),
                    trailing: isCustom(product)
                        ? PopupMenuButton<String>(
                            onSelected: (value) => value == 'edit'
                                ? edit(product)
                                : delete(product),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Bearbeiten'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Löschen'),
                              ),
                            ],
                          )
                        : const Icon(Icons.chevron_right),
                  ),
                ),
              ),
          ],
        ),
      );
}
