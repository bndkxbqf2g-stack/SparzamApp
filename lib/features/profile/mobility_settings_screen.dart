import 'package:flutter/material.dart';

import '../../models/mobility_settings.dart';

class MobilitySettingsScreen extends StatefulWidget {
  const MobilitySettingsScreen({
    super.key,
    required this.initialSettings,
  });

  final MobilitySettings initialSettings;

  @override
  State<MobilitySettingsScreen> createState() =>
      _MobilitySettingsScreenState();
}

class _MobilitySettingsScreenState extends State<MobilitySettingsScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController addressController;
  late final TextEditingController costController;

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController(
      text: widget.initialSettings.startAddress,
    );
    costController = TextEditingController(
      text: widget.initialSettings.euroPerKm.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    costController.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final cost = double.parse(costController.text.replaceAll(',', '.'));

    Navigator.pop(
      context,
      MobilitySettings(
        startAddress: addressController.text.trim(),
        euroPerKm: cost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mobilität')),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: addressController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Startort',
                  hintText: 'Straße, PLZ und Ort',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Startort eingeben' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: costController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fahrtkosten pro km',
                  suffixText: '€/km',
                  prefixIcon: Icon(Icons.euro_outlined),
                ),
                validator: (value) {
                  final number =
                      double.tryParse((value ?? '').replaceAll(',', '.'));
                  if (number == null || number < 0 || number > 5) {
                    return 'Bitte gültigen Wert zwischen 0 und 5 € eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Die App rechnet die Strecke als Hin- und Rückfahrt. '
                'Änderst du den Startort, werden gespeicherte Straßenstrecken '
                'für den neuen Startort neu ermittelt.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Speichern'),
              ),
            ],
          ),
        ),
      );
}
