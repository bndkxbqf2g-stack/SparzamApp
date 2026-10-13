import '../data/stores.dart';
import '../models/store.dart';

/// Returns a comparison key for a source/store branch identifier.
///
/// Providers occasionally vary only in whitespace or letter case when the
/// same branch is returned through different endpoints. We intentionally do
/// not remove punctuation or invent aliases: a different identifier remains
/// a different branch until an adapter explicitly maps it.
String? canonicalBranchId(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.toLowerCase();
}

/// Checks a source location against the one configured branch for a store.
///
/// A missing source location remains a legacy-compatible fallback. If the
/// application has no unique branch configured for the store, the source is
/// also left usable because there is no deterministic branch to compare it
/// with. Once both sides identify a branch, different identifiers never
/// silently match.
bool matchesConfiguredBranch(
  String storeName,
  String? sourceLocationId, {
  Iterable<Store> configuredStores = stores,
}) {
  final source = canonicalBranchId(sourceLocationId);
  if (source == null) return true;
  final configured = configuredStores
      .where((store) => store.name == storeName)
      .toList(growable: false);
  if (configured.length != 1) return true;
  final branchId = canonicalBranchId(configured.single.branchId);
  return branchId == null || branchId == source;
}
