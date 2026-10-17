import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/price_observation.dart';
import 'sequential_operation_queue.dart';

typedef PriceObservationRawReader = Future<List<String>?> Function();
typedef PriceObservationRawWriter = Future<void> Function(List<String> values);

const maxAutomaticPriceObservations = 2000;
const maxAutomaticPriceObservationsPerKey = 3;

/// Keeps user evidence intact while bounding repeated external observations.
/// Prospect and Open Prices history is useful for comparison, but an
/// unbounded JSON list cannot be stored reliably in browser preferences.
List<PriceObservation> compactPriceObservationsForStorage(
  Iterable<PriceObservation> observations, {
  int maxAutomaticEntries = maxAutomaticPriceObservations,
  int maxEntriesPerKey = maxAutomaticPriceObservationsPerKey,
}) {
  final input = observations.toList(growable: false);
  final automaticByKey = <String, List<PriceObservation>>{};
  for (final observation in input) {
    if (!_isAutomaticPriceObservation(observation)) continue;
    automaticByKey
        .putIfAbsent(_automaticPriceObservationKey(observation), () => [])
        .add(observation);
  }

  final perKeyLimit = maxEntriesPerKey < 0 ? 0 : maxEntriesPerKey;
  final candidates = <PriceObservation>[];
  for (final group in automaticByKey.values) {
    final newest = List<PriceObservation>.of(group)
      ..sort(_newestPriceObservationFirst);
    candidates.addAll(newest.take(perKeyLimit));
  }
  candidates.sort(_newestPriceObservationFirst);

  final entryLimit = maxAutomaticEntries < 0 ? 0 : maxAutomaticEntries;
  final retainedAutomaticIds = candidates
      .take(entryLimit)
      .map((observation) => observation.id)
      .toSet();

  return input
      .where(
        (observation) =>
            !_isAutomaticPriceObservation(observation) ||
            retainedAutomaticIds.contains(observation.id),
      )
      .toList(growable: false);
}

bool _isAutomaticPriceObservation(PriceObservation observation) => switch (
      observation.source
    ) {
      PriceObservationSource.retailer ||
      PriceObservationSource.retailerWebsite ||
      PriceObservationSource.leaflet ||
      PriceObservationSource.openPrices ||
      PriceObservationSource.estimate => true,
      _ => false,
    };

bool _isAutomaticProspectRegularObservation(
  PriceObservation observation,
) =>
    observation.kind == PriceObservationKind.regular &&
    !observation.discounted &&
    switch (observation.source) {
      PriceObservationSource.retailer ||
      PriceObservationSource.retailerWebsite ||
      PriceObservationSource.leaflet => true,
      _ => false,
    };

/// A delayed cache refresh must not overwrite newer automatic evidence that
/// arrived from a live feed. Manual and receipt corrections retain the
/// existing identity-reinterpretation semantics.
bool _shouldReplaceObservation(
  PriceObservation? previous,
  PriceObservation incoming,
) {
  if (previous == null) return true;
  if (_isAutomaticPriceObservation(previous) &&
      _isAutomaticPriceObservation(incoming) &&
      incoming.observedAt.isBefore(previous.observedAt)) {
    return false;
  }
  return true;
}

/// Adapter provenance stays in the compaction key so independent external
/// sources do not evict one another from the bounded local history.
String _automaticPriceObservationKey(PriceObservation observation) => [
      observation.source.name,
      observation.sourceAdapter?.trim().toLowerCase() ?? '',
      observation.storeName.trim().toLowerCase(),
      observation.locationId?.trim().toLowerCase() ?? '',
      observation.region?.trim().toLowerCase() ?? '',
      observation.productId?.trim() ?? '',
      observation.familyKey?.trim() ?? '',
      observation.variant?.trim().toLowerCase() ?? '',
      observation.kind.name,
      observation.quantity?.toString() ?? '',
      observation.unit?.trim().toLowerCase() ?? '',
    ].join('\u001f');

int _newestPriceObservationFirst(
  PriceObservation a,
  PriceObservation b,
) {
  // The current projection is the routeable local basis. Keep it ahead of
  // older history when the bounded automatic ledger is compacted; otherwise a
  // long-lived store could silently lose the only current regular price.
  if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
  final byDate = b.observedAt.compareTo(a.observedAt);
  return byDate == 0 ? b.id.compareTo(a.id) : byDate;
}

bool _isQuotaExceededError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('quotaexceedederror') ||
      text.contains('quota exceeded') ||
      text.contains('storage quota');
}

