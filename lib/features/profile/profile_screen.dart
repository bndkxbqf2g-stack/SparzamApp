import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
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
            children: const [
              ListTile(
                leading: Icon(Icons.login),
                title: Text('Mit Apple anmelden'),
                subtitle: Text('Kommt mit Supabase im nächsten Sprint'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.directions_car_outlined),
                title: Text('Mobilität'),
                subtitle: Text('Auto · Testwert 0,22 €/km'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.storefront_outlined),
                title: Text('Meine Märkte'),
                subtitle: Text('7 Märkte im Zellingen-MVP'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
