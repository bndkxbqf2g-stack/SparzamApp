import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/open_food_facts_service.dart';

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController brand;
  late final TextEditingController unit;
  late final TextEditingController group;
  late final TextEditingController ean;
  late final TextEditingController aliases;
  late bool favorite;
  late final TextEditingController packageAmount;
  late final TextEditingController packageUnit;
  final openFoodFacts = OpenFoodFactsService();
  bool enriching = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    name = TextEditingController(text: product?.name ?? '');
    brand = TextEditingController(text: product?.brand ?? '');
    unit = TextEditingController(text: product?.unit ?? 'Artikel');
    group = TextEditingController(text: product?.group ?? 'custom');
    ean = TextEditingController(text: product?.ean ?? '');
    aliases = TextEditingController(text: product?.aliases.join(', ') ?? '');
    packageAmount = TextEditingController(
      text: product?.packageAmount?.toString() ?? '',
    );
    packageUnit = TextEditingController(text: product?.packageUnit ?? '');
    favorite = product?.isFavorite ?? false;
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      brand,
      unit,
      group,
      ean,
      aliases,
      packageAmount,
      packageUnit,
    ]) {
      controller.dispose();
    }
    openFoodFacts.close();
    super.dispose();
  }

  Future<void> enrichFromEan() async {
    final code = ean.text.trim();
    if (code.isEmpty || enriching) return;
    setState(() => enriching = true);

    final existing = widget.product ??
        Product(
          id: 'barcode_$code',
          name: name.text.trim().isEmpty ? 'Produkt' : name.text.trim(),
          unit: unit.text.trim().isEmpty ? 'Artikel' : unit.text.trim(),
          group: group.text.trim().isEmpty ? 'custom' : group.text.trim(),
          ean: code,
        );
    final enriched = await openFoodFacts.fetchProductByEan(
      code,
      existing: existing,
    );

    if (!mounted) return;
    setState(() {
      enriching = false;
      if (enriched == null) return;
      name.text = enriched.name;
      brand.text = enriched.brand ?? '';
      unit.text = enriched.unit;
      group.text = enriched.group;
      packageAmount.text = enriched.packageAmount?.toString() ?? '';
      packageUnit.text = enriched.packageUnit ?? '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enriched == null
              ? 'Keine Produktdaten bei Open Food Facts gefunden.'
              : 'Produktdaten wurden ergänzt.',
        ),
      ),
    );
  }

  void save() {
    if (!formKey.currentState!.validate()) return;
    final id = widget.product?.id ??
        'custom_${DateTime.now().microsecondsSinceEpoch}';

    Navigator.pop(
      context,
      Product(
        id: id,
        name: name.text.trim(),
        brand: brand.text.trim().isEmpty ? null : brand.text.trim(),
        unit: unit.text.trim(),
        group: group.text.trim().toLowerCase(),
        ean: ean.text.trim().isEmpty ? null : ean.text.trim(),
        aliases: aliases.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        isFavorite: favorite,
        packageAmount: double.tryParse(
          packageAmount.text.replaceAll(',', '.').trim(),
        ),
        packageUnit: packageUnit.text.trim().isEmpty
            ? null
            : packageUnit.text.trim().toLowerCase(),
        imageUrl: widget.product?.imageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.product == null
              ? 'Produkt anlegen'
              : 'Produkt bearbeiten'),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: name,
                autofocus: widget.product == null,
                decoration: const InputDecoration(labelText: 'Produktname'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Name eingeben' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: brand,
                decoration: const InputDecoration(
                  labelText: 'Marke / Variante',
                  hintText: 'optional',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: unit,
                      decoration:
                          const InputDecoration(labelText: 'Einheit'),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Einheit eingeben'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: group,
                      decoration:
                          const InputDecoration(labelText: 'Kategorie'),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Kategorie eingeben'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: ean,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'EAN / Barcode',
                        hintText: 'optional',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Produktdaten laden',
                    onPressed: enriching ? null : enrichFromEan,
                    icon: enriching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: packageAmount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Packungsmenge',
                        hintText: 'z. B. 500',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: packageUnit,
                      decoration: const InputDecoration(
                        labelText: 'Mengeneinheit',
                        hintText: 'g, kg, ml, l, st',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: aliases,
                decoration: const InputDecoration(
                  labelText: 'Suchbegriffe',
                  hintText: 'z. B. Pasta, Spaghetti, Nudeln',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: favorite,
                onChanged: (value) => setState(() => favorite = value),
                title: const Text('Favorit'),
                subtitle:
                    const Text('Favoriten erscheinen bevorzugt in Vorschlägen.'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Produkt speichern'),
              ),
            ],
          ),
        ),
      );
}
