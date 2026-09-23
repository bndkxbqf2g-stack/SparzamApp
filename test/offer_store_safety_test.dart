import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparzamapp/services/offer_store.dart';

void main() {
  test('beschädigte oder ungültige Angebote werden ignoriert', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('offers_v2', [
      jsonEncode({
        'id': 'bad',
        'productId': 'milk',
        'storeName': 'Lidl',
        'originalPrice': -2,
        'offerPrice': 1,
        'validUntil': '2026-09-30T00:00:00.000',
      }),
      jsonEncode({
        'id': 'good',
        'productId': 'milk',
        'storeName': 'Lidl',
        'originalPrice': 2,
        'offerPrice': 1,
        'validUntil': '2026-09-30T00:00:00.000',
      }),
      '{defekt',
    ]);

    final loaded = await OfferStore().load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'good');
  });
}
