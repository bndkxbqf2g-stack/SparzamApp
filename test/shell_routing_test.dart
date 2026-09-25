import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_routing.dart';
import 'package:sparzamapp/models/mobility_settings.dart';

void main() {
  test('leere Einkaufsliste erzeugt keine Routenberechnung', () {
    const routing = ShellRouting(
      items: [],
      offers: [],
      mobility: MobilitySettings(),
      marketPrices: [],
      roadDistances: {},
      roadMatrix: null,
    );

    expect(routing.current, isNull);
    expect(routing.regular, isNull);
  });
}
