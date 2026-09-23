import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/offer.dart';
import '../../models/product.dart';

class OfferEditorScreen extends StatefulWidget {
  const OfferEditorScreen({
    super.key,
    this.offer,
    required this.catalogProducts,
  });

  final Offer? offer;
  final List<Product> catalogProducts;

  @override
  State<OfferEditorScreen> createState() => _OfferEditorScreenState();
}

class _OfferEditorScreenState extends State<OfferEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String productId;
  late String storeName;
  late DateTime validUntil;
  late final TextEditingController originalPrice;
  late final TextEditingController offerPrice;
  late final TextEditingController buyQuantity;
  late final TextEditingController payQuantity;
  late final TextEditingController couponPercent;
  late final TextEditingController couponAmount;
  late final TextEditingController cashbackPercent;
  late final TextEditingController cashbackAmount;

  @override
  void initState() {
    super.initState();
    final offer = widget.offer;
    productId = offer?.productId ?? widget.catalogProducts.first.id;
    storeName = offer?.storeName ?? stores.first.name;
    validUntil = offer?.validUntil ?? DateTime.now().add(const Duration(days: 7));
    originalPrice = _controller(offer?.originalPrice);
    offerPrice = _controller(offer?.offerPrice);
    buyQuantity = _controller(offer?.buyQuantity);
    payQuantity = _controller(offer?.payQuantity);
    couponPercent = _controller(offer?.couponPercent);
    couponAmount = _controller(offer?.couponAmount);
    cashbackPercent = _controller(offer?.cashbackPercent);
    cashbackAmount = _controller(offer?.cashbackAmount);
  }

  TextEditingController _controller(num? value) =>
      TextEditingController(text: value?.toString() ?? '');

  @override
  void dispose() {
    for (final controller in [
      originalPrice,
      offerPrice,
      buyQuantity,
      payQuantity,
      couponPercent,
      couponAmount,
      cashbackPercent,
      cashbackAmount,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _double(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.').trim());

  int? _int(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  String? _priceValidator(String? value) {
    final price = double.tryParse((value ?? '').replaceAll(',', '.').trim());
    return price == null || !price.isFinite || price <= 0
        ? 'Bitte gültigen Preis eingeben'
        : null;
  }

  String? _discountValidator(String? value, {bool percent = false}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    final amount = double.tryParse(raw.replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount < 0 ||
        (percent && amount > 100)) {
      return percent ? 'Prozent zwischen 0 und 100' : 'Gültigen Betrag eingeben';
    }
    return null;
  }

  String? _quantityValidator(String? value, {required bool paying}) {
    final raw = (value ?? '').trim();
    final other = paying ? buyQuantity.text.trim() : payQuantity.text.trim();
    if (raw.isEmpty && other.isEmpty) return null;
    final count = int.tryParse(raw);
    if (count == null || count <= 0) return 'Anzahl über 0 eingeben';
    final buying = int.tryParse(buyQuantity.text.trim());
    if (paying && buying != null && count > buying) {
      return 'Nicht mehr bezahlen als kaufen';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: validUntil,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => validUntil = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final normal = _double(originalPrice)!;
    final sale = _double(offerPrice)!;
    if (sale > normal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Angebotspreis darf nicht über dem Normalpreis liegen.')),
      );
      return;
    }

    Navigator.pop(
      context,
      Offer(
        id: widget.offer?.id ?? 'offer_${DateTime.now().microsecondsSinceEpoch}',
        productId: productId,
        storeName: storeName,
        originalPrice: normal,
        offerPrice: sale,
        validUntil: validUntil,
        buyQuantity: _int(buyQuantity),
        payQuantity: _int(payQuantity),
        couponPercent: _double(couponPercent),
        couponAmount: _double(couponAmount),
        cashbackPercent: _double(cashbackPercent),
        cashbackAmount: _double(cashbackAmount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.offer == null ? 'Angebot hinzufügen' : 'Angebot bearbeiten'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: productId,
                decoration: const InputDecoration(labelText: 'Produkt'),
                items: widget.catalogProducts
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (value) => setState(() => productId = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: storeName,
                decoration: const InputDecoration(labelText: 'Markt'),
                items: stores
                    .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                    .toList(),
                onChanged: (value) => setState(() => storeName = value!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numberField(originalPrice, 'Normalpreis €', _priceValidator)),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(offerPrice, 'Angebot €', _priceValidator)),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gültig bis'),
                subtitle: Text(_date(validUntil)),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDate,
              ),
              const Divider(height: 28),
              Text('Mehrfachkauf', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _numberField(buyQuantity, 'Kaufen',
                      (value) => _quantityValidator(value, paying: false), integer: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(payQuantity, 'Bezahlen',
                      (value) => _quantityValidator(value, paying: true), integer: true)),
                ],
              ),
              const Divider(height: 28),
              Text('Coupon', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _numberField(couponPercent, 'Prozent %',
                      (value) => _discountValidator(value, percent: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(couponAmount, 'Betrag €', _discountValidator)),
                ],
              ),
              const Divider(height: 28),
              Text('Cashback', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _numberField(cashbackPercent, 'Prozent %',
                      (value) => _discountValidator(value, percent: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(cashbackAmount, 'Betrag €', _discountValidator)),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Angebot speichern'),
              ),
            ],
          ),
        ),
      );

  Widget _numberField(
    TextEditingController controller,
    String label,
    String? Function(String?)? validator, {
    bool integer = false,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !integer),
        decoration: InputDecoration(labelText: label),
        validator: validator,
      );

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
