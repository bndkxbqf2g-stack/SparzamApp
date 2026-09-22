import 'package:flutter/material.dart';

class CompletedItemsAction extends StatelessWidget {
  const CompletedItemsAction({
    super.key,
    required this.count,
    required this.onRemove,
  });

  final int count;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => count == 0
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: FilledButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.check_circle_outline),
            label: Text('$count erledigte Artikel entfernen'),
          ),
        );
}

class EmptyShoppingListCard extends StatelessWidget {
  const EmptyShoppingListCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
          child: Column(
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 52,
                color: Colors.blue.shade600,
              ),
              const SizedBox(height: 12),
              const Text(
                'Deine Liste ist noch leer.',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tippe oben ein Produkt ein oder füge es über '
                '„Schnell hinzufügen“ direkt hinzu.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
