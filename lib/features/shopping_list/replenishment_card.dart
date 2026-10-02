import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/replenishment_suggestion.dart';

class ReplenishmentCard extends StatelessWidget {
  const ReplenishmentCard({
    super.key,
    required this.suggestions,
    required this.onAdd,
    this.onReview,
    this.priceHintFor,
  });

  final List<ReplenishmentSuggestion> suggestions;
  final ValueChanged<ReplenishmentSuggestion> onAdd;
  final ValueChanged<ReplenishmentSuggestion>? onReview;
  final String? Function(Product product)? priceHintFor;

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
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${suggestions[index].timingLabel} · '
                    'Rhythmus ca. ${suggestions[index].intervalDays} Tage'
                    '${suggestions[index].suggestedQuantity > 1 ? ' · meist ×${suggestions[index].suggestedQuantity}' : ''}'
                    ' · ${suggestions[index].evidenceLabel}',
                  ),
                  if (priceHintFor != null)
                    Builder(
                      builder: (context) {
                        final hint = priceHintFor!(suggestions[index].product);
                        if (hint == null || hint.trim().isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            hint,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    ),
                ],
              ),
              trailing: Wrap(
                spacing: 2,
                children: [
                  if (onReview != null)
                    IconButton(
                      tooltip: 'Angebote und Varianten prüfen',
                      onPressed: () => onReview!(suggestions[index]),
                      icon: const Icon(Icons.tune),
                    ),
                  IconButton.filledTonal(
                    tooltip: 'Zur Liste hinzufügen',
                    onPressed: () => onAdd(suggestions[index]),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            if (index < suggestions.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
