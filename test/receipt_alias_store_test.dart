import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/services/receipt_alias_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('learns only after two equal explicit confirmations', () async {
    final store = ReceiptAliasStore();
    await store.confirm(
      storeName: 'Kaufland',
      rawLabel: 'K.H-Milch',
      productId: 'milch_15',
      now: DateTime(2026, 9, 24),
    );
    expect(await store.learnedProductId(
      storeName: 'Kaufland',
      rawLabel: 'K.H-Milch',
    ), isNull);

    await store.confirm(
      storeName: 'Kaufland',
      rawLabel: 'K.H-Milch',
      productId: 'milch_15',
      now: DateTime(2026, 9, 24),
    );
    expect(await store.learnedProductId(
      storeName: 'Kaufland',
      rawLabel: 'K.H-Milch',
    ), 'milch_15');
    final learned = await store.learnedAlias(
      storeName: 'Kaufland',
      rawLabel: 'K.H-Milch',
    );
    expect(learned?.productId, 'milch_15');
    expect(learned?.confirmations, 2);
  });

  test('a conflicting correction resets confidence', () async {
    final store = ReceiptAliasStore();
    for (var i = 0; i < 2; i++) {
      await store.confirm(
        storeName: 'Kaufland',
        rawLabel: 'K.H-Milch',
        productId: 'milch_15',
        now: DateTime(2026, 9, 24),
      );
    }
    await store.confirm(
      storeName: 'Kaufland',
      rawLabel: 'K.H-Milch',
      productId: 'milch_35',
      now: DateTime(2026, 9, 25),
    );
    expect(await store.learnedProductId(
      storeName: 'Kaufland',
      rawLabel: 'K.H-Milch',
    ), isNull);
  });

  test('OCR umlaut and ae spellings share the same learned alias', () async {
    final store = ReceiptAliasStore();
    await store.confirm(
      storeName: 'Lidl',
      rawLabel: 'Hähnchenbrust',
      productId: 'chicken-breast',
      now: DateTime(2026, 9, 24),
    );
    await store.confirm(
      storeName: 'Lidl',
      rawLabel: 'HAEHNCHENBRUST',
      productId: 'chicken-breast',
      now: DateTime(2026, 9, 25),
    );

    expect(
      await store.learnedProductId(
        storeName: 'Lidl',
        rawLabel: 'Hähnchenbrust',
      ),
      'chicken-breast',
    );
    expect(
      await store.learnedProductId(
        storeName: 'Lidl',
        rawLabel: 'HAEHNCHENBRUST',
      ),
      'chicken-breast',
    );
    expect((await store.load()), hasLength(1));
  });

  test('OCR market spellings share the same learned alias', () async {
    final store = ReceiptAliasStore();
    await store.confirm(
      storeName: 'ALDI Süd',
      rawLabel: 'Butter',
      productId: 'butter-250',
      now: DateTime(2026, 9, 24),
    );
    await store.confirm(
      storeName: 'ALDI SUED',
      rawLabel: 'Butter',
      productId: 'butter-250',
      now: DateTime(2026, 9, 25),
    );

    expect(
      await store.learnedProductId(
        storeName: 'ALDI Süd',
        rawLabel: 'Butter',
      ),
      'butter-250',
    );
    expect(
      await store.learnedProductId(
        storeName: 'ALDI SUED',
        rawLabel: 'Butter',
      ),
      'butter-250',
    );
    expect((await store.load()), hasLength(1));
  });
}
