import 'package:flutter/material.dart';

class PurchaseMoneyEditor extends StatelessWidget {
  const PurchaseMoneyEditor({
    super.key,
    required this.basketController,
    required this.travelController,
    required this.baselineController,
  });

  final TextEditingController basketController;
  final TextEditingController travelController;
  final TextEditingController baselineController;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _MoneyField(
                controller: basketController,
                label: 'Warenkorb',
              ),
              const SizedBox(height: 12),
              _MoneyField(
                controller: travelController,
                label: 'Fahrtkosten',
              ),
              const SizedBox(height: 12),
              _MoneyField(
                controller: baselineController,
                label: 'Vergleichswert',
              ),
            ],
          ),
        ),
      );
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
}
