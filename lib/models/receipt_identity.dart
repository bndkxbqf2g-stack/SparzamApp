enum ReceiptIdentityState {
  confirmed,
  provisional,
  familyOnly,
  unresolved,
}

class ReceiptIdentityAssessment {
  const ReceiptIdentityAssessment({
    required this.state,
    required this.confidence,
    required this.exactRouteEligible,
    required this.label,
    required this.reason,
  });

  final ReceiptIdentityState state;
  final double confidence;
  final bool exactRouteEligible;
  final String label;
  final String reason;

  String get summary => '$label · $reason';
}

/// Keeps product assignment separate from product identity confirmation.
///
/// A provisional product id is useful for catalog growth and later review but
/// must not by itself qualify an exact route price.
ReceiptIdentityAssessment assessReceiptIdentity({
  String? productId,
  bool identityConfirmed = false,
  String familyKey = '',
}) {
  if (productId?.isNotEmpty == true && identityConfirmed) {
    return const ReceiptIdentityAssessment(
      state: ReceiptIdentityState.confirmed,
      confidence: 1,
      exactRouteEligible: true,
      label: 'Identität bestätigt',
      reason: 'Konkrete Produktzuordnung wurde bestätigt.',
    );
  }
  if (productId?.isNotEmpty == true) {
    return const ReceiptIdentityAssessment(
      state: ReceiptIdentityState.provisional,
      confidence: 0,
      exactRouteEligible: false,
      label: 'Identität vorläufig',
      reason: 'Automatische oder noch nicht bestätigte Produktzuordnung.',
    );
  }
  if (familyKey.trim().isNotEmpty) {
    return const ReceiptIdentityAssessment(
      state: ReceiptIdentityState.familyOnly,
      confidence: 0,
      exactRouteEligible: false,
      label: 'Nur Produktfamilie erkannt',
      reason: 'Konkrete Variante oder Produktidentität ist noch offen.',
    );
  }
  return const ReceiptIdentityAssessment(
    state: ReceiptIdentityState.unresolved,
    confidence: 0,
    exactRouteEligible: false,
    label: 'Identität offen',
    reason: 'Keine belastbare Produktidentität erkannt.',
  );
}
