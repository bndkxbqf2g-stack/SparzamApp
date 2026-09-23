import 'package:flutter/material.dart';

class PricesHubScreen extends StatelessWidget {
  const PricesHubScreen({
    super.key,
    required this.onOpenCatalog,
    required this.onOpenSettings,
    required this.summary,
  });

  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenSettings;
  final String summary;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Preise', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(summary),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Produktstamm und Marktpreise'),
              subtitle: const Text('Produkte, Preisquellen und Abdeckung'),
              onTap: onOpenCatalog,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: const Text('Preisdaten einstellen'),
              onTap: onOpenSettings,
            ),
          ),
        ],
      );
}
