import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/receipt_observation.dart';
import 'package:sparzamapp/services/receipt_observation_store.dart';

ReceiptObservation observation({
  String? productId,
  bool identityConfirmed = false,
  String id = 'receipt|1',
  int rowLine = 1,
}) => ReceiptObservation(
  id: id,
  receiptFingerprint: 'receipt',
  rowLine: rowLine,
  rawLabel: 'Unbekannter Artikel',
  familyKey: 'sonstiges',
  storeName: 'Kaufland',
  observedAt: DateTime(2026, 9, 30),
  totalPrice: 1.29,
  quantity: null,
  quantityUnit: 'Stück',
  unitPrice: null,
  discounted: false,
  productId: productId,
  identityConfirmed: identityConfirmed,
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('counts first insert and ignores an identical retry', () async {
    final store = ReceiptObservationStore();

    expect(await store.addMany([observation()]), 1);
    expect(await store.addMany([observation()]), 0);
  });

  test('counts a corrected identity update as a saved observation', () async {
    final store = ReceiptObservationStore();
    await store.addMany([observation(productId: 'receipt_auto_unknown')]);

    final changed = await store.addMany([
      observation(productId: 'catalog_product', identityConfirmed: true),
    ]);

    expect(changed, 1);
    final saved = await store.load();
    expect(saved.single.productId, 'catalog_product');
    expect(saved.single.identityConfirmed, isTrue);
  });

  test(
    'deduplicates legacy line ids after OCR shifts the source line',
    () async {
      final store = ReceiptObservationStore();
      await store.addMany([observation(id: 'receipt|34', rowLine: 34)]);

      final changed = await store.addMany([
        observation(id: 'receipt|item:1', rowLine: 8),
      ]);

      expect(changed, 1);
      final saved = await store.load();
      expect(saved, hasLength(1));
      expect(saved.single.id, 'receipt|item:1');
      expect(saved.single.rowLine, 8);
    },
  );

  test('does not erase a confirmed identity on a duplicate import', () async {
    final store = ReceiptObservationStore();
    await store.addMany([
      observation(
        id: 'receipt|item:1',
        productId: 'catalog_milk',
        identityConfirmed: true,
      ),
    ]);

    final changed = await store.addMany([
      observation(id: 'receipt|item:1', rowLine: 7),
    ]);

    expect(changed, 1);
    final saved = await store.load();
    expect(saved.single.productId, 'catalog_milk');
    expect(saved.single.identityConfirmed, isTrue);
    expect(saved.single.rowLine, 7);
  });
}
