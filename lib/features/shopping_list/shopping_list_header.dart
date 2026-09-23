import 'package:flutter/material.dart';

import '../../models/named_shopping_list.dart';

class ShoppingListHeader extends StatelessWidget {
  const ShoppingListHeader({
    super.key,
    required this.itemCount,
    required this.onClear,
    this.lists = const <NamedShoppingList>[],
    this.activeListId = 'default',
    this.onSelectList,
    this.onCreateList,
    this.onEditAisleOrder,
    this.tileView = false,
    this.onToggleView,
  });

  final int itemCount;
  final VoidCallback onClear;
  final List<NamedShoppingList> lists;
  final String activeListId;
  final Future<void> Function(String id)? onSelectList;
  final Future<void> Function(String name)? onCreateList;
  final VoidCallback? onEditAisleOrder;
  final bool tileView;
  final VoidCallback? onToggleView;

  Future<void> _createList(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Einkaufsliste'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Listenname',
            hintText: 'Zum Beispiel Wocheneinkauf',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await onCreateList?.call(name);
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Einkaufsliste leeren?'),
            content: const Text(
              'Alle Artikel werden aus der aktuellen Liste entfernt. '
              'Deine Kaufhistorie bleibt erhalten.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Liste leeren'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) onClear();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Einkaufsliste',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (itemCount > 0) ...[
            Text(
              '$itemCount Artikel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              tooltip: 'Listenoptionen',
              onSelected: (value) {
                if (value == 'clear') _confirmClear(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Text('Gesamte Liste leeren'),
                ),
              ],
            ),
              ],
            ],
          ),
          if (lists.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: activeListId,
                    decoration: const InputDecoration(
                      labelText: 'Aktuelle Liste',
                      isDense: true,
                    ),
                    items: lists
                        .map((list) => DropdownMenuItem(
                              value: list.id,
                              child: Text(list.name),
                            ))
                        .toList(),
                    onChanged: onSelectList == null
                        ? null
                        : (id) {
                            if (id != null) onSelectList!(id);
                          },
                  ),
                ),
                IconButton(
                  tooltip: 'Reihenfolge im Markt',
                  onPressed: onEditAisleOrder,
                  icon: const Icon(Icons.swap_vert),
                ),
                IconButton(
                  tooltip: tileView ? 'Listenansicht' : 'Kachelansicht',
                  onPressed: onToggleView,
                  icon: Icon(tileView ? Icons.view_list : Icons.grid_view),
                ),
                IconButton(
                  tooltip: 'Neue Liste',
                  onPressed: onCreateList == null
                      ? null
                      : () => _createList(context),
                  icon: const Icon(Icons.playlist_add),
                ),
              ],
            ),
          ],
        ],
      );
}
