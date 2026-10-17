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

/// Pre-indexed favorite keys for the prospect cover lists.
///
/// Cover cards are built repeatedly while the user scrolls. Keeping the
/// persisted keys in a set makes the common branch-specific lookup constant
/// time while preserving the legacy store-wide fallback.
class ProspectFavoriteIndex {
  const ProspectFavoriteIndex.empty() : _keys = const <String>{};

  ProspectFavoriteIndex.from(Iterable<String> keys)
      : _keys = Set.unmodifiable(
          keys
              .map((key) => key.trim())
              .where((key) => key.isNotEmpty),
        );

  final Set<String> _keys;

  bool matches(ProspectIssue issue) {
    if (_keys.contains(prospectFavoriteKey(issue))) return true;
    return canonicalBranchId(issue.branchId) != null &&
        _keys.contains(issue.storeName.trim());
  }
}

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