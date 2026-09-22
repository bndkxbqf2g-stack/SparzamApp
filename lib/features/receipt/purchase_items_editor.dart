import 'package:flutter/material.dart';

import '../../models/purchase_record.dart';

class PurchaseItemsEditor extends StatelessWidget {
  const PurchaseItemsEditor({
    super.key,
    required this.items,
    required this.onQuantityChanged,
  });

  final List<PurchaseLine> items;
  final void Function(int index, int quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: Text(items[index].name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Menge verringern',
                      onPressed: items[index].quantity <= 1
                          ? null
                          : () => onQuantityChanged(
                                index,
                                items[index].quantity - 1,
                              ),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${items[index].quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      tooltip: 'Menge erhöhen',
                      onPressed: () => onQuantityChanged(
                        index,
                        items[index].quantity + 1,
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
              if (index < items.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      );
}
