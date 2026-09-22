import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/market_price.dart';
import '../../models/product.dart';
import '../../services/open_prices_service.dart';

class MarketPriceEditorScreen extends StatefulWidget {
  const MarketPriceEditorScreen({
    super.key,
    required this.product,
    required this.prices,
    required this.onSave,
    required this.onDelete,
    required this.openPricesMaxAgeDays,
  });

  final Product product;
  final List<MarketPrice> prices;
  final Future<List<MarketPrice>> Function(MarketPrice price) onSave;
  final Future<List<MarketPrice>> Function(
    String productId,
    String storeName,
  ) onDelete;
  final int openPricesMaxAgeDays;

  @override
  State<MarketPriceEditorScreen> createState() =>
      _MarketPriceEditorScreenState();
}

class _MarketPriceEditorScreenState extends State<MarketPriceEditorScreen> {
  late List<MarketPrice> prices;
  late final Map<String, TextEditingController> controllers;
  late final OpenPricesService openPrices;
  bool importing = false;

  @override
  void initState() {
    super.initState();
    prices = [...widget.prices];
    openPrices = OpenPricesService(
      maxAge: Duration(days: widget.openPricesMaxAgeDays),
    );
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
    openPrices.close();
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
        source: MarketPriceSource.manual,
      ),
    );
    if (mounted) setState(() => prices = next);
  }

  Future<void> remove(String storeName) async {
    controllers[storeName]!.clear();
    final next = await widget.onDelete(widget.product.id, storeName);
    if (mounted) setState(() => prices = next);
  }

  Future<void> importOpenPrices() async {
    if (importing || widget.product.ean == null) return;
    setState(() => importing = true);

    try {
      final found = await openPrices.fetchRecentPrices(
        product: widget.product,
        stores: stores,
      );
      var next = prices;
      for (final price in found) {
        next = await widget.onSave(price);
      }

      if (!mounted) return;
      setState(() {
        prices = next;
        for (final store in stores) {
          controllers[store.name]!.text =
              _priceFor(store.name)?.price.toStringAsFixed(2) ?? '';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            found.isEmpty
                ? 'Keine aktuellen Open-Prices-Daten für diese EAN gefunden.'
                : '${found.length} passende Open-Prices-Preise geprüft.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open Prices konnte gerade nicht geladen werden.'),
        ),
      );
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Preise · ${widget.product.name}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Eigene Marktpreise überschreiben Demo- und Open-Prices-Daten '
              'und werden sofort für Angebote und Routen verwendet.',
            ),
            const SizedBox(height: 10),
            if (widget.product.ean != null &&
                widget.product.ean!.trim().isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('Open Prices'),
                  subtitle: Text(
                    'Aktuelle EUR-Normalpreise der letzten '
                    '${widget.openPricesMaxAgeDays} Tage laden. '
                    'Quelle: Open Food Facts / Open Prices (ODbL).',
                  ),
                  trailing: importing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: 'Open Prices laden',
                          onPressed: importOpenPrices,
                          icon: const Icon(Icons.refresh),
                        ),
                ),
              )
            else
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Open Prices nicht verfügbar'),
                  subtitle: Text(
                    'Hinterlege zuerst eine EAN / einen Barcode für dieses Produkt.',
                  ),
                ),
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
                          child: Builder(
                            builder: (context) {
                              final saved = _priceFor(store.name);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (saved != null)
                                    Text(
                                      '${saved.sourceLabel} · '
                                      '${saved.freshnessLabel(
                                        now: DateTime.now(),
                                        openPricesMaxAgeDays:
                                            widget.openPricesMaxAgeDays,
                                      )} · '
                                      '${_date(saved.updatedAt)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                ],
                              );
                            },
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
