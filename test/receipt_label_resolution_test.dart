import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/products.dart';
import 'package:sparzamapp/features/catalog/product_identity.dart';
import 'package:sparzamapp/features/shopping_list/shopping_suggestions.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  Product firstSuggestion(String query) {
    final suggestions = buildSuggestions(
      query: query,
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: products,
    );
    expect(suggestions, isNotEmpty, reason: 'Keine Auswahl für "$query"');
    return suggestions.first;
  }

  test(
    'Kaufland-style abbreviations resolve without storing receipt prices',
    () {
      expect(firstSuggestion('K.H-Milch').id, isIn(['milch_15', 'milch_35']));
      expect(firstSuggestion('Eier Bodenhaltung').id, 'eier_bodenhaltung');
      expect(firstSuggestion('KLC Gou.mitt.450g').id, 'kaese_gouda');
      expect(firstSuggestion('KBio.Körn.Frischk.').id, 'kaese_frischkaese');
      expect(firstSuggestion('K.Schmelzk.Scheib.').id, 'kaese_schmelzkaese');
      expect(firstSuggestion('KLC.Fischstäbchen').id, 'fischstaebchen');
      expect(firstSuggestion('XXL R.-Hackfleisch').id, 'hackfleisch_rind');
      expect(firstSuggestion('K.Wiener').id, 'wurst_wiener');
      expect(firstSuggestion('K.Gelbwurst').id, 'wurst_gelbwurst');
      expect(firstSuggestion('K.Kochhinterschink').id, 'wurst_kochschinken');
      expect(firstSuggestion('KLC.Kn.Mäuse Salz').id, 'chips');
    },
  );

  test('receipt families remain distinct while variants are searchable', () {
    expect(identifyProduct('KLC.Geh. Tomaten').familyKey, 'tomatenkonserve');
    expect(firstSuggestion('KLC.Geh. Tomaten').id, 'tomaten_dose');
    expect(firstSuggestion('K.Passata Rus.Bas.').id, 'tomaten_passata');
    expect(firstSuggestion('Melissa Kritharaki').id, 'nudeln_kritharaki');
    expect(firstSuggestion('KLC.Penne Rigate').id, 'nudeln_penne');
    expect(firstSuggestion('K.Medit. Wedges').id, 'kartoffel_wedges');
    expect(firstSuggestion('K.Kaisergemüse').id, 'gemuese_kaisergemuese');
    expect(firstSuggestion('KLC.Gemüsemais').id, 'mais');
    expect(
      firstSuggestion('KLC.Erbsen m. Möhren').id,
      'gemuese_erbsen_moehren',
    );
    expect(firstSuggestion('Thomy Holl.Legere').id, 'sauce_hollandaise');
    expect(firstSuggestion('KBio.Ital.Kräuter').id, 'kraeuter_italienisch');
  });

  test('common receipt categories have a price-free catalog choice', () {
    for (final query in [
      'Bounty Ice Cream',
      'Pizza-Donut Schin.',
      'K.Sandwichtoast K',
      'K.Creme zum Kochen',
      'Mü.Jogh.m.d.Ecke',
      'Müllermilch',
      'KLC Müsliriegel',
      'Haribo Balla Stixx',
      'Kohlrabi',
      'Eisbergsalat',
      'Zwiebeln rot',
      'TA rot',
      'Softlan Windfrisch',
      'KLC Toilettenpapier',
    ]) {
      expect(firstSuggestion(query), isA<Object>());
    }
  });
}
