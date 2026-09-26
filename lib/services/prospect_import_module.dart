import 'package:http/http.dart' as http;

import 'prospect_feed_service.dart';

/// Orchestrates the complete prospect import boundary.
///
/// Retailer-specific acquisition remains in the refresh workflow and its
/// official source adapters. The app consumes one validated, status-aware
/// result and never treats an unavailable retailer as an empty successful feed.
class ProspectImportModule {
  ProspectImportModule({http.Client? client})
      : _feedService = ProspectFeedService(client: client);

  final ProspectFeedService _feedService;

  Future<ProspectFeedLoadResult> execute() => _feedService.load();
}
