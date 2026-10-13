/// Normalizes scanner and manually entered GTIN/EAN values without guessing
/// product identity. Separators are presentation noise; a 12-digit UPC-A is
/// represented by its canonical 13-digit GTIN with a leading zero.
final _barcodeDigits = RegExp(r'^\d+$');

String? normalizeBarcode(String value) {
  final compact = value.replaceAll(RegExp(r'[\s-]+'), '');
  if (compact.isEmpty || !_barcodeDigits.hasMatch(compact)) return null;
  if (compact.length == 12) return '0$compact';
  return compact;
}
