import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/services/recent_purchase_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('ungültige Zähler bei letzten Einkäufen werden ignoriert', () async {
    final preferences = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = preferences;
    await SharedPreferencesAsync().setStringList('recent_purchases', [
      jsonEncode({
        'id': 'bad',
        'name': 'Milch',
        'unit': 'l',
        'group': 'Milchprodukte',
        'purchaseCount': 0,
        'totalQuantity': 2,
      }),
      jsonEncode({
        'id': 'good',
        'name': 'Milch',
        'unit': 'l',
        'group': 'Milchprodukte',
        'purchaseCount': 2,
        'totalQuantity': 3,
      }),
    ]);

    final loaded = await RecentPurchaseStore().load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'good');
  });
}
