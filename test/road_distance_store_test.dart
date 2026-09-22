import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/services/road_distance_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('Straßenentfernungen gelten nur für denselben Startort', () async {
    final store = RoadDistanceStore();
    const firstOrigin = 'Start A';
    const secondOrigin = 'Start B';

    await store.save(firstOrigin, const {'Lidl': 4.2});

    expect(await store.load(firstOrigin), const {'Lidl': 4.2});
    expect(await store.load(secondOrigin), isEmpty);
  });
}
