import 'package:flutter/material.dart';

import '../../data/stores.dart';
import '../../models/mobility_settings.dart';
import '../../services/prospect_branch_resolver.dart';

class StoreSelectionScreen extends StatefulWidget {
  const StoreSelectionScreen({
    super.key,
    required this.initialSettings,
  });

  final MobilitySettings initialSettings;

  @override
  State<StoreSelectionScreen> createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends State<StoreSelectionScreen> {
  late Set<String> enabled;

  @override
  void initState() {
    super.initState();
    enabled = widget.initialSettings.enabledStoreNames.isEmpty
        ? stores.map((store) => store.name).toSet()
        : widget.initialSettings.enabledStoreNames.toSet();
  }

  void _save() {
    final allNames = stores.map((store) => store.name).toSet();
    final saveAsAll = enabled.length == allNames.length &&
        enabled.containsAll(allNames);
    final selected = enabled.toList()..sort();

    Navigator.pop(
      context,
      widget.initialSettings.copyWith(
        enabledStoreNames: saveAsAll ? const <String>[] : selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Meine Märkte')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Nur aktivierte Märkte werden für Routenvorschläge und '
              'Angebotshinweise berücksichtigt.',
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final resolved = const ProspectBranchResolver().resolve(
                  widget.initialSettings.startAddress,
                );
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_searching_outlined),
                    title: Text(
                      resolved.isEmpty
                          ? 'Keine neue Filiale sicher ermittelt'
                          : '${resolved.length} Filialen für den Startort erkannt',
                    ),
                    subtitle: Text(
                      resolved.isEmpty
                          ? 'Gespeicherte offizielle Markt-IDs bleiben erhalten.'
                          : 'Nur offiziell hinterlegte Markt-IDs werden verwendet.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < stores.length; index++) ...[
                    SwitchListTile(
                      value: enabled.contains(stores[index].name),
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            enabled.add(stores[index].name);
                          } else if (enabled.length > 1) {
                            enabled.remove(stores[index].name);
                          }
                        });
                      },
                      title: Text(stores[index].name),
                      subtitle: Text(
                        '${stores[index].location} · '
                        'Markt-ID: ${stores[index].branchId ?? 'nicht hinterlegt'}',
                      ),
                      secondary: const Icon(Icons.storefront_outlined),
                    ),
                    if (index < stores.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(
                () => enabled = stores.map((store) => store.name).toSet(),
              ),
              child: const Text('Alle Märkte aktivieren'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Speichern'),
            ),
          ],
        ),
      );
}
