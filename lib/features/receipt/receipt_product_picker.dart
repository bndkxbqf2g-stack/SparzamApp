import 'package:flutter/material.dart';

import '../../models/product.dart';

Future<String?> showReceiptProductPicker({
  required BuildContext context,
  required List<Product> products,
  String? selectedProductId,
}) async {
  var query = '';
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final normalized = query.toLowerCase().trim();
        final matches = products.where((product) {
          if (normalized.isEmpty) return true;
          return product.name.toLowerCase().contains(normalized) ||
              product.aliases.any(
                (alias) => alias.toLowerCase().contains(normalized),
              );
        }).take(40).toList();

        return AlertDialog(
          title: const Text('Produkt zuordnen'),
          content: SizedBox(
            width: 440,
            height: 460,
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Produkt suchen …',
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final product = matches[index];
                      final selected = product.id == selectedProductId;
                      return ListTile(
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        title: Text(product.name),
                        subtitle: Text(product.unit),
                        onTap: () => Navigator.pop(context, product.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (selectedProductId != null)
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: const Text('Zuordnung entfernen'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    ),
  );
}
