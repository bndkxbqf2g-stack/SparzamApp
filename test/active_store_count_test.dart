import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/active_store_count.dart';

void main() {
  test('leere Auswahl zählt genau die sechs konfigurierten Märkte', () {
    expect(activeStoreCount(const []), 6);
  });

  test('ungültige oder doppelte Marktnamen werden nicht gezählt', () {
    expect(
      activeStoreCount(const ['Lidl', 'Lidl', 'NichtMehrKonfiguriert']),
      1,
    );
  });
}
