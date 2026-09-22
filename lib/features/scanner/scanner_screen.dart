import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/product.dart';
import '../../services/open_food_facts_service.dart';
import 'barcode_product_resolver.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.learnedProducts = const []});

  final List<Product> learnedProducts;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? unknownCode;
  bool completing = false;
  bool lookingUp = false;
  final openFoodFacts = OpenFoodFactsService();

  Future<void> resolve(String? code) async {
    if (completing || code == null || code.isEmpty) return;
    final product = productForBarcode(code, widget.learnedProducts);
    if (product != null) {
      completing = true;
      Navigator.pop(context, product);
      return;
    }
    if (lookingUp) return;
    setState(() {
      lookingUp = true;
      unknownCode = code;
    });

    final enriched = await openFoodFacts.fetchProductByEan(code);
    if (!mounted) return;
    if (enriched != null) {
      completing = true;
      Navigator.pop(context, enriched);
      return;
    }

    setState(() => lookingUp = false);
  }

  Future<void> enterCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('EAN eingeben'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'z. B. 2990000000019'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Prüfen'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code != null) await resolve(code);
  }

  Future<void> addUnknown() async {
    final code = unknownCode;
    if (code == null) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neues Produkt'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Produktname'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Anlegen'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    Navigator.pop(
      context,
      Product(
        id: 'barcode_$code',
        name: name,
        unit: 'Artikel',
        group: 'custom',
        ean: code,
      ),
    );
  }

  @override
  void dispose() {
    openFoodFacts.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Barcode scannen'),
          actions: [IconButton(onPressed: enterCode, icon: const Icon(Icons.keyboard))],
        ),
        body: Column(
          children: [
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  if (capture.barcodes.isNotEmpty) {
                    resolve(capture.barcodes.first.rawValue);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: unknownCode == null
                  ? const Text('Barcode in den Rahmen halten.')
                  : Column(
                      children: [
                        if (lookingUp)
                          const Text('Produktdaten werden gesucht …')
                        else
                          Text('Noch unbekannt: $unknownCode'),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: lookingUp ? null : addUnknown,
                          icon: const Icon(Icons.add),
                          label: const Text('Produkt anlegen'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
}
