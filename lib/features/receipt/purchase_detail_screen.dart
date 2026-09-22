import 'package:flutter/material.dart';

import '../../models/purchase_record.dart';

class PurchaseDetailScreen extends StatefulWidget {
  const PurchaseDetailScreen({
    super.key,
    required this.record,
    required this.onSave,
    required this.onDelete,
  });

  final PurchaseRecord record;
  final Future<void> Function(PurchaseRecord record) onSave;
  final Future<void> Function(PurchaseRecord record) onDelete;

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  late DateTime purchaseDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    purchaseDate = widget.record.createdAt;
  }

  String euro(double value) => '${value.toStringAsFixed(2)} €';

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected == null) return;
    setState(() {
      purchaseDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        purchaseDate.hour,
        purchaseDate.minute,
        purchaseDate.second,
      );
    });
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    await widget.onSave(widget.record.copyWith(createdAt: purchaseDate));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Einkauf löschen?'),
            content: Text(
              'Der Einkauf wird aus der Historie entfernt. '
              'Das Lebensmittelbudget wird um '
              '${euro(widget.record.basket)} korrigiert. '
              'Diese Änderung beeinflusst auch gelernte Wiederkaufrhythmen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => saving = true);
    await widget.onDelete(widget.record);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Einkaufsdetails'),
          actions: [
            IconButton(
              tooltip: 'Einkauf löschen',
              onPressed: saving ? null : delete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.store_outlined),
                    title: Text(widget.record.storeNames.join(' + ')),
                    subtitle: const Text('Besuchte Märkte'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    onTap: saving ? null : pickDate,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Kaufdatum'),
                    subtitle: Text(
                      '${purchaseDate.day.toString().padLeft(2, '0')}.'
                      '${purchaseDate.month.toString().padLeft(2, '0')}.'
                      '${purchaseDate.year}',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Artikel',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0;
                      index < widget.record.items.length;
                      index++) ...[
                    ListTile(
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: Text(widget.record.items[index].name),
                      trailing: Text(
                        '×${widget.record.items[index].quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (index < widget.record.items.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _MoneyRow(
                      label: 'Warenkorb',
                      value: euro(widget.record.basket),
                    ),
                    _MoneyRow(
                      label: 'Fahrt',
                      value: euro(widget.record.travel),
                    ),
                    const Divider(),
                    _MoneyRow(
                      label: 'Gesamt',
                      value: euro(widget.record.total),
                      strong: true,
                    ),
                    _MoneyRow(
                      label: 'Ersparnis',
                      value: euro(widget.record.savings),
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Korrektur speichern'),
            ),
          ],
        ),
      );
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
