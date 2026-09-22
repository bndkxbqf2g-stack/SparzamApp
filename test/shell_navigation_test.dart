import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_navigation.dart';

void main() {
  test('Hauptnavigation behält Reihenfolge und Bezeichnungen', () {
    expect(
      shellDestinations.map((destination) => destination.label),
      ['Home', 'Liste', 'Route', 'Bon', 'Profil'],
    );
  });
}
