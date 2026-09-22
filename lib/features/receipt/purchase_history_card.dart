import 'package:flutter/material.dart';

import '../../models/purchase_record.dart';

class PurchaseHistoryCard extends StatelessWidget {
  const PurchaseHistoryCard({
    super.key,
    required this.record,
    this.onTap,
  });

  final PurchaseRecord record;
  final VoidCallback? onTap;

  String euro(double value) => '${value.toStringAsFixed(2)} €';

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          leading: const CircleAvatar(child: Icon(Icons.check)),
          title: Text(record.storeNames.join(' + ')),
          subtitle: Text(
            '${record.createdAt.day.toString().padLeft(2, '0')}.${record.createdAt.month.toString().padLeft(2, '0')}.${record.createdAt.year} · '
            '${record.itemCount} Artikel · gespart ${euro(record.savings)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                euro(record.total),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      );
}
