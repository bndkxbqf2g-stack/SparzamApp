import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'receipt_observation_builder.dart';

Future<Product?> showReceiptProductCandidateDialog({
  required BuildContext context,
  required String rawLabel,
  required String quantityUnit,
}) async {
  final family = inferReceiptFamily(rawLabel);
  final nameController = TextEditingController(text: _displayName(rawLabel));
  final groupController = TextEditingController(text: _displayName(family));
  final unitController = TextEditingController(
    text: quantityUnit == 'kg' ? 'kg' : 'Stück',
  );

  final result = await showDialog<Product>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Neues Produkt anlegen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bon: $rawLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Produktname'),
          ),
          TextField(
            controller: groupController,
            decoration: const InputDecoration(labelText: 'Produktgruppe'),
          ),
          TextField(
            controller: unitController,
            decoration: const InputDecoration(labelText: 'Einheit'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            final group = groupController.text.trim();
            final unit = unitController.text.trim();
            if (name.isEmpty || group.isEmpty || unit.isEmpty) return;
            Navigator.pop(
              context,
              Product(
                id: 'receipt_${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                unit: unit,
                group: group,
                aliases: [rawLabel],
              ),
            );
          },
          child: const Text('Anlegen & zuordnen'),
        ),
      ],
    ),
  );
  nameController.dispose();
  groupController.dispose();
  unitController.dispose();
  return result;
}

String _displayName(String value) {
  if (value.isEmpty) return value;
  final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}
