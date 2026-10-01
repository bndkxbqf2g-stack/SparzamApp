import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/prospects/prospect_category_presentation.dart';

void main() {
  test('formats technical Kaufland category names for the UI', () {
    expect(
      presentProspectCategory('02_Obst__Gemuese__Pflanzen'),
      'Obst & Gemüse',
    );
    expect(
      presentProspectCategory('07_Kaffee__Tee__Suesswaren__Knabberartikel'),
      'Kaffee & Snacks',
    );
  });

  test('formats retailer slugs without changing unknown provenance', () {
    expect(presentProspectCategory('getraenke1'), 'Getränke');
    expect(presentProspectCategory('kuehlregal'), 'Kühlregal');
    expect(presentProspectCategory('Kühlregal'), 'Kühlregal');
    expect(
      presentProspectCategory('Frischetheke Spezial'),
      'Frischetheke Spezial',
    );
    expect(presentProspectCategory('Messe'), 'Messe');
  });

  test('empty source categories stay empty for the caller fallback', () {
    expect(presentProspectCategory(null), isEmpty);
    expect(presentProspectCategory('  '), isEmpty);
  });
}
