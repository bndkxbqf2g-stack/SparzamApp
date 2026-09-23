import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/market_price.dart';
import '../../models/product.dart';
import 'receipt_file_text_reader.dart';
import 'receipt_import.dart';
import 'receipt_ledger.dart';

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
  final List<String> importedFileNames = <String>[];
  final receiptDrafts = <({String name, ReceiptDraft draft})>[];
  int duplicateReceipts = 0;
  String? errorMessage;
  bool importing = false;
  bool saving = false;

  Future<void> pickReceipt() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (!mounted || image == null) return;
      setState(() {
        importedFileNames.add(image.name);
        errorMessage = null;
      });
    } catch (error) {
      if (mounted) setState(() => errorMessage = 'Kamera konnte nicht geöffnet werden: $error');
    }
  }

  Future<void> pickReceiptFile() async {
    setState(() {
      importing = true;
      errorMessage = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'csv', 'jpg', 'jpeg', 'png'],
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final extractedTexts = <String>[];
      final newDrafts = <({String name, ReceiptDraft draft})>[];
      var duplicateCount = 0;
      final unreadableFiles = <String>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null) {
          unreadableFiles.add(file.name);
          continue;
        }
        final text = await readReceiptFileText(
          fileName: file.name,
          bytes: bytes,
        );
        if (text != null && text.trim().isNotEmpty) {
          if (file.name.toLowerCase().endsWith('.pdf')) {
            final draft = parseReceiptLedger(text);
            final existing = [...receiptDrafts, ...newDrafts]
                .any((entry) => entry.draft.fingerprint == draft.fingerprint);
            if (existing) {
              duplicateCount++;
            } else {
              newDrafts.add((name: file.name, draft: draft));
            }
          } else {
            extractedTexts.add(text.trim());
          }
        } else if (file.name.toLowerCase().endsWith('.pdf')) {
          unreadableFiles.add(file.name);
        }
      }
      if (!mounted) return;
      setState(() {
        importedFileNames.addAll(result.files.map((file) => file.name));
        receiptDrafts.addAll(newDrafts);
        duplicateReceipts += duplicateCount;
        _appendReceiptText(extractedTexts);
        if (unreadableFiles.isNotEmpty) {
          errorMessage =
              '${unreadableFiles.length} Beleg(e) enthalten keinen auslesbaren Text. Bitte die Artikel unten manuell ergänzen.';
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => errorMessage = 'Dateien konnten nicht gelesen werden: $error');
      }
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  void _appendReceiptText(List<String> texts) {
    if (texts.isEmpty) return;
    final current = linesController.text.trim();
    linesController.text = [
      if (current.isNotEmpty) current,
      ...texts,
    ].join('\n');
  }

  Future<void> save() async {
    final storeName = storeController.text.trim();
    if (storeName.isEmpty) {
      setState(() => errorMessage = 'Bitte zuerst den Markt angeben.');
      return;
    }
    if (linesController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Es wurden keine Artikeldaten erkannt. Bitte Artikel und Preis manuell ergänzen.');
      return;
    }
    final result = parseReceiptLines(
      text: linesController.text,
      storeName: storeName,
      products: widget.products,
    );
    if (result.prices.isEmpty) {
      setState(() => errorMessage = 'Keine bestätigte Produkt-Preis-Zeile gefunden. Bitte geprüfte Einzelpreise im Format Produkt;1,29 eintragen.');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.onSavePrices(result.prices);
      if (!mounted) return;
      Navigator.of(context).pop(
        ReceiptImportOutcome(
          savedPrices: result.prices.length,
          unmatchedLines: result.unmatchedLines,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => errorMessage = 'Preise konnten nicht gespeichert werden: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
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
                onPressed: saving || importing ? null : pickReceipt,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Weiteren Bon fotografieren'),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: saving || importing ? null : pickReceiptFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(importing
                    ? 'Belege werden gelesen …'
                    : 'Mehrere Bon-Dateien auswählen'),
              ),
              if (importing) const LinearProgressIndicator(),
              if (importedFileNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${importedFileNames.length} Beleg(e) ausgewählt'),
                ...importedFileNames.map(
                  (name) => Text(
                    '• $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              if (duplicateReceipts > 0)
                Text('$duplicateReceipts doppelte(r) PDF-Beleg(e) übersprungen.'),
              if (receiptDrafts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('PDF-Prüfvorschau',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                ...receiptDrafts.map((entry) {
                  final draft = entry.draft;
                  final printed = draft.totalCents;
                  final difference = printed == null
                      ? null : draft.calculatedCents - printed;
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${draft.retailer ?? 'Unbekannter Markt'} · '
                      '${draft.receiptDate == null ? 'Datum offen' : '${draft.receiptDate!.day.toString().padLeft(2, '0')}.${draft.receiptDate!.month.toString().padLeft(2, '0')}.${draft.receiptDate!.year}'} · '
                      '${entry.name}',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${draft.rows.length} Preiszeilen · '
                      'gerechnet ${(draft.calculatedCents / 100).toStringAsFixed(2)} € · '
                      '${printed == null ? 'Bonbetrag nicht erkannt' : 'Bonbetrag ${(printed / 100).toStringAsFixed(2)} €'}'
                      '${difference == null || difference == 0 ? '' : ' · Abweichung ${(difference / 100).toStringAsFixed(2)} €'}'
                      '${draft.unresolvedLines.isEmpty ? '' : ' · ${draft.unresolvedLines.length} offene Zeilen'}',
                    ),
                    trailing: Icon(draft.balances
                        ? Icons.check_circle_outline
                        : Icons.report_gmailerrorred_outlined),
                  );
                }),
                const Text(
                  'Diese PDF-Vorschau speichert keine Artikelpreise. '
                  'Bitte eindeutige Einzelpreise unten selbst bestätigen.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Text aus PDF-, TXT- und CSV-Dateien wird als Prüfhilfe eingelesen. Preise werden erst aus eindeutigen, geprüften Zeilen im Format Produkt;1,29 übernommen. Mengen, Rabatte und mehrdeutige Artikel bitte vorher prüfen. Fotos benötigen eine manuelle Übertragung.',
                style: TextStyle(fontSize: 12),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
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
            onPressed: saving || importing ? null : () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: saving || importing ? null : save,
            child: Text(saving ? 'Speichern …' : 'Preise lernen'),
          ),
        ],
      );
}
