import 'package:http/http.dart' as http;

import 'prospect_feed_service.dart';
import 'prospect_branch_resolver.dart';

/// Orchestrates the complete prospect import boundary.
///
/// Retailer-specific acquisition remains in the refresh workflow and its
/// official source adapters. The app consumes one validated, status-aware
/// result and never treats an unavailable retailer as an empty successful feed.
class ProspectImportModule {
  ProspectImportModule({http.Client? client})
      : _feedService = ProspectFeedService(client: client);

  final ProspectFeedService _feedService;
  final ProspectBranchResolver _branchResolver = const ProspectBranchResolver();

  Future<ProspectFeedLoadResult> execute({String? startAddress}) async {
    final feed = await _feedService.load();
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
                  sourceStatus: issue.sourceStatus,
                  recordCount: issue.recordCount,
                )
              : issue,
        )
        .toList(growable: false);

    return ProspectFeedLoadResult(
      records: feed.records,
      refreshedStores: feed.refreshedStores,
      generatedAt: feed.generatedAt,
      prospects: prospects,
    );
  }

  List<ProspectBranch> resolveBranches(String address, {
    Iterable<ProspectBranch> current = configuredProspectBranches,
  }) => _branchResolver.resolveOrKeep(address, current);
}
