import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/market_price.dart';
import '../../models/product.dart';
import 'receipt_file_text_reader.dart';
import 'receipt_import.dart';
import 'receipt_ledger.dart';
import 'receipt_price_review.dart';

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
  final selectedReceiptPrices = <String>{};
  DateTime? receiptDate;
  String? errorMessage;
  bool importing = false;
  bool saving = false;

  String _priceKey(String fingerprint, String productId) =>
      '$fingerprint|$productId';

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Datum offen';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Future<void> pickReceiptDate() async {
    final chosen = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: receiptDate ?? DateTime.now(),
    );
    if (mounted && chosen != null) {
      setState(() => receiptDate = chosen);
    }
  }

  Future<void> pickReceipt() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (!mounted || image == null) return;
      setState(() {
        errorMessage = 'Fotos lassen sich noch nicht auslesen. Bitte einen durchsuchbaren PDF-Bon auswählen.';
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
      for (final entry in newDrafts) {
        final review = reviewReceiptPrices(entry.draft, widget.products);
        for (final suggestion in review.suggestions) {
          selectedReceiptPrices.add(_priceKey(entry.draft.fingerprint, suggestion.product.id));
        }
      }
      setState(() {
        importedFileNames.addAll(result.files.map((file) => file.name));
        receiptDrafts.addAll(newDrafts);
        duplicateReceipts += duplicateCount;
        if (receiptDrafts.length == 1) {
          receiptDate = receiptDrafts.single.draft.receiptDate;
          storeController.text = receiptDrafts.single.draft.retailer ?? '';
        }
        _appendReceiptText(extractedTexts);
        if (unreadableFiles.isNotEmpty) {
          errorMessage =
              '${unreadableFiles.length} Datei(en) enthalten keinen auslesbaren Text. Bilder benötigen künftig Texterkennung; bitte einen durchsuchbaren PDF-Bon wählen.';
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
    final prices = <MarketPrice>[];
    final unmatched = <String>[];
    for (final entry in receiptDrafts) {
      final review = reviewReceiptPrices(entry.draft, widget.products);
      for (final suggestion in review.suggestions) {
        if (selectedReceiptPrices.contains(
            _priceKey(entry.draft.fingerprint, suggestion.product.id))) {
          prices.add(suggestion.price);
        }
      }
    }
    if (linesController.text.trim().isNotEmpty) {
      final storeName = storeController.text.trim();
      if (storeName.isEmpty || receiptDate == null) {
        setState(() => errorMessage =
            'Für manuelle Zeilen bitte Markt und Belegdatum angeben.');
        return;
      }
      final manual = parseReceiptLines(
        text: linesController.text,
        storeName: storeName,
        products: widget.products,
        now: receiptDate,
      );
      prices.addAll(manual.prices);
      unmatched.addAll(manual.unmatchedLines);
    }
    if (prices.isEmpty) {
      setState(() => errorMessage =
          'Kein eindeutiger Artikelpreis ausgewählt. Weitere Produkte können nach einer Katalogzuordnung übernommen werden.');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.onSavePrices(prices);
      if (!mounted) return;
      Navigator.of(context).pop(
        ReceiptImportOutcome(
          savedPrices: prices.length,
          unmatchedLines: unmatched,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => errorMessage =
            'Preise konnten nicht gespeichert werden: $error');
      }
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
                label: const Text('Foto aufnehmen (noch ohne Texterkennung)'),
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
                const Text('Erkannte Bonpreise',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                for (final entry in receiptDrafts)
                  Builder(builder: (context) {
                    final draft = entry.draft;
                    final review = reviewReceiptPrices(draft, widget.products);
                    return Card(
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                          '${draft.retailer ?? 'Unbekannter Markt'} · '
                          '${_dateLabel(draft.receiptDate)}',
                        ),
                        subtitle: Text(
                          '${entry.name} · ${review.suggestions.length} eindeutige Preise · '
                          '${review.unmatchedItems} weitere Artikel',
                        ),
                        children: [
                          if (!draft.balances)
                            const ListTile(
                              title: Text('Bon nicht vollständig geprüft'),
                              subtitle: Text('Die Positionen ergeben nicht den Bonbetrag. '
                                  'Daraus werden keine Preise übernommen.'),
                            )
                          else if (review.suggestions.isEmpty)
                            const ListTile(
                              title: Text('Keine eindeutige Katalogzuordnung'),
                              subtitle: Text('Die Artikel und Preise wurden gelesen. '
                                  'Unklare Sorten und Packungsgrößen bleiben offen.'),
                            )
                          else
                            for (final suggestion in review.suggestions)
                              CheckboxListTile(
                                dense: true,
                                value: selectedReceiptPrices.contains(
                                    _priceKey(draft.fingerprint,
                                        suggestion.product.id)),
                                onChanged: saving ? null : (checked) {
                                  setState(() {
                                    final key = _priceKey(draft.fingerprint,
                                        suggestion.product.id);
                                    if (checked == true) {
                                      selectedReceiptPrices.add(key);
                                    } else {
                                      selectedReceiptPrices.remove(key);
                                    }
                                  });
                                },
                                title: Text(suggestion.product.name),
                                subtitle: Text(
                                  '${suggestion.row.label} · '
                                  '${suggestion.row.quantity == null ? '1 Stück' : '${suggestion.row.quantity} Stück'} · '
                                  '${suggestion.price.price.toStringAsFixed(2).replaceAll('.', ',')} € je ${suggestion.product.unit}',
                                ),
                              ),
                          if (review.unmatchedItems > 0)
                            ExpansionTile(
                              title: Text(
                                  '${review.unmatchedItems} weitere erkannte Positionen'),
                              subtitle: const Text(
                                  'Noch keinem Katalogprodukt sicher zugeordnet'),
                              children: [
                                for (final row in draft.rows.where(
                                  (row) => row.kind == ReceiptRowKind.item &&
                                    !review.suggestions.any(
                                      (suggestion) => suggestion.row.line == row.line),
                                ))
                                  ListTile(
                                    dense: true,
                                    title: Text(row.label),
                                    trailing: Text(
                                      '${(row.cents / 100).toStringAsFixed(2).replaceAll('.', ',')} €',
                                    ),
                                    subtitle: Text(row.quantity == null
                                        ? 'Bonposition'
                                        : '${row.quantity} × '
                                          '${((row.unitCents ?? row.cents) / 100).toStringAsFixed(2).replaceAll('.', ',')} €'),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                const Text(
                  'Nur eindeutig zugeordnete Einzelpreise werden übernommen. '
                  'Rabattpositionen und nicht unterscheidbare Sorten bleiben offen.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              ExpansionTile(
                title: const Text('Manuell ergänzen (optional)'),
                initiallyExpanded: receiptDrafts.isEmpty,
                children: [
              OutlinedButton.icon(
                onPressed: saving || importing ? null : pickReceiptDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Belegdatum: ${_dateLabel(receiptDate)}'),
              ),
              if (receiptDrafts.length > 1)
                const Text('Manuelle Ergänzungen gelten nur für den unten gewählten Markt und ein Belegdatum.'),
              const Text('Optionale manuelle Ergänzung im Format Produkt;1,29',
                  style: TextStyle(fontSize: 12)),
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
            child: Text(saving ? 'Speichern …' : 'Ausgewählte Preise übernehmen'),
          ),
        ],
      );
}
