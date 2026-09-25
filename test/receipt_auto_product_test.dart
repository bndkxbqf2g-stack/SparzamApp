import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_auto_product.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('creates a conservative product from an unmatched receipt row', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
K.H-Milch 0,85 B
Summe 0,85
Datum 23.07.26
''');
    final row = draft.rows.firstWhere((row) => row.kind == ReceiptRowKind.item);

    final product = buildAutomaticReceiptProduct(
      row: row,
      id: 'receipt_auto_test',
    );

    expect(product.name, 'K.H-Milch');
    expect(product.group, 'Milch');
    expect(product.unit, 'Stück');
    expect(product.aliases, ['K.H-Milch']);
    expect(product.name, isNot(contains('1,5')));
    expect(product.name, isNot(contains('3,5')));
  });

  test('reuses an exact normalized receipt alias instead of duplicating it', () {
    const existing = Product(
      id: 'existing',
      name: 'Milch offen',
      unit: 'Stück',
      group: 'Milch',
      aliases: ['K.H-Milch'],
    );

    final found = findExistingReceiptProduct(
      'k h milch',
      const [existing],
    );

    expect(found?.id, 'existing');
  });

  test('does not merge merely similar receipt labels', () {
    const existing = Product(
      id: 'milk15',
      name: 'H-Milch 1,5%',
      unit: '1 l',
      group: 'Milch',
      aliases: ['K.H-Milch 1,5'],
    );

    expect(
      findExistingReceiptProduct('K.H-Milch 3,5', const [existing]),
      isNull,
    );
  });
  test('known product families stay observations instead of raw catalog products', () {
    expect(shouldCreateAutomaticReceiptProduct('GL H-Milch 3,5% 1 L'), isFalse);
    expect(shouldCreateAutomaticReceiptProduct('Paprika rot spitz'), isFalse);
    expect(shouldCreateAutomaticReceiptProduct('VL Eier BH 10ST'), isFalse);
  });

  test('unknown receipt labels may still create provisional catalog products', () {
    expect(shouldCreateAutomaticReceiptProduct('Mystery Produkt 250g'), isTrue);
  });


}
