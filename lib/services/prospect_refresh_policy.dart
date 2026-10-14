/// Maximum age of a validated prospect snapshot before an app-resume refresh.
const prospectResumeRefreshInterval = Duration(hours: 6);

/// Returns whether resuming the app should start a background prospect refresh.
///
/// Future timestamps can occur after a device clock correction; they are kept
/// visible until they age past the normal interval instead of causing a
/// refresh loop. A missing timestamp always refreshes because freshness is
/// unknown.
bool shouldRefreshProspectsOnResume({
  required DateTime? generatedAt,
  required DateTime now,
  Duration maxAge = prospectResumeRefreshInterval,
}) {
  if (generatedAt == null) return true;
  if (maxAge <= Duration.zero) return true;
  final age = now.difference(generatedAt);
  if (age.isNegative) return false;
  return age >= maxAge;
}
