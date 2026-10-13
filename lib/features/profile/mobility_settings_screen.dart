import 'package:flutter/material.dart';

import '../../models/mobility_settings.dart';

class MobilitySettingsScreen extends StatefulWidget {
  const MobilitySettingsScreen({super.key, required this.initialSettings});

  final MobilitySettings initialSettings;

  @override
  State<MobilitySettingsScreen> createState() => _MobilitySettingsScreenState();
}

class _MobilitySettingsScreenState extends State<MobilitySettingsScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController addressController;
  late final TextEditingController fuelConsumptionController;
  late final TextEditingController fuelPriceController;
  late final TextEditingController savingsController;
  late final TextEditingController additionalStoreCostController;
  late final TextEditingController timeValueController;
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
    fuelConsumptionController = TextEditingController(
      text: widget.initialSettings.fuelConsumptionLitersPer100Km.toStringAsFixed(1),
    );
    fuelPriceController = TextEditingController(
      text: widget.initialSettings.fuelPricePerLiter.toStringAsFixed(2),
    );
    savingsController = TextEditingController(
      text: widget.initialSettings.minExtraStoreSavings.toStringAsFixed(2),
    );
    additionalStoreCostController = TextEditingController(
      text: widget.initialSettings.additionalStoreCost.toStringAsFixed(2),
    );
    timeValueController = TextEditingController(
      text: widget.initialSettings.timeValuePerHour.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    fuelConsumptionController.dispose();
    fuelPriceController.dispose();
    savingsController.dispose();
    additionalStoreCostController.dispose();
    timeValueController.dispose();
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
        fuelConsumptionLitersPer100Km: _number(fuelConsumptionController.text)!,
        fuelPricePerLiter: _number(fuelPriceController.text)!,
        mode: mode,
        maxStores: maxStores,
        minExtraStoreSavings: _number(savingsController.text)!,
        additionalStoreCost: _number(additionalStoreCostController.text)!,
        timeValuePerHour: _number(timeValueController.text)!,
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
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
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
            onSelectionChanged: (value) => setState(() => mode = value.first),
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
            controller: fuelConsumptionController,
            enabled: mode == MobilityMode.car,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Verbrauch',
              suffixText: 'l/100 km',
              prefixIcon: Icon(Icons.local_gas_station_outlined),
              helperText: 'Standard: 5,0 l E10 pro 100 km. Hin- und Rückfahrt werden berechnet.',
            ),
            validator: (value) {
              final number = _number(value ?? '');
              if (number == null || !number.isFinite || number <= 0 || number > 30) {
                return 'Bitte einen Verbrauch zwischen 0 und 30 l eingeben';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: fuelPriceController,
            enabled: mode == MobilityMode.car,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'E10-Preis',
              suffixText: '€/l',
              prefixIcon: Icon(Icons.euro_outlined),
              helperText: 'Der aktuelle E10-Preis kann hier jederzeit angepasst werden.',
            ),
            validator: (value) {
              final number = _number(value ?? '');
              if (number == null || !number.isFinite || number <= 0 || number > 10) {
                return 'Bitte einen E10-Preis zwischen 0 und 10 € eingeben';
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
            onChanged: (value) => setState(() => maxStores = value.round()),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: savingsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Mindestvorteil für zusätzlichen Markt',
              suffixText: '€',
              prefixIcon: Icon(Icons.savings_outlined),
              helperText: 'Ein weiterer Markt wird nur empfohlen, wenn er mindestens so viel spart.',
            ),
            validator: (value) {
              final number = _number(value ?? '');
              if (number == null ||
                  !number.isFinite ||
                  number < 0 ||
                  number > 50) {
                return 'Bitte gültigen Wert zwischen 0 und 50 € eingeben';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: additionalStoreCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Kosten je zusätzlichem Markt',
              suffixText: '€',
              prefixIcon: Icon(Icons.store_mall_directory_outlined),
              helperText:
                  'Optionaler Aufwand pro Markt ab dem zweiten; fließt nur in den Planungswert ein.',
            ),
            validator: (value) {
              final number = _number(value ?? '');
              if (number == null ||
                  !number.isFinite ||
                  number < 0 ||
                  number > 50) {
                return 'Bitte gültigen Wert zwischen 0 und 50 € eingeben';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('mobility-time-value'),
            controller: timeValueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Zeitwert für Wegezeit (optional)',
              suffixText: '€/Std.',
              prefixIcon: const Icon(Icons.schedule_outlined),
              helperText:
                  'Bei 0 € wird die Zeit angezeigt, aber nicht monetarisiert. '
                  'Mit einem Wert wird sie zusätzlich im Routenvergleich berücksichtigt.',
            ),
            validator: (value) {
              final number = _number(value ?? '');
              if (number == null ||
                  !number.isFinite ||
                  number < 0 ||
                  number > 100) {
                return 'Bitte gültigen Wert zwischen 0 und 100 € eingeben';
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

