import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/purchase_record.dart';
import 'package:sparzamapp/services/purchase_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  PurchaseRecord record(String id, DateTime date) => PurchaseRecord(
        id: id,
        createdAt: date,
        storeNames: const ['Lidl'],
        items: const [
          PurchaseLine(
            productId: 'milk',
            name: 'Milch',
            quantity: 2,
          ),
        ],
        basket: 2.50,
        travel: 0.50,
        total: 3.00,
        baselineTotal: 3.50,
      );

  test('Kaufdatum kann bei gleicher ID korrigiert werden', () async {
    final store = PurchaseStore();
    final original = record('1', DateTime(2026, 9, 1));
    final first = await store.add(original, const []);

    final corrected = original.copyWith(
      createdAt: DateTime(2026, 9, 3),
    );
    final second = await store.add(corrected, first);

    expect(second, hasLength(1));
    expect(second.single.createdAt, DateTime(2026, 9, 3));

    final loaded = await store.load();
    expect(loaded.single.createdAt, DateTime(2026, 9, 3));
  });

  test('Historie bleibt nach einer Datumskorrektur chronologisch', () async {
    final store = PurchaseStore();
    var current = await store.add(
      record('1', DateTime(2026, 9, 3)),
      const [],
    );
    current = await store.add(
      record('2', DateTime(2026, 9, 2)),
      current,
    );

    current = await store.add(
      record('1', DateTime(2026, 9, 1)),
      current,
    );

    expect(current.map((item) => item.id), ['2', '1']);
    expect((await store.load()).map((item) => item.id), ['2', '1']);
  });

  test('Einkauf kann aus Historie entfernt werden', () async {
    final store = PurchaseStore();
    var current = await store.add(
      record('1', DateTime(2026, 9, 1)),
      const [],
    );
    current = await store.add(
      record('2', DateTime(2026, 9, 2)),
      current,
    );

    final next = await store.remove('1', current);

    expect(next.map((item) => item.id), ['2']);
    expect((await store.load()).map((item) => item.id), ['2']);
  });

  test('Beträge und Artikelmengen können korrigiert werden', () {
    final original = record('1', DateTime(2026, 9, 1));

    final corrected = original.copyWith(
      items: const [
        PurchaseLine(productId: 'milk', name: 'Milch', quantity: 1),
      ],
      basket: 1.25,
      travel: 0.25,
      total: 1.50,
      baselineTotal: 2,
    );

    expect(corrected.items.single.quantity, 1);
    expect(corrected.basket, 1.25);
    expect(corrected.travel, 0.25);
    expect(corrected.total, 1.50);
    expect(corrected.savings, 0.50);
  });
}
