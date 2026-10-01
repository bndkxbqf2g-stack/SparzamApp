import 'package:flutter/material.dart';

/// Makes the age and provenance of the public prospect feed visible wherever
/// current offers are shown. The timestamp is informational; offer validity
/// is still checked per record before it can be displayed or routed.
class ProspectFeedStatusCard extends StatelessWidget {
  const ProspectFeedStatusCard({
    super.key,
    this.generatedAt,
    this.fromCache = false,
  });

  final DateTime? generatedAt;
  final bool fromCache;

  @override
  Widget build(BuildContext context) {
    if (generatedAt == null && !fromCache) return const SizedBox.shrink();
    final timestamp = formatProspectFeedTimestamp(generatedAt);
    final theme = Theme.of(context);
    return Card(
      color: fromCache ? theme.colorScheme.surfaceContainerHighest : null,
      child: ListTile(
        leading: Icon(
          fromCache ? Icons.cloud_off_outlined : Icons.verified_outlined,
        ),
        title: Text(
          fromCache
              ? 'Letzter geprüfter Prospektstand'
              : 'Aktueller Prospektstand',
        ),
        subtitle: Text(
          fromCache
              ? 'Stand $timestamp. Der Live-Abruf war nicht verfügbar; '
                    'Gültigkeiten werden weiterhin geprüft, abgelaufene Angebote '
                    'bleiben ausgeblendet.'
              : 'Stand $timestamp. Es werden nur aktuell gültige Angebote '
                    'angezeigt.',
        ),
      ),
    );
  }
}

String formatProspectFeedTimestamp(DateTime? value) {
  if (value == null) return 'Zeitpunkt unbekannt';
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} · $hour:$minute Uhr';
}
