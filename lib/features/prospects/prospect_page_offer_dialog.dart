import 'package:flutter/material.dart';
import 'prospect_page_ocr.dart';

class ProspectPageOfferDraft {
  const ProspectPageOfferDraft({
    required this.productLabel,
    required this.offerPrice,
    required this.validUntil,
    this.originalPrice,
  });

  final String productLabel;
  final double offerPrice;
  final double? originalPrice;
  final DateTime validUntil;
}

Future<ProspectPageOfferDraft?> showProspectPageOfferDialog(
  BuildContext context, {
  DateTime? initialValidUntil,
  ProspectPageOcrCandidate? initialCandidate,
}) =>
    showDialog<ProspectPageOfferDraft>(
      context: context,
      builder: (_) => _ProspectPageOfferDialog(
        initialValidUntil: initialValidUntil,
        initialCandidate: initialCandidate,
      ),
    );

class _ProspectPageOfferDialog extends StatefulWidget {
  const _ProspectPageOfferDialog({
    this.initialValidUntil,
    this.initialCandidate,
  });

  final DateTime? initialValidUntil;
  final ProspectPageOcrCandidate? initialCandidate;

  @override
  State<_ProspectPageOfferDialog> createState() =>
      _ProspectPageOfferDialogState();
}

class _ProspectPageOfferDialogState extends State<_ProspectPageOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _offerController;
  late final TextEditingController _originalController;
  DateTime? _validUntil;
  String? _dateError;
  String? _priceOrderError;

  @override
  void initState() {
    super.initState();
    final candidate = widget.initialCandidate;
    _labelController = TextEditingController(
      text: candidate?.productLabel ?? '',
    );
    _offerController = TextEditingController(
      text: candidate == null ? '' : _prefillPrice(candidate.offerPrice),
    );
    _originalController = TextEditingController(
      text: candidate?.originalPrice == null
          ? ''
          : _prefillPrice(candidate!.originalPrice!),
    );
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = widget.initialValidUntil == null
        ? null
        : DateUtils.dateOnly(widget.initialValidUntil!);
    _validUntil = initial == null || initial.isBefore(today) ? null : initial;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _offerController.dispose();
    _originalController.dispose();
    super.dispose();
  }

  double? _price(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.').trim());

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final lastDay = DateUtils.addDaysToDate(today, 730);
    var initial = _validUntil ?? today;
    if (initial.isBefore(today)) initial = today;
    if (initial.isAfter(lastDay)) initial = lastDay;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: lastDay,
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _validUntil = DateUtils.dateOnly(selected);
      _dateError = null;
    });
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    final validUntil = _validUntil;
    final offerPrice = _price(_offerController);
    final originalPrice = _originalController.text.trim().isEmpty
        ? null
        : _price(_originalController);
    final priceOrderIsValid =
        offerPrice == null ||
        originalPrice == null ||
        (offerPrice > 0 && originalPrice > 0 && offerPrice <= originalPrice);
    if (!valid || validUntil == null || !priceOrderIsValid) {
      setState(() {
        _dateError = validUntil == null ? 'Gültigkeitsende auswählen' : null;
        _priceOrderError = priceOrderIsValid
            ? null
            : 'Normalpreis muss mindestens so hoch wie der Angebotspreis sein';
      });
      return;
    }
    Navigator.of(context).pop(
      ProspectPageOfferDraft(
        productLabel: _labelController.text.trim(),
        offerPrice: offerPrice!,
        originalPrice: originalPrice,
        validUntil: validUntil,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Artikel von Prospektseite hinzufügen'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.initialCandidate == null)
                  const Text(
                    'Bitte die Angaben aus der Seite prüfen. Der Seitenlink '
                    'wird als Nachweis am Angebot gespeichert.',
                  )
                else
                  Text(
                    'Lokaler OCR-Vorschlag · '
                    '${prospectPageOcrConfidenceLabel(widget.initialCandidate!.confidence)}. '
                    'Bitte Bezeichnung und Preise vor dem Speichern prüfen.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _labelController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Artikelbezeichnung',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Artikelbezeichnung eingeben'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _offerController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Angebotspreis',
                    suffixText: '€',
                  ),
                  validator: (value) {
                    final price = double.tryParse(
                      (value ?? '').replaceAll(',', '.').trim(),
                    );
                    return price == null || !price.isFinite || price <= 0
                        ? 'Gültigen Angebotspreis eingeben'
                        : null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _originalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Normalpreis (optional)',
                    suffixText: '€',
                    errorText: _priceOrderError,
                  ),
                  onChanged: (_) => setState(() => _priceOrderError = null),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final price = double.tryParse(
                      value.replaceAll(',', '.').trim(),
                    );
                    return price == null || !price.isFinite || price <= 0
                        ? 'Gültigen Normalpreis eingeben'
                        : null;
                  },
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Gültig bis',
                    errorText: _dateError,
                  ),
                  child: InkWell(
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        _validUntil == null
                            ? 'Datum auswählen'
                            : _formatDate(_validUntil!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('Artikel hinzufügen'),
          ),
        ],
      );

}

String _prefillPrice(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

