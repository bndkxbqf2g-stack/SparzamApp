import 'package:flutter/material.dart';

import '../../design/sparzam_theme.dart';

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
          const Icon(Icons.sell_outlined,
              color: SparzamTheme.deepGreen, size: 28),
          const SizedBox(height: 8),
          Text('Preise',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const Center(child: Text('Transparenz schafft echte Ersparnis.')),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.search, color: SparzamTheme.deepGreen),
              title: const Text('Produkte und Preise vergleichen'),
              subtitle: const Text('Produkt suchen, Marktpreise und Verlauf ansehen'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenCatalog,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined,
                  color: SparzamTheme.deepGreen),
              title: const Text('Preisdaten'),
              subtitle: Text(summary),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenSettings,
            ),
          ),
        ],
      );
}
