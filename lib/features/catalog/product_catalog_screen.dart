import 'package:flutter/material.dart';

import '../../data/products.dart' as demo;
import '../../models/market_price.dart';
import '../../models/product.dart';
import '../../models/price_data_settings.dart';
import '../../models/price_sync_result.dart';
import 'price_coverage.dart';
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
    required this.priceDataSettings,
    required this.onSyncOpenPrices,
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
  final PriceDataSettings priceDataSettings;
  final Future<PriceSyncResult> Function({
    void Function(int processed, int total)? onProgress,
    bool Function()? shouldCancel,
  }) onSyncOpenPrices;

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  late List<Product> customProducts;
  late List<MarketPrice> marketPrices;
  String query = '';
  bool syncing = false;
  bool autoSyncTriggered = false;
  String? syncFeedback;
  String? syncProgress;
  bool cancelRequested = false;

  @override
  void initState() {
    super.initState();
    customProducts = [...widget.customProducts];
    marketPrices = [...widget.marketPrices];

    if (widget.priceDataSettings.openPricesEnabled &&
        widget.priceDataSettings.autoSyncOnCatalogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !autoSyncTriggered) {
          autoSyncTriggered = true;
          syncOpenPrices();
        }
      });
    }
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

  Future<void> syncOpenPrices() async {
    if (syncing || !widget.priceDataSettings.openPricesEnabled) return;
    final eanCount = allProducts
        .where((product) => (product.ean ?? '').trim().isNotEmpty)
        .length;
    setState(() {
      syncing = true;
      syncFeedback = null;
      syncProgress = '0/$eanCount EANs geprüft';
      cancelRequested = false;
    });
    try {
      final result = await widget.onSyncOpenPrices(
        onProgress: (processed, total) {
          if (mounted) {
            setState(() => syncProgress = '$processed/$total EANs geprüft');
          }
        },
        shouldCancel: () => cancelRequested || !mounted,
      );
      if (!mounted) return;
      setState(() {
        marketPrices = result.prices;
        syncFeedback = '${result.cancelled ? 'Abgebrochen: ' : ''}'
            '${result.productsProcessed}/${result.productsWithEan} '
            'EAN-Produkte geprüft · ${result.pricesFound} '
            '${result.pricesFound == 1 ? 'Preis' : 'Preise'} gefunden.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => syncFeedback =
          'Open Prices konnte nicht aktualisiert werden. Bitte Verbindung prüfen und erneut versuchen.');
    } finally {
      if (mounted) {
        setState(() {
          syncing = false;
          syncProgress = null;
        });
      }
    }
  }

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
          openPricesMaxAgeDays:
              widget.priceDataSettings.openPricesMaxAgeDays,
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
            Builder(
              builder: (context) {
                final coverage = calculatePriceCoverage(
                  allProducts,
                  marketPrices,
                  openPricesMaxAgeDays:
                      widget.priceDataSettings.openPricesMaxAgeDays,
                );
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preisdaten-Abdeckung',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${coverage.productsWithEan}/${coverage.products} Produkte mit EAN · '
                          '${coverage.manualPrices} eigene Preise · '
                          '${coverage.openPrices} Open-Prices-Daten',
                        ),
                        if (coverage.staleOpenPrices > 0)
                          Text(
                            '${coverage.staleOpenPrices} Open-Prices-Werte sind veraltet.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (widget.priceDataSettings.openPricesEnabled) ...[
                          const SizedBox(height: 10),
                          FilledButton.tonalIcon(
                            onPressed: syncing ? null : syncOpenPrices,
                            icon: syncing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync_outlined),
                            label: const Text('Open Prices aktualisieren'),
                          ),
                        ],
                        if (syncFeedback != null) ...[
                          const SizedBox(height: 8),
                          Text(syncFeedback!),
                        ],
                        if (syncing && syncProgress != null) ...[
                          const SizedBox(height: 8),
                          Text(syncProgress!),
                          TextButton(
                            onPressed: cancelRequested
                                ? null
                                : () => setState(() => cancelRequested = true),
                            child: Text(cancelRequested
                                ? 'Abbruch läuft …'
                                : 'Abbrechen'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
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
                      product.packageAmount != null && product.packageUnit != null
                          ? '${product.packageAmount} ${product.packageUnit}'
                          : product.unit,
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
