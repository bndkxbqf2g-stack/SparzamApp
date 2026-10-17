import '../offers/offer_import.dart';
import '../../services/branch_identity.dart';
import '../../services/prospect_feed_service.dart';
import '../../services/store_identity.dart';

/// Stable UI grouping key for one prospect publication and its exact branch.
///
/// A missing branch ID deliberately keeps the legacy store-level key. The UI
/// may show such evidence, but it must not invent a branch. When a source
/// provides a branch ID, two stores with the same visible chain name remain
/// separate all the way through cover cards and article groups.
String prospectIssueKey(ProspectIssue issue) => prospectStoreBranchKey(
      storeName: issue.storeName,
      branchId: issue.branchId,
    );

String prospectRecordKey(OfferImportRecord record) =>
    prospectStoreBranchKey(
      storeName: record.storeName,
      branchId: record.branchId,
    );

/// Comparison key for a retailer label coming from two public feed
/// sections. Whitespace, case and German diacritics are presentation details;
/// punctuation is normalized by the shared store-identity helper. This key is
/// used only for matching metadata, never as a displayed name or a new branch
/// identity.
String prospectStoreMatchKey(String value) {
  final trimmed = value.trim();
  final normalized = normalizeStoreIdentityText(trimmed);
  if (normalized.isEmpty) return trimmed.toLowerCase();

  // Public feeds alternate between literal umlauts and the common ae/oe/ue
  // spelling. Collapse those transliterations only for metadata matching so
  // ALDI Süd and ALDI SUED stay one retailer while branch IDs remain exact.
  return normalized
      .replaceAll('ae', 'a')
      .replaceAll('oe', 'o')
      .replaceAll('ue', 'u');
}

/// Comparison key for an exact prospect branch. A missing branch remains a
/// store-level key; the helper never invents a location ID.
String prospectBranchMatchKey({
  required String storeName,
  String? branchId,
}) {
  final store = prospectStoreMatchKey(storeName);
  final branch = canonicalBranchId(branchId);
  return branch == null ? store : '$store#$branch';
}

String prospectIssueMatchKey(ProspectIssue issue) => prospectBranchMatchKey(
      storeName: issue.storeName,
      branchId: issue.branchId,
    );

String prospectRecordMatchKey(OfferImportRecord record) =>
    prospectBranchMatchKey(
      storeName: record.storeName,
      branchId: record.branchId,
    );

/// Stable persisted key for a favorite prospect cover. Legacy entries that
/// contain only the retailer name remain valid as a store-wide fallback.
String prospectFavoriteKey(ProspectIssue issue) => prospectIssueKey(issue);

/// Matches both new branch-specific favorites and legacy store-only entries.
bool prospectFavoriteMatches({
  required String storedKey,
  required ProspectIssue issue,
}) {
  final key = storedKey.trim();
  if (key.isEmpty) return false;
  final exact = prospectFavoriteKey(issue);
  if (key == exact) return true;
  final hasBranch = canonicalBranchId(issue.branchId) != null;
  return hasBranch && key == issue.storeName.trim();
}

String prospectStoreBranchKey({
  required String storeName,
  String? branchId,
}) {
  final store = storeName.trim();
  final branch = canonicalBranchId(branchId);
  if (branch == null) return store;
  return '$store#$branch';
}
