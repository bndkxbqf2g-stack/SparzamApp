import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/sparzam_theme.dart';

/// Händlerseiten bleiben externe Quellen; ihre Angebote werden nicht als
/// geprüfte, lokal gespeicherte Sparzam-Angebote ausgegeben.
class OfficialOfferLinks extends StatelessWidget {
  const OfficialOfferLinks({super.key});

  static const _sources = <(String, String)>[
    ('Lidl', 'https://www.lidl.de/c/online-prospekte/s10005610/'),
    ('EDEKA', 'https://www.edeka.de/angebote/'),
    ('PENNY', 'https://www.penny.de/angebote'),
    ('ALDI Süd', 'https://www.aldi-sued.de/angebote'),
    ('Netto', 'https://www.netto-online.de/filialangebote'),
    ('REWE', 'https://www.rewe.de/angebote/nationale-angebote/'),
    ('Kaufland', 'https://filiale.kaufland.de/angebote.html'),
  ];

  Future<void> _open(BuildContext context, String url) async {
    bool opened;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Angebotsseite konnte nicht geöffnet werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weitere aktuelle Angebote',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Direkt beim Händler ansehen. Preise und Gültigkeit '
            'hängen vom gewählten Markt ab.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final source in _sources)
                ActionChip(
                  avatar: const Icon(Icons.open_in_new,
                      size: 16, color: SparzamTheme.deepGreen),
                  label: Text(source.$1),
                  onPressed: () => _open(context, source.$2),
                ),
            ],
          ),
        ],
      );
}
