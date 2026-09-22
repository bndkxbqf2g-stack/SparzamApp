import 'package:flutter/material.dart';

import '../../models/product.dart';

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
    favorite = product?.isFavorite ?? false;
  }

  @override
  void dispose() {
    for (final controller in [name, brand, unit, group, ean, aliases]) {
      controller.dispose();
    }
    super.dispose();
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
              TextFormField(
                controller: ean,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'EAN / Barcode',
                  hintText: 'optional',
                ),
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
