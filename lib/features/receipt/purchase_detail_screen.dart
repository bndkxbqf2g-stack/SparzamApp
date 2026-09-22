import 'package:flutter/material.dart';

import '../../models/purchase_record.dart';
import 'purchase_items_editor.dart';
import 'purchase_money_editor.dart';

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
  late List<PurchaseLine> items;
  late final TextEditingController basketController;
  late final TextEditingController travelController;
  late final TextEditingController baselineController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    purchaseDate = widget.record.createdAt;
    items = [...widget.record.items];
    basketController = _moneyController(widget.record.basket);
    travelController = _moneyController(widget.record.travel);
    baselineController = _moneyController(widget.record.baselineTotal);
  }

  TextEditingController _moneyController(double value) =>
      TextEditingController(text: value.toStringAsFixed(2));

  double _moneyValue(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;

  String euro(double value) => '${value.toStringAsFixed(2)} €';

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;
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
    final basket = _moneyValue(basketController);
    final travel = _moneyValue(travelController);
    try {
      await widget.onSave(
        widget.record.copyWith(
          createdAt: purchaseDate,
          items: items,
          basket: basket,
          travel: travel,
          total: basket + travel,
          baselineTotal: _moneyValue(baselineController),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Korrektur konnte nicht gespeichert werden. Bitte erneut versuchen.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void changeQuantity(int index, int quantity) {
    final item = items[index];
    setState(() {
      items[index] = PurchaseLine(
        productId: item.productId,
        name: item.name,
        quantity: quantity,
      );
    });
  }

  @override
  void dispose() {
    basketController.dispose();
    travelController.dispose();
    baselineController.dispose();
    super.dispose();
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
    if (!confirmed || !mounted || saving) return;

    setState(() => saving = true);
    try {
      await widget.onDelete(widget.record);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Einkauf konnte nicht gelöscht werden. Bitte erneut versuchen.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
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
            PurchaseItemsEditor(
              items: items,
              onQuantityChanged: changeQuantity,
            ),
            const SizedBox(height: 16),
            PurchaseMoneyEditor(
              basketController: basketController,
              travelController: travelController,
              baselineController: baselineController,
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
