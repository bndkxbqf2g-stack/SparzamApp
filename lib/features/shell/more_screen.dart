import 'package:flutter/material.dart';

import '../../design/sparzam_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.routePage,
    required this.receiptPage,
    required this.profilePage,
  });

  final Widget routePage;
  final Widget receiptPage;
  final Widget profilePage;

  void _open(BuildContext context, String title, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(child: page),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.spa_outlined, color: SparzamTheme.deepGreen, size: 28),
          const SizedBox(height: 8),
          Text('Mehr', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const Center(child: Text('Deine Einstellungen. Dein Vorteil.')),
          const SizedBox(height: 24),
          Card(child: ListTile(
            leading: const Icon(Icons.route_outlined, color: SparzamTheme.deepGreen),
            title: const Text('Einkaufsroute'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, 'Einkaufsroute', routePage),
          )),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: SparzamTheme.deepGreen),
            title: const Text('Bons und Einkäufe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, 'Bons und Einkäufe', receiptPage),
          )),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Icon(Icons.person_outline, color: SparzamTheme.deepGreen),
            title: const Text('Profil und Einstellungen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, 'Profil und Einstellungen', profilePage),
          )),
        ],
      );
}
