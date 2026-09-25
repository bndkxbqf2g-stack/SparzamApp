import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/market_price.dart';
import '../../models/product.dart';
import '../../models/receipt_identity.dart';
import '../../services/receipt_observation_store.dart';
import '../../services/receipt_alias_store.dart';
import 'receipt_auto_product.dart';
import 'receipt_file_text_reader.dart';
import 'receipt_import.dart';
import 'receipt_import_display.dart';
import 'receipt_ledger.dart';
import 'receipt_assigned_price.dart';
import 'receipt_observation_builder.dart';
import 'receipt_price_review.dart';
import 'receipt_product_picker.dart';
import 'receipt_product_candidate_dialog.dart';

class ReceiptImportDialog extends StatefulWidget {
  const ReceiptImportDialog({
    super.key,
    required this.products,
    required this.onSavePrices,
    this.onCreateProduct,
  });

  final List<Product> products;
  final Future<void> Function(List<MarketPrice> prices) onSavePrices;
  final Future<List<Product>> Function(Product product)? onCreateProduct;

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
  final assignedProducts = <String, String>{};
  final automaticProductAssignments = <String>{};
  late List<Product> availableProducts;
  DateTime? receiptDate;
  String? errorMessage;
  bool importing = false;
  bool saving = false;
  final observationStore = ReceiptObservationStore();
  final aliasStore = ReceiptAliasStore();

  @override
  void initState() {
    super.initState();
    availableProducts = [...widget.products];
  }

  String _priceKey(String fingerprint, String productId) =>
      '$fingerprint|$productId';

