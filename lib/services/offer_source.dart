import '../models/offer_observation.dart';

/// Result of an offer source refresh.
///
/// `available == false` means the source is unknown/unavailable. An empty
/// successful result is distinct from that state and must not be shown as a
/// zero-price or zero-availability claim.
class OfferSourceResult {
  const OfferSourceResult({
    required this.observations,
    required this.available,
    this.errorCode,
  });

  const OfferSourceResult.unavailable(this.errorCode)
      : observations = const <OfferObservation>[],
        available = false;

  const OfferSourceResult.empty()
      : observations = const <OfferObservation>[],
        available = true,
        errorCode = null;

  final List<OfferObservation> observations;
  final bool available;
  final String? errorCode;
}

/// Common boundary for optional retailer offer adapters.
abstract interface class OfferSource {
  String get source;
  bool get enabled;

  Future<OfferSourceResult> fetchCurrent({
    required String exactStore,
    DateTime? now,
  });

  void close();
}

/// Lidl's unofficial adapter remains deliberately unconfigured.
///
/// The public wrapper was evaluated as a reference only. Until a documented,
/// permitted retailer feed is configured, this source never performs a
/// network request and reports its state as unknown.
class LidlOfferSource implements OfferSource {
  const LidlOfferSource({this.enabled = false});

  @override
  final bool enabled;

  @override
  String get source => 'lidl';

  @override
  Future<OfferSourceResult> fetchCurrent({
    required String exactStore,
    DateTime? now,
  }) async =>
      OfferSourceResult.unavailable(
        enabled ? 'adapter_not_configured' : 'source_disabled',
      );

  @override
  void close() {}
}

/// Kaufland's unofficial adapter remains deliberately unconfigured.
///
/// It follows the same safety boundary as [LidlOfferSource].
class KauflandOfferSource implements OfferSource {
  const KauflandOfferSource({this.enabled = false});

  @override
  final bool enabled;

  @override
  String get source => 'kaufland';

  @override
  Future<OfferSourceResult> fetchCurrent({
    required String exactStore,
    DateTime? now,
  }) async =>
      OfferSourceResult.unavailable(
        enabled ? 'adapter_not_configured' : 'source_disabled',
      );

  @override
  void close() {}
}
