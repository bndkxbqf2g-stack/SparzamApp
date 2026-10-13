enum ReceiptConfidenceLevel {
  belegt(
    label: 'BELEGT',
    description: 'Preis- und Belegdaten sind vorhanden; die konkrete Variante kann noch offen sein.',
  ),
  wahrscheinlich(
    label: 'WAHRSCHEINLICH',
    description: 'Eine Produktzuordnung ist vorhanden, aber noch nicht manuell bestätigt.',
  ),
  unsicher(
    label: 'UNSICHER',
    description: 'Die Belegzeile ist erkannt, die Produktidentität bleibt offen.',
  ),
  manuellBestaetigt(
    label: 'MANUELL_BESTÄTIGT',
    description: 'Die konkrete Produktzuordnung wurde ausdrücklich bestätigt.',
  );

  const ReceiptConfidenceLevel({
    required this.label,
    required this.description,
  });

  final String label;
  final String description;
}

/// Derives a conservative confidence level from the stored review state.
///
/// A receipt observation is never promoted to an exact route price merely by
/// having a confidence label. Exact route eligibility remains tied to the
/// existing explicit identity confirmation flag.
ReceiptConfidenceLevel receiptConfidenceFor({
  required String? productId,
  required bool identityConfirmed,
  required String familyKey,
}) {
  if (identityConfirmed && productId?.trim().isNotEmpty == true) {
    return ReceiptConfidenceLevel.manuellBestaetigt;
  }
  if (productId?.trim().isNotEmpty == true) {
    return ReceiptConfidenceLevel.wahrscheinlich;
  }
  if (familyKey.trim().isNotEmpty) {
    return ReceiptConfidenceLevel.belegt;
  }
  return ReceiptConfidenceLevel.unsicher;
}
