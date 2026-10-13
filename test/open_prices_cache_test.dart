import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/services/open_prices_cache.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('ein paralleler Read wartet auf einen Open-Prices-Cache-Write',
      () async {
    final cache = SharedPreferencesOpenPricesCache();
    final reader = SharedPreferencesOpenPricesCache();
    const response = '{"items":[{"price":4.49}]}';

    final writing = cache.save('4001234567890', response);
    final reading = reader.load('4001234567890');

    await writing;
    expect(await reading, response);
  });

  test('leere Cache-Schlüssel bleiben unbekannt', () async {
    final cache = SharedPreferencesOpenPricesCache();

    await cache.save('', 'ignored');
    expect(await cache.load(''), isNull);
  });
}
