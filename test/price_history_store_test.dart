import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/price_point.dart';
import 'package:sparzamapp/services/price_history_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('gleiche Quelle am selben Tag wird aktualisiert statt dupliziert',
      () async {
    final store = PriceHistoryStore();
    final first = PricePoint(
      productId: 'a',
      storeName: 'Lidl',
      price: 2.49,
      date: DateTime(2026, 9, 20, 8),
      source: PricePointSource.openPrices,
    );
    final newer = PricePoint(
      productId: 'a',
      storeName: 'Lidl',
      price: 2.29,
      date: DateTime(2026, 9, 20, 18),
      source: PricePointSource.openPrices,
    );

    var history = await store.upsertObservation(first, const []);
    history = await store.upsertObservation(newer, history);

    expect(history, hasLength(1));
    expect(history.single.price, 2.29);
    expect(history.single.source, PricePointSource.openPrices);
  });

  test('manuell und Open Prices dürfen am selben Tag nebeneinander existieren',
      () async {
    final store = PriceHistoryStore();
    final external = PricePoint(
      productId: 'a',
      storeName: 'Lidl',
      price: 2.29,
      date: DateTime(2026, 9, 20),
      source: PricePointSource.openPrices,
    );
    final manual = PricePoint(
      productId: 'a',
      storeName: 'Lidl',
      price: 2.39,
      date: DateTime(2026, 9, 20),
      source: PricePointSource.manual,
    );

    var history = await store.upsertObservation(external, const []);
    history = await store.upsertObservation(manual, history);

    expect(history, hasLength(2));
    expect(
      history.map((point) => point.source).toSet(),
      {PricePointSource.openPrices, PricePointSource.manual},
    );
  });

  test('Quelle bleibt beim Speichern und Laden erhalten', () async {
    final store = PriceHistoryStore();
    final point = PricePoint(
      productId: 'a',
      storeName: 'Lidl',
      price: 1.99,
      date: DateTime(2026, 9, 20),
      source: PricePointSource.manual,
    );

    await store.save([point]);
    final loaded = await store.load();

    expect(loaded.single.source, PricePointSource.manual);
  });
}
