import '../../data/stores.dart';

/// Returns the number of configured markets that the route can actually use.
///
/// An empty selection means all configured project markets. Invalid names from
/// older or manually edited local settings are ignored, just like the route
/// optimizer ignores stores that are not configured.
int activeStoreCount(Iterable<String> enabledStoreNames) {
  final configuredNames = stores.map((store) => store.name).toSet();
  final enabled = enabledStoreNames.toSet();
  if (enabled.isEmpty) return configuredNames.length;
  return enabled.where(configuredNames.contains).length;
}
