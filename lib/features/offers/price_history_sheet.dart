import 'package:flutter/material.dart';

import '../../models/price_point.dart';

void showPriceHistory(
  BuildContext context,
  String productName,
  List<PricePoint> history,
) {
  final sorted = [...history]..sort((a, b) => b.date.compareTo(a.date));

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$productName · Preisverlauf',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            const Text('Noch keine Preisbeobachtungen vorhanden.')
          else
            for (final point in sorted.take(8))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${point.price.toStringAsFixed(2)} €'),
                subtitle: Text(point.storeName),
                trailing: Text(_date(point.date)),
              ),
        ],
      ),
    ),
  );
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
