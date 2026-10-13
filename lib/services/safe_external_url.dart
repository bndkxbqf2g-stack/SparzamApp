/// Returns a network URL that is safe to hand to Flutter's network widgets.
///
/// Imported offer data can outlive the source that created it, so callers must
/// validate persisted URLs at render time as well as at import time.
String? safeExternalHttpUrl(Object? value) {
  if (value is! String) return null;
  final raw = value.trim();
  if (raw.isEmpty) return null;

  final uri = Uri.tryParse(raw);
  if (uri == null || uri.host.trim().isEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  return raw;
}
