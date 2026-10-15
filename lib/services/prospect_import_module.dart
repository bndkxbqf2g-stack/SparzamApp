import 'package:http/http.dart' as http;

import 'prospect_feed_service.dart';
import 'prospect_branch_resolver.dart';
import 'prospect_feed_cache.dart';

/// Orchestrates the complete prospect import boundary.
///
/// Retailer-specific acquisition remains in the refresh workflow and its
/// official source adapters. The app consumes one validated, status-aware
/// result and never treats an unavailable retailer as an empty successful feed.
class ProspectImportModule {
  ProspectImportModule({
    http.Client? client,
    ProspectFeedCache? cache,
    bool networkEnabled = true,
  }) : _feedService = ProspectFeedService(
         client: client,
         cache: cache,
         networkEnabled: networkEnabled,
       );

  final ProspectFeedService _feedService;
  final ProspectBranchResolver _branchResolver = const ProspectBranchResolver();

  void close() => _feedService.close();

  Future<ProspectFeedLoadResult> execute({String? startAddress}) async {
    final feed = await _feedService.load();
    return _withResolvedBranches(feed, startAddress: startAddress);
  }

  /// Loads a validated cache or bundled feed without network access. This is
  /// intentionally separate from [execute], so callers can render quickly and
  /// still perform a normal refresh afterwards.
  Future<ProspectFeedLoadResult?> executeCached({String? startAddress}) async {
    final feed = await _feedService.loadCached();
    if (feed == null) return null;
    return _withResolvedBranches(feed, startAddress: startAddress);
  }

  ProspectFeedLoadResult _withResolvedBranches(
    ProspectFeedLoadResult feed, {
    String? startAddress,
  }) {
    if (startAddress == null || startAddress.trim().isEmpty) return feed;

    final branches = resolveBranches(startAddress);
    final urls = <String, String>{
      for (final branch in branches) branch.storeName: branch.officialUrl,
    };
    final prospects = feed.prospects
        .map(
          (issue) => urls.containsKey(issue.storeName)
              ? ProspectIssue(
                  storeName: issue.storeName,
                  title: issue.title,
                  pages: issue.pages,
                  url: urls[issue.storeName],
                  thumbnailUrl: issue.thumbnailUrl,
                  branchId: issue.branchId,
                  location: issue.location,
                  address: issue.address,
                  sourceStatus: issue.sourceStatus,
                  recordCount: issue.recordCount,
                  availablePageCount: issue.availablePageCount,
                  loadedPageCount: issue.loadedPageCount,
                  missingPageNumbers: issue.missingPageNumbers,
                  pageStatus: issue.pageStatus,
                  pageCountKnown: issue.pageCountKnown,
                  uncertainProductCount: issue.uncertainProductCount,
                  validFrom: issue.validFrom,
                  validUntil: issue.validUntil,
                )
              : issue,
        )
        .toList(growable: false);

    return ProspectFeedLoadResult(
      records: feed.records,
      refreshedStores: feed.refreshedStores,
      generatedAt: feed.generatedAt,
      prospects: prospects,
      fromCache: feed.fromCache,
    );
  }

  List<ProspectBranch> resolveBranches(
    String address, {
    Iterable<ProspectBranch> current = configuredProspectBranches,
  }) => _branchResolver.resolveOrKeep(address, current);
}