/// Local price evidence for small, user-relevant data sets. Protected user
/// evidence remains available while repeated external observations are bounded.
class PriceObservationStore {
  PriceObservationStore({
    SharedPreferencesAsync? preferences,
    PriceObservationRawReader? readRaw,
    PriceObservationRawWriter? writeRaw,
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _readRawOverride = readRaw,
        _writeRawOverride = writeRaw;

  static const storageKey = 'price_observations_v1';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences;
  final PriceObservationRawReader? _readRawOverride;
  final PriceObservationRawWriter? _writeRawOverride;

  Future<List<PriceObservation>> load() => _queue.schedule(_loadNow);

  Future<List<PriceObservation>> _loadNow() async {
    final raw = await _readRaw() ?? const [];
    final observations = <PriceObservation>[];
    for (final value in raw) {
      try {
        observations.add(
          PriceObservation.fromJson(jsonDecode(value) as Map<String, dynamic>),
        );
      } catch (_) {
        // A corrupt entry does not hide the remaining price evidence.
      }
    }
    return observations;
  }

  Future<List<PriceObservation>> append(Iterable<PriceObservation> incoming) {
    final valid = incoming.where((entry) => entry.isValid).toList();
    return _queue.schedule(() async {
      final existing = await _loadNow();
      final ids = existing.map((entry) => entry.id).toSet();
      final additions = valid.where((entry) => ids.add(entry.id)).toList();
      if (additions.isEmpty) return existing;
      final next = [...existing, ...additions];
      return _persist(next);
    });
  }

  /// Upserts only automatically learned regular prospect prices.
  ///
  /// This boundary deliberately rejects offer amounts and discounted markers
  /// before they reach local automatic price history. Manual, receipt and
  /// explicitly saved offer evidence continue to use [upsertById].
  Future<List<PriceObservation>> upsertAutomaticRegularById(
    Iterable<PriceObservation> incoming, {
    bool Function(PriceObservation observation)? removeWhere,
    PriceObservation Function(PriceObservation observation)? rewriteExisting,
  }) {
    final regular = incoming.where(_isAutomaticProspectRegularObservation);
    return upsertById(
      regular,
      removeWhere: removeWhere,
      rewriteExisting: rewriteExisting,
    );
  }

  /// Replaces evidence with the same stable ID. This is reserved for
  /// deterministic derived observations (for example reinterpreted receipts),
  /// so identity improvements do not leave stale projections behind.
  /// Replaces matching IDs and can remove a narrowly scoped obsolete
  /// projection in the same serialized read/modify/write operation.
  Future<List<PriceObservation>> upsertById(
    Iterable<PriceObservation> incoming, {
    bool Function(PriceObservation observation)? removeWhere,
    PriceObservation Function(PriceObservation observation)? rewriteExisting,
  }) {
    final valid = incoming.where((entry) => entry.isValid).toList();
    return _queue.schedule(() async {
      final existing = await _loadNow();
      final byId = <String, PriceObservation>{};
      var changed = false;
      for (final entry in existing) {
        if (removeWhere?.call(entry) ?? false) {
          changed = true;
          continue;
        }
        final rewritten = rewriteExisting?.call(entry) ?? entry;
        if (jsonEncode(rewritten.toJson()) != jsonEncode(entry.toJson())) {
          changed = true;
        }
        byId[rewritten.id] = rewritten;
      }
      if (byId.length != existing.length) changed = true;
      for (final entry in valid) {
        final previous = byId[entry.id];
        if (!_shouldReplaceObservation(previous, entry)) continue;
        final previousJson = previous == null
            ? null
            : jsonEncode(previous.toJson());
        final nextJson = jsonEncode(entry.toJson());
        if (previousJson != nextJson) changed = true;
        byId[entry.id] = entry;
      }
      if (!changed) return existing;
      final next = byId.values.toList(growable: false);
      return _persist(next);
    });
  }

  Future<List<PriceObservation>> replaceAll(
    Iterable<PriceObservation> observations,
  ) {
    final valid = observations.where((entry) => entry.isValid).toList();
    return _queue.schedule(() => _persist(valid));
  }

  Future<List<PriceObservation>> _persist(
    Iterable<PriceObservation> observations,
  ) async {
    final compacted = compactPriceObservationsForStorage(observations);
    try {
      await _writeRaw(
        compacted.map((entry) => jsonEncode(entry.toJson())).toList(),
      );
      return compacted;
    } catch (error) {
      if (!_isQuotaExceededError(error)) rethrow;
      // A smaller second attempt also repairs an already oversized legacy
      // store. Protected receipt/manual evidence is never removed here.
      final reduced = compactPriceObservationsForStorage(
        observations,
        maxAutomaticEntries: maxAutomaticPriceObservations ~/ 2,
        maxEntriesPerKey: 1,
      );
      await _writeRaw(
        reduced.map((entry) => jsonEncode(entry.toJson())).toList(),
      );
      return reduced;
    }
  }

  Future<List<String>?> _readRaw() =>
      _readRawOverride?.call() ?? _preferences.getStringList(storageKey);

  Future<void> _writeRaw(List<String> values) =>
      _writeRawOverride?.call(values) ??
      _preferences.setStringList(storageKey, values);
}
