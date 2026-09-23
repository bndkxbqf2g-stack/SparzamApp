import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/market_price.dart';
import '../../models/product.dart';
import 'receipt_import.dart';

class ReceiptImportDialog extends StatefulWidget {
  const ReceiptImportDialog({
    super.key,
    required this.products,
    required this.onSavePrices,
  });

  final List<Product> products;
  final Future<void> Function(List<MarketPrice> prices) onSavePrices;

  @override
  State<ReceiptImportDialog> createState() => _ReceiptImportDialogState();
}

class _ReceiptImportDialogState extends State<ReceiptImportDialog> {
  final storeController = TextEditingController();
  final linesController = TextEditingController();
  bool hasPhoto = false;
  String? importedFileName;
  bool saving = false;

  Future<void> pickReceipt() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (!mounted || image == null) return;
    setState(() => hasPhoto = true);
  }

  Future<void> pickReceiptFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'csv', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() => importedFileName = file.name);
    final bytes = file.bytes;
    final lower = file.name.toLowerCase();
    if (bytes != null && (lower.endsWith('.txt') || lower.endsWith('.csv'))) {
      linesController.text = utf8.decode(bytes, allowMalformed: true);
    }
  }

  Future<void> save() async {
    final result = parseReceiptLines(
      text: linesController.text,
      storeName: storeController.text,
      products: widget.products,
    );
    if (result.prices.isEmpty) return;
    setState(() => saving = true);
    await widget.onSavePrices(result.prices);
    if (!mounted) return;
    Navigator.of(context).pop(result.unmatchedLines);
  }

  @override
  void dispose() {
    storeController.dispose();
    linesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Kassenbon übernehmen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: saving ? null : pickReceipt,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(hasPhoto ? 'Bon fotografiert' : 'Bon fotografieren'),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: saving ? null : pickReceiptFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(importedFileName == null
                    ? 'Bon-Datei hochladen'
                    : 'Datei: $importedFileName'),
              ),
              const SizedBox(height: 8),
              const Text(
                'PDF/Bild-Belege dienen als Referenz für die manuelle Übertragung. TXT/CSV wird direkt eingelesen. Format je Zeile: Produkt;Preis',
                style: TextStyle(fontSize: 12),
              ),
              TextField(
                controller: storeController,
                decoration: const InputDecoration(labelText: 'Markt'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: linesController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Artikel und Preise',
                  hintText: 'Milch;1,29\nButter;1,89',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: saving ? null : save,
            child: const Text('Preise lernen'),
          ),
        ],
      );
}
