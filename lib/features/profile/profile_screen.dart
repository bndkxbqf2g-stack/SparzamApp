import 'package:flutter/material.dart';

import '../../models/mobility_settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.mobility,
    required this.onEditMobility,
    required this.onEditStores,
    required this.storeCount,
    required this.onOpenCatalog,
    required this.productCount,
    required this.onEditPriceData,
    required this.priceDataSummary,
    required this.onOpenDiagnostics,
  });

  final MobilitySettings mobility;
  final VoidCallback onEditMobility;
  final VoidCallback onEditStores;
  final int storeCount;
  final VoidCallback onOpenCatalog;
  final int productCount;
  final VoidCallback onEditPriceData;
  final String priceDataSummary;
  final VoidCallback onOpenDiagnostics;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text(
            'Profil',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.login),
                  title: Text('Mit Apple anmelden'),
                  subtitle: Text('Kommt mit Supabase in einem späteren Sprint'),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: onEditMobility,
                  leading: Icon(
                    switch (mobility.mode) {
                      MobilityMode.car => Icons.directions_car_outlined,
                      MobilityMode.bike => Icons.directions_bike_outlined,
                      MobilityMode.walk => Icons.directions_walk_outlined,
                    },
                  ),
                  title: const Text('Mobilität & Route'),
                  subtitle: Text(
                    '${mobility.mode.label} · '
                    '${mobility.effectiveEuroPerKm.toStringAsFixed(2)} €/km · '
                    'max. ${mobility.maxStores} Märkte',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: onOpenCatalog,
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Produktkatalog'),
                  subtitle: Text('$productCount Produkte · eigene Preise verwalten'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: onEditPriceData,
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Preisdaten'),
                  subtitle: Text(priceDataSummary),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: onEditStores,
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Meine Märkte'),
                  subtitle: Text('$storeCount Märkte für Empfehlungen aktiv'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: onOpenDiagnostics,
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Diagnoseprotokoll'),
                  subtitle: const Text('Fehler für den Praxistest erfassen und kopieren'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Startort'),
              subtitle: Text(mobility.startAddress),
            ),
          ),
        ],
      );
}
