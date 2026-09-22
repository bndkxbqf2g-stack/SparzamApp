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
  late final TextEditingController savingsController;
  late MobilityMode mode;
  late int maxStores;

  @override
  void initState() {
    super.initState();
    mode = widget.initialSettings.mode;
    maxStores = widget.initialSettings.maxStores;
    addressController = TextEditingController(
      text: widget.initialSettings.startAddress,
    );
    costController = TextEditingController(
      text: widget.initialSettings.euroPerKm.toStringAsFixed(2),
    );
    savingsController = TextEditingController(
      text: widget.initialSettings.minExtraStoreSavings.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    costController.dispose();
    savingsController.dispose();
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.replaceAll(',', '.').trim());

  void _save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      widget.initialSettings.copyWith(
        startAddress: addressController.text.trim(),
        euroPerKm: _number(costController.text)!,
        mode: mode,
        maxStores: maxStores,
        minExtraStoreSavings: _number(savingsController.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mobilität & Route')),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Verkehrsmittel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<MobilityMode>(
                segments: const [
                  ButtonSegment(
                    value: MobilityMode.car,
                    icon: Icon(Icons.directions_car_outlined),
                    label: Text('Auto'),
                  ),
                  ButtonSegment(
                    value: MobilityMode.bike,
                    icon: Icon(Icons.directions_bike_outlined),
                    label: Text('Rad'),
                  ),
                  ButtonSegment(
                    value: MobilityMode.walk,
                    icon: Icon(Icons.directions_walk_outlined),
                    label: Text('Fuß'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (value) =>
                    setState(() => mode = value.first),
              ),
              const SizedBox(height: 20),
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
                enabled: mode == MobilityMode.car,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Fahrtkosten pro km',
                  suffixText: '€/km',
                  prefixIcon: const Icon(Icons.euro_outlined),
                  helperText: mode == MobilityMode.car
                      ? 'Wird für Hin- und Rückfahrt berechnet.'
                      : 'Bei Fahrrad und zu Fuß: 0,00 € Fahrtkosten.',
                ),
                validator: (value) {
                  final number = _number(value ?? '');
                  if (number == null || number < 0 || number > 5) {
                    return 'Bitte gültigen Wert zwischen 0 und 5 € eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Maximal $maxStores ${maxStores == 1 ? 'Markt' : 'Märkte'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Slider(
                value: maxStores.toDouble(),
                min: 1,
                max: 3,
                divisions: 2,
                label: maxStores.toString(),
                onChanged: (value) =>
                    setState(() => maxStores = value.round()),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: savingsController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Mindestvorteil für zusätzlichen Markt',
                  suffixText: '€',
                  prefixIcon: Icon(Icons.savings_outlined),
                  helperText:
                      'Ein weiterer Markt wird nur empfohlen, wenn er mindestens so viel spart.',
                ),
                validator: (value) {
                  final number = _number(value ?? '');
                  if (number == null || number < 0 || number > 50) {
                    return 'Bitte gültigen Wert zwischen 0 und 50 € eingeben';
                  }
                  return null;
                },
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