  String _rowKey(ReceiptDraft draft, ReceiptRow row) =>
      '${draft.fingerprint}|${row.line}';

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Datum offen';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  ReceiptIdentityAssessment _suggestionIdentity(
    ReceiptDraft draft,
    ReceiptPriceSuggestion suggestion,
  ) =>
      assessReceiptIdentity(
        productId: suggestion.product.id,
        identityConfirmed: selectedReceiptPrices.contains(
          _priceKey(draft.fingerprint, suggestion.product.id),
        ),
        familyKey: inferReceiptFamily(suggestion.row.label),
      );

  ReceiptIdentityAssessment _assignedIdentity(
    ReceiptDraft draft,
    ReceiptRow row,
  ) {
    final key = _rowKey(draft, row);
    return assessReceiptIdentity(
      productId: assignedProducts[key],
      identityConfirmed: assignedProducts.containsKey(key) &&
          !automaticProductAssignments.contains(key),
      familyKey: inferReceiptFamily(row.label),
    );
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
        final draft = entry.draft;
        if (draft.retailer != null) {
          for (final row in draft.rows.where((r) => r.kind == ReceiptRowKind.item)) {
            final learnedId = await aliasStore.learnedProductId(
              storeName: draft.retailer!,
              rawLabel: row.label,
            );
            if (learnedId != null &&
                availableProducts.any((product) => product.id == learnedId)) {
              assignedProducts[_rowKey(draft, row)] = learnedId;
            }
          }
        }
        // Price suggestions are rendered later and deliberately start
        // unselected; only an explicit checkbox action confirms them.
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

  Future<void> _ensureAutomaticReceiptProducts() async {
    final createProduct = widget.onCreateProduct;
    if (createProduct == null) return;

    for (final entry in receiptDrafts) {
      final draft = entry.draft;
      if (!draft.balances) continue;

      final review = reviewReceiptPrices(draft, availableProducts);
      final matchedLines = review.suggestions
          .map((suggestion) => suggestion.row.line)
          .toSet();

      for (final row in draft.rows.where(
        (row) => row.kind == ReceiptRowKind.item,
      )) {
        final key = _rowKey(draft, row);
        if (matchedLines.contains(row.line) ||
            assignedProducts.containsKey(key)) {
          continue;
        }

        if (!shouldCreateAutomaticReceiptProduct(row.label)) {
          continue;
        }

        final existing = findExistingReceiptProduct(
          row.label,
          availableProducts,
        );
        if (existing != null) {
          assignedProducts[key] = existing.id;
          automaticProductAssignments.add(key);
          continue;
        }

        final product = buildAutomaticReceiptProduct(
          row: row,
          id: 'receipt_auto_${DateTime.now().microsecondsSinceEpoch}_${row.line}',
        );
        availableProducts = await createProduct(product);
        assignedProducts[key] = product.id;
        automaticProductAssignments.add(key);
      }
    }
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      errorMessage = null;
    });
    try {
      await _ensureAutomaticReceiptProducts();
    } catch (error) {
      if (mounted) {
        setState(() {
          saving = false;
          errorMessage = 'Erkannte Produkte konnten nicht angelegt werden: $error';
        });
      }
      return;
    }
    if (!mounted) return;

    final prices = <MarketPrice>[];
    final unmatched = <String>[];
    for (final entry in receiptDrafts) {
      final draft = entry.draft;
      final review = reviewReceiptPrices(draft, availableProducts);
      final usedProducts = <String>{};
      for (final suggestion in review.suggestions) {
        if (selectedReceiptPrices.contains(
            _priceKey(draft.fingerprint, suggestion.product.id))) {
          prices.add(suggestion.price);
          usedProducts.add(suggestion.product.id);
        }
      }
      for (final row in draft.rows) {
        final id = assignedProducts[_rowKey(draft, row)];
        if (id == null) continue;
        final products = availableProducts.where((product) => product.id == id);
        if (products.length != 1) continue;

        // A manual assignment always teaches identity. It becomes a direct
        // catalog price only where quantity/package semantics are already safe.
        final price = assignedReceiptPrice(
          draft: draft,
          row: row,
          product: products.single,
          identityConfirmed:
              !automaticProductAssignments.contains(_rowKey(draft, row)),
        );
        if (price != null && usedProducts.add(id)) {
          prices.add(price);
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
        products: availableProducts,
        now: receiptDate,
      );
      prices.addAll(manual.prices);
      unmatched.addAll(manual.unmatchedLines);
    }
    try {
      var savedObservations = 0;
      for (final entry in receiptDrafts) {
        final draft = entry.draft;
        final review = reviewReceiptPrices(draft, availableProducts);
        final assigned = <int, String>{};
        final confirmedLines = <int>{};
        for (final row in draft.rows) {
          final key = _rowKey(draft, row);
          final productId = assignedProducts[key];
          if (productId != null) {
            assigned[row.line] = productId;
            if (!automaticProductAssignments.contains(key)) {
              confirmedLines.add(row.line);
            }
          }
        }
        for (final row in draft.rows) {
          final productId = assigned[row.line];
          if (productId != null &&
              draft.retailer != null &&
              !automaticProductAssignments.contains(_rowKey(draft, row))) {
            await aliasStore.confirm(
              storeName: draft.retailer!,
              rawLabel: row.label,
              productId: productId,
              now: DateTime.now(),
            );
          }
        }
        savedObservations += await observationStore.addMany(
          buildReceiptObservations(
            draft: draft,
            review: review,
            assignedProductIds: assigned,
            confirmedProductLines: confirmedLines,
          ),
        );
      }
      if (prices.isNotEmpty) {
        await widget.onSavePrices(prices);
      }
      if (prices.isEmpty && savedObservations == 0) {
        setState(() => errorMessage =
            'Keine verwertbaren Produkt- oder Preisbeobachtungen gefunden.');
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        ReceiptImportOutcome(
          savedPrices: prices.length,
          savedObservations: savedObservations,
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

  List<ReceiptDisplayEntry> get _displayReceiptDrafts =>
      orderReceiptDraftsForDisplay(receiptDrafts);

  int get _importableReceiptCount => importableReceiptCount(receiptDrafts);

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
              if (receiptDrafts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_importableReceiptCount von ${receiptDrafts.length} '
                    'Bon(s) vollständig geprüft und übernehmbar',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              if (duplicateReceipts > 0)
                Text('$duplicateReceipts doppelte(r) PDF-Beleg(e) übersprungen.'),
              if (receiptDrafts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Erkannte Bonpreise',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                for (final entry in _displayReceiptDrafts)
                  Builder(builder: (context) {
                    final draft = entry.draft;
                    final review = reviewReceiptPrices(draft, availableProducts);
                    return Card(
                      child: ExpansionTile(
                        initiallyExpanded: draft.balances,
                        title: Text(
                          '${draft.retailer ?? 'Unbekannter Markt'} · '
                          '${_dateLabel(draft.receiptDate)}',
                        ),
                        subtitle: Text(
                          '${entry.name} · ${review.suggestions.length} Preisvorschläge · '
                          '${review.unmatchedItems} weitere Artikel',
                        ),
                        children: [
                          if (!draft.balances)
                            const ListTile(
                              title: Text('Bon nicht vollständig geprüft'),
                              subtitle: Text('Die Positionen ergeben nicht den Bonbetrag. '
                                  'Dieser Bon bleibt gesperrt; seine erkannten Preise werden nur angezeigt. '
                                  'Andere vollständig geprüfte Bons können trotzdem übernommen werden.'),
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
                                title: Text(
                                  '${suggestion.product.name} · '
                                  '${suggestion.price.price.toStringAsFixed(2).replaceAll('.', ',')} €',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  '${suggestion.row.label} · '
                                  '${suggestion.row.quantity == null ? '1 Stück' : '${suggestion.row.quantity} ${suggestion.row.quantityUnit}'} · '
                                  '${suggestion.price.price.toStringAsFixed(2).replaceAll('.', ',')} € je ${suggestion.product.unit}\n'
                                  '${_suggestionIdentity(draft, suggestion).summary}',
                                ),
                              ),
                          if (review.unmatchedItems > 0)
                            ExpansionTile(
                              initiallyExpanded: true,
                              title: Text(
                                  '${review.unmatchedItems} weitere erkannte Artikelpreise'),
                              subtitle: const Text(
                                  'Noch keinem Katalogprodukt sicher zugeordnet'),
                              children: [
                                for (final row in draft.rows.where(
                                  (row) => row.kind == ReceiptRowKind.item &&
                                    !review.suggestions.any(
                                      (suggestion) => suggestion.row.line == row.line),
                                ))
                                  ListTile(
                                    dense: false,
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          row.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${(row.cents / 100).toStringAsFixed(2).replaceAll('.', ',')} €',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          row.quantity == null
                                              ? 'Preis laut Bon · 1 Position'
                                              : 'Preis laut Bon · ${row.quantity} ${row.quantityUnit} × '
                                                '${((row.unitCents ?? row.cents) / 100).toStringAsFixed(2).replaceAll('.', ',')} €',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          draft.balances
                                              ? 'Wird beim Speichern als Bonbeobachtung übernommen.'
                                              : 'Nur Vorschau – Bon muss rechnerisch noch geprüft werden.',
                                        ),
                                        if (assignedProducts.containsKey(_rowKey(draft, row)))
                                          Text(
                                            'Zuordnung: ${availableProducts.where((p) => p.id == assignedProducts[_rowKey(draft, row)]).first.name}\n'
                                            '${_assignedIdentity(draft, row).summary}',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            icon: const Icon(Icons.link),
                                            label: Text(
                                              assignedProducts.containsKey(_rowKey(draft, row))
                                                  ? 'Zuordnung ändern'
                                                  : 'Produkt zuordnen',
                                            ),
                                            onPressed: saving ? null : () async {
                                              final key = _rowKey(draft, row);
                                              final value = await showReceiptProductPicker(
                                                context: context,
                                                products: availableProducts,
                                                selectedProductId: assignedProducts[key],
                                              );
                                              if (!mounted || value == null) return;
                                              setState(() {
                                                if (value.isEmpty) {
                                                  assignedProducts.remove(key);
                                                } else {
                                                  assignedProducts[key] = value;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        if (widget.onCreateProduct != null)
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              icon: const Icon(Icons.add_circle_outline),
                                              label: const Text('Als neues Produkt anlegen'),
                                              onPressed: saving ? null : () async {
                                                final product = await showReceiptProductCandidateDialog(
                                                  context: context,
                                                  rawLabel: row.label,
                                                  quantityUnit: row.quantityUnit,
                                                );
                                                if (!mounted || product == null) return;
                                                final next = await widget.onCreateProduct!(product);
                                                if (!mounted) return;
                                                setState(() {
                                                  availableProducts = next;
                                                  assignedProducts[_rowKey(draft, row)] = product.id;
                                                });
                                              },
                                            ),
                                          ),
                                      ],
                                    )
                                  ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                const Text(
                  'Bei vollständig geprüften Bons werden alle erkannten Artikelpreise als Bonbeobachtungen übernommen. '
                  'Ein Häkchen bestätigt zusätzlich eine vorgeschlagene exakte Produktzuordnung und erzeugt daraus einen direkten Marktpreis. '
                  'Unklare Varianten bleiben prüfbar; Pfand und reine Rabattzeilen werden nicht als Produkte behandelt.',
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
            child: Text(saving ? 'Speichern …' : 'Bonpreise übernehmen'),
          ),
        ],
      );
}
