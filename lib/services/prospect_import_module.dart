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

  Future<ProspectFeedLoadResult> execute() => _feedService.load();

  List<ProspectBranch> resolveBranches(String address, {
    Iterable<ProspectBranch> current = configuredProspectBranches,
  }) => _branchResolver.resolveOrKeep(address, current);
}
