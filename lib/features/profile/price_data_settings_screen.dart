import 'package:flutter/material.dart';

import '../../models/price_data_settings.dart';

class PriceDataSettingsScreen extends StatefulWidget {
  const PriceDataSettingsScreen({
    super.key,
    required this.initialSettings,
  });

  final PriceDataSettings initialSettings;

  @override
  State<PriceDataSettingsScreen> createState() =>
      _PriceDataSettingsScreenState();
}

class _PriceDataSettingsScreenState extends State<PriceDataSettingsScreen> {
  late bool enabled;
  late bool autoSync;
  late int maxAgeDays;

  @override
  void initState() {
    super.initState();
    enabled = widget.initialSettings.openPricesEnabled;
    autoSync = widget.initialSettings.autoSyncOnCatalogOpen;
    maxAgeDays = widget.initialSettings.openPricesMaxAgeDays;
  }

  void save() => Navigator.pop(
        context,
        PriceDataSettings(
          openPricesEnabled: enabled,
          openPricesMaxAgeDays: maxAgeDays,
          autoSyncOnCatalogOpen: enabled && autoSync,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Preisdaten')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: enabled,
                    onChanged: (value) => setState(() => enabled = value),
                    secondary: const Icon(Icons.cloud_outlined),
                    title: const Text('Open Prices verwenden'),
                    subtitle: const Text(
                      'Öffentliche Crowdsourcing-Preise als zusätzliche Quelle.',
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: enabled && autoSync,
                    onChanged: enabled
                        ? (value) => setState(() => autoSync = value)
                        : null,
                    secondary: const Icon(Icons.sync_outlined),
                    title: const Text('Beim Öffnen des Katalogs aktualisieren'),
                    subtitle: const Text(
                      'Produkte mit EAN werden automatisch geprüft.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Open-Prices-Daten maximal $maxAgeDays Tage alt',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Slider(
              value: maxAgeDays.toDouble(),
              min: 14,
              max: 180,
              divisions: 83,
              label: '$maxAgeDays Tage',
              onChanged: enabled
                  ? (value) => setState(() => maxAgeDays = value.round())
                  : null,
            ),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Priorität: Eigene Preise > aktuelle Open-Prices-Daten > '
                  'hinterlegte Basispreise. Veraltete Open-Prices-Daten werden '
                  'nicht für die Routenberechnung verwendet.',
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Speichern'),
            ),
          ],
        ),
      );
}
