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
  final formKey = GlobalKey<FormState>();
  late final monthly = _controller(widget.initialPlan.monthlyBudget);
  late final food = _controller(widget.initialPlan.foodBudget);
  late final spent = _controller(widget.initialPlan.foodSpent);

  TextEditingController _controller(double value) =>
      TextEditingController(text: value == 0 ? '' : value.toStringAsFixed(2));

  double? _value(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.').trim());

  String? _validator(String? value) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.').trim());
    if (number == null || !number.isFinite || number < 0) {
      return 'Bitte einen gültigen Betrag ab 0 € eingeben';
    }
    return null;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final monthlyValue = _value(monthly)!;
    final foodValue = _value(food)!;
    final spentValue = _value(spent)!;
    final plan = BudgetPlan(
      monthlyBudget: monthlyValue,
      foodBudget: foodValue,
      foodSpent: spentValue,
    );
    try {
      await widget.store.save(plan);
      widget.onChanged(plan);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget konnte nicht gespeichert werden.')),
        );
      }
    }
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
      body: Form(
        key: formKey,
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BudgetSummary(snapshot: snapshot, plannedShop: widget.plannedShop),
          const SizedBox(height: 18),
          _MoneyField(controller: monthly, label: 'Verfügbares Monatsbudget', validator: _validator),
          const SizedBox(height: 12),
          _MoneyField(controller: food, label: 'Lebensmittelbudget', validator: _validator),
          const SizedBox(height: 12),
          _MoneyField(controller: spent, label: 'Diesen Monat bereits ausgegeben', validator: _validator),
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
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.label, required this.validator});
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: '€',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        validator: validator,
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
