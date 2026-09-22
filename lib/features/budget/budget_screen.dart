import 'package:flutter/material.dart';

import '../../models/budget_plan.dart';
import '../../services/budget_store.dart';
import 'budget_calculator.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({
    super.key,
    required this.initialPlan,
    required this.store,
    required this.plannedShop,
    required this.onChanged,
  });

  final BudgetPlan initialPlan;
  final BudgetStore store;
  final double plannedShop;
  final ValueChanged<BudgetPlan> onChanged;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late final monthly = _controller(widget.initialPlan.monthlyBudget);
  late final food = _controller(widget.initialPlan.foodBudget);
  late final spent = _controller(widget.initialPlan.foodSpent);

  TextEditingController _controller(double value) =>
      TextEditingController(text: value == 0 ? '' : value.toStringAsFixed(2));

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;

  Future<void> save() async {
    final plan = BudgetPlan(
      monthlyBudget: _value(monthly),
      foodBudget: _value(food),
      foodSpent: _value(spent),
    );
    await widget.store.save(plan);
    widget.onChanged(plan);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    monthly.dispose();
    food.dispose();
    spent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = calculateBudget(widget.initialPlan, widget.plannedShop);
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BudgetSummary(snapshot: snapshot, plannedShop: widget.plannedShop),
          const SizedBox(height: 18),
          _MoneyField(controller: monthly, label: 'Verfügbares Monatsbudget'),
          const SizedBox(height: 12),
          _MoneyField(controller: food, label: 'Lebensmittelbudget'),
          const SizedBox(height: 12),
          _MoneyField(controller: spent, label: 'Diesen Monat bereits ausgegeben'),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Budget speichern'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Der aktuelle Einkaufsplan wird nur als Planung gegengerechnet. '
            'Als echte Ausgabe zählt er erst später nach bestätigtem Einkauf.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: '€',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({required this.snapshot, required this.plannedShop});
  final BudgetSnapshot snapshot;
  final double plannedShop;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Planungsstatus', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Lebensmittel-Restbudget: ${snapshot.foodRemaining.toStringAsFixed(2)} €'),
              Text('Geplanter Einkauf: ${plannedShop.toStringAsFixed(2)} €'),
              const Divider(),
              Text(
                'Danach übrig: ${snapshot.afterPlannedShop.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: snapshot.overBudget ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
      );
}
