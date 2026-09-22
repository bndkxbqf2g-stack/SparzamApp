import 'package:flutter/material.dart';

import '../../models/mobility_settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.mobility,
    required this.onEditMobility,
  });

  final MobilitySettings mobility;
  final VoidCallback onEditMobility;

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
                  leading: const Icon(Icons.directions_car_outlined),
                  title: const Text('Mobilität'),
                  subtitle: Text(
                    '${mobility.euroPerKm.toStringAsFixed(2)} €/km · '
                    '${mobility.startAddress}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.storefront_outlined),
                  title: Text('Meine Märkte'),
                  subtitle: Text('7 Märkte im aktuellen MVP'),
                ),
              ],
            ),
          ),
        ],
      );
}
