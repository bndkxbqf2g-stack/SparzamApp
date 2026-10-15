import '../offers/offer_import.dart';
import '../../services/branch_identity.dart';
import '../../services/prospect_feed_service.dart';

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

String prospectStoreBranchKey({
  required String storeName,
  String? branchId,
}) {
  final store = storeName.trim();
  final branch = canonicalBranchId(branchId);
  if (branch == null) return store;
  return '$store#$branch';
}
