import 'package:flutter/material.dart';

import 'shopping_group_card.dart';

Future<List<String>?> showAisleOrderDialog(
  BuildContext context, {
  required List<String> groups,
  required List<String> currentOrder,
}) {
  final known = currentOrder.where(groups.contains).toList();
  final order = [...known, ...groups.where((group) => !known.contains(group))];
  return showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Reihenfolge im Markt'),
        content: SizedBox(
          width: 360,
          height: 320,
          child: ReorderableListView(
            children: [
              for (final group in order)
                ListTile(
                  key: ValueKey(group),
                  leading: const Icon(Icons.drag_handle),
                  title: Text(shoppingGroupLabel(group)),
                ),
            ],
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final item = order.removeAt(oldIndex);
                order.insert(newIndex, item);
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, order),
            child: const Text('Speichern'),
          ),
        ],
      ),
    ),
  );
}
