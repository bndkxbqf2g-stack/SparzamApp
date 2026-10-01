import 'package:flutter/material.dart';

import 'price_gap_priority.dart';

class PriceGapCard extends StatelessWidget {
  const PriceGapCard({
    super.key,
    required this.gaps,
    this.title = 'Preis-Datenlücken zuerst klären',
    this.description = 'Ohne belastbaren Preis bleibt die Planung für diese Positionen vorläufig.',
    this.maxItems = 5,
  });

  final List<PriceGapPriority> gaps;
  final String title;
  final String description;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final shown = gaps.take(maxItems).toList(growable: false);
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.priority_high_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 8),
            for (var index = 0; index < shown.length; index++) ...[
              if (index > 0) const Divider(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 13,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shown[index].item.product.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          shown[index].detailLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (gaps.length > shown.length) ...[
              const SizedBox(height: 8),
              Text(
                'Weitere ${gaps.length - shown.length} Positionen folgen danach.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
