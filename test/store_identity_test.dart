import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/stores.dart';
import 'package:sparzamapp/services/store_identity.dart';

void main() {
  test('canonicalizes casing and configured town suffixes', () {
    expect(canonicalStoreName('lIdL', stores), 'Lidl');
    expect(canonicalStoreName('Lidl · Zellingen', stores), 'Lidl');
    expect(canonicalStoreName('ALDI-Süd', stores), 'ALDI Süd');
  });

  test('does not resolve a market from an arbitrary substring', () {
    expect(canonicalStoreName('Museum Lidl', stores), isNull);
    expect(canonicalStoreName('Lidl-Museum', stores), isNull);
    expect(canonicalStoreName('Unbekannter Markt', stores), isNull);
  });
}
