import 'package:flutter/material.dart';

import '../../models/replenishment_suggestion.dart';

class ReplenishmentCard extends StatelessWidget {
  const ReplenishmentCard({
    super.key,
    required this.suggestions,
    required this.onAdd,
  });

  final List<ReplenishmentSuggestion> suggestions;
  final ValueChanged<ReplenishmentSuggestion> onAdd;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.autorenew),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bald wieder nötig',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < suggestions.length; index++) ...[
            ListTile(
              leading: Icon(
                suggestions[index].daysUntilDue <= 0
                    ? Icons.notification_important_outlined
                    : Icons.schedule_outlined,
              ),
              title: Text(
                suggestions[index].product.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${suggestions[index].timingLabel} · '
                'Rhythmus ca. ${suggestions[index].intervalDays} Tage'
                '${suggestions[index].suggestedQuantity > 1 ? ' · meist ×${suggestions[index].suggestedQuantity}' : ''}',
              ),
              trailing: IconButton.filledTonal(
                tooltip: 'Zur Liste hinzufügen',
                onPressed: () => onAdd(suggestions[index]),
                icon: const Icon(Icons.add),
              ),
            ),
            if (index < suggestions.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
