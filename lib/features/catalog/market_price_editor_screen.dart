import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/market_price.dart';
import '../../models/product.dart';

class MarketPriceEditorScreen extends StatefulWidget {
  const MarketPriceEditorScreen({
    super.key,
    required this.product,
    required this.prices,
    required this.onSave,
    required this.onDelete,
  });

  final Product product;
  final List<MarketPrice> prices;
  final Future<List<MarketPrice>> Function(MarketPrice price) onSave;
  final Future<List<MarketPrice>> Function(
    String productId,
    String storeName,
  ) onDelete;

  @override
  State<MarketPriceEditorScreen> createState() =>
      _MarketPriceEditorScreenState();
}

class _MarketPriceEditorScreenState extends State<MarketPriceEditorScreen> {
  late List<MarketPrice> prices;
  late final Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    prices = [...widget.prices];
    controllers = {
      for (final store in stores)
        store.name: TextEditingController(
          text: _priceFor(store.name)?.price.toStringAsFixed(2) ?? '',
        ),
    };
  }

  MarketPrice? _priceFor(String storeName) {
    final matches = prices.where(
      (item) =>
          item.productId == widget.product.id &&
          item.storeName == storeName,
    );
    return matches.isEmpty ? null : matches.first;
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save(String storeName) async {
    final raw =
        double.tryParse(controllers[storeName]!.text.replaceAll(',', '.'));
    if (raw == null || raw <= 0) return;

    final next = await widget.onSave(
      MarketPrice(
        productId: widget.product.id,
        storeName: storeName,
        price: raw,
        updatedAt: DateTime.now(),
      ),
    );
    if (mounted) setState(() => prices = next);
  }

  Future<void> remove(String storeName) async {
    controllers[storeName]!.clear();
    final next = await widget.onDelete(widget.product.id, storeName);
    if (mounted) setState(() => prices = next);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Preise · ${widget.product.name}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Eigene Marktpreise überschreiben die Demo-Normalpreise '
              'und werden sofort für Angebote und Routen verwendet.',
            ),
            const SizedBox(height: 12),
            for (final store in stores)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 115,
                          child: TextField(
                            controller: controllers[store.name],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              suffixText: '€',
                              isDense: true,
                            ),
                            onSubmitted: (_) => save(store.name),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Speichern',
                          onPressed: () => save(store.name),
                          icon: const Icon(Icons.save_outlined),
                        ),
                        if (_priceFor(store.name) != null)
                          IconButton(
                            tooltip: 'Eigenen Preis löschen',
                            onPressed: () => remove(store.name),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
