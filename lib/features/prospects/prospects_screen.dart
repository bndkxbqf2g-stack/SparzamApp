import 'package:flutter/material.dart';

import '../../design/sparzam_theme.dart';

class ProspectsScreen extends StatelessWidget {
  const ProspectsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.menu_book_outlined,
              color: SparzamTheme.deepGreen, size: 28),
          const SizedBox(height: 8),
          Text('Prospekte',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const Center(child: Text('Alle Angebote. An einem Ort.')),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 48, color: SparzamTheme.sage),
                  SizedBox(height: 16),
                  Text('Hier erscheinen deine Prospekte',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text(
                    'Für die ausgewählten Märkte sind noch keine zur '
                    'Einbindung freigegebenen Prospekte verfügbar. '
                    'Geprüfte Einzelangebote findest du unter Angebote.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
