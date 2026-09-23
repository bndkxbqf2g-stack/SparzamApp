import 'package:flutter/material.dart';

class ProspectsScreen extends StatelessWidget {
  const ProspectsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Prospekte', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Für die ausgewählten Märkte liegen noch keine zur '
                'Einbindung freigegebenen blätterbaren Prospekte vor. '
                'Geprüfte Einzelangebote findest du unter Angebote.',
              ),
            ),
          ),
        ],
      );
}
