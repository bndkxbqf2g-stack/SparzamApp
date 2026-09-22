import 'package:flutter/material.dart';

class ShoppingListHeader extends StatelessWidget {
  const ShoppingListHeader({
    super.key,
    required this.itemCount,
    required this.onClear,
  });

  final int itemCount;
  final VoidCallback onClear;

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
  Widget build(BuildContext context) => Row(
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
      );
}
