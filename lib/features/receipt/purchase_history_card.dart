import 'package:flutter/material.dart';

import '../../models/purchase_record.dart';

class PurchaseHistoryCard extends StatelessWidget {
  const PurchaseHistoryCard({super.key, required this.record});

  final PurchaseRecord record;

  String euro(double value) => '${value.toStringAsFixed(2)} €';

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.check)),
          title: Text(record.storeNames.join(' + ')),
          subtitle: Text(
            '${record.createdAt.day.toString().padLeft(2, '0')}.${record.createdAt.month.toString().padLeft(2, '0')}.${record.createdAt.year} · '
            '${record.itemCount} Artikel · gespart ${euro(record.savings)}',
          ),
          trailing: Text(
            euro(record.total),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
}
