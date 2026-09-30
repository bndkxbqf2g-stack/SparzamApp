import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/receipt_search_products.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_observation.dart';

void main() {
  ReceiptObservation observation(
    String id,
    String label, {
    DateTime? at,
    bool confirmed = false,
    String store = 'Kaufland',
  }) => ReceiptObservation(
    id: id,
    receiptFingerprint: 'synthetic',
    rowLine: 1,
    rawLabel: label,
    familyKey: '',
    storeName: store,
    observedAt: at ?? DateTime(2026, 5, 26),
    totalPrice: 1,
    quantity: null,
    quantityUnit: 'Stück',
    unitPrice: null,
    discounted: false,
    identityConfirmed: confirmed,
  );

  test('unconfirmed older milk label is a searchable choice, not a price', () {
    final candidates = receiptSearchProducts(
      [observation('one', 'K.H-Milch'), observation('two', 'K.H-Milch')],
      catalogProducts: const <Product>[],
      now: DateTime(2026, 9, 30),
    );
    expect(candidates, hasLength(1));
    expect(candidates.single.name, 'H-Milch');
    expect(candidates.single.aliases, ['K.H-Milch']);
    expect(candidates.single.group, 'milch');
    expect(candidates.single.unit, 'Packung');
    expect(candidates.single.id, startsWith('receipt_suggestion_'));
  });

  test('catalog aliases, confirmed rows, and aged rows do not duplicate', () {
    final candidates = receiptSearchProducts(
      [
        observation('existing', 'K.H-Milch'),
        observation('confirmed', 'K.Weizenbrötchen', confirmed: true),
        observation('old', 'K.Passata', at: DateTime(2025, 1, 1)),
      ],
      catalogProducts: const [
        Product(
          id: 'milk',
          name: 'H-Milch',
          unit: 'Packung',
          group: 'milch',
          aliases: ['K.H-Milch'],
        ),
      ],
      now: DateTime(2026, 9, 30),
    );
    expect(candidates, isEmpty);
  });

  test('different product families retain distinct provisional choices', () {
    final candidates = receiptSearchProducts(
      [
        observation('eggs', 'Eier Bodenhaltung'),
        observation('pasta', 'Eier-Spätzle'),
        observation('meat', 'XXL R.-Hackfleisch'),
      ],
      catalogProducts: const <Product>[],
      now: DateTime(2026, 9, 30),
    );
    expect(candidates.map((item) => item.group), [
      'eier',
      'nudeln',
      'hackfleisch',
    ]);
  });
}
