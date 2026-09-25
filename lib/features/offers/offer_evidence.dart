import 'package:flutter/material.dart';

import '../../models/offer.dart';

class OfferEvidence extends StatelessWidget {
  const OfferEvidence({super.key, required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final proofRef = offer.proofRef?.trim();
    final imageUrl = offer.imageUrl?.trim();
    final hasProof = proofRef != null && proofRef.isNotEmpty;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          'Quelle: ${_sourceLabel(offer.source)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          _validityLabel(offer),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (hasProof) ...[
          const SizedBox(height: 4),
          Text(
            'Beleg: $proofRef',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (hasImage) ...[
          const SizedBox(height: 8),
          Semantics(
            label: 'Prospektbild',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                height: 96,
                width: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 72,
                  width: 140,
                  alignment: Alignment.center,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Text('Prospektbild\nnicht verfügbar', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _validityLabel(Offer offer) {
    final from = offer.validFrom;
    if (from == null) return 'Gültig bis ${_date(offer.validUntil)}';
    return 'Gültig ${_date(from)}–${_date(offer.validUntil)}';
  }

  String _sourceLabel(String source) => switch (source.trim().toLowerCase()) {
        'leaflet' => 'Prospekt',
        'retailer' => 'Händler',
        'retailerwebsite' => 'Händler-Website',
        'receipt' => 'Kassenbon',
        'manual' => 'Manuell',
        'openprices' || 'open_prices' => 'Open Prices',
        _ => source.trim().isEmpty ? 'Unbekannt' : source.trim(),
      };

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
