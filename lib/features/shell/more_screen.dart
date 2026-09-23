import 'package:flutter/material.dart';

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

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Sparzam')),
          body: SafeArea(child: page),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Mehr', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.route_outlined),
            title: const Text('Einkaufsroute'),
            onTap: () => _open(context, routePage),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Bons und Einkäufe'),
            onTap: () => _open(context, receiptPage),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profil und Einstellungen'),
            onTap: () => _open(context, profilePage),
          ),
        ],
      );
}
