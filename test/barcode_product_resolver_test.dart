import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/scanner/barcode_product_resolver.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('Demo-EAN findet bekanntes Produkt', () {
    expect(productForBarcode('2990000000019')?.id, 'butter_streichzart');
  });

  test('gelernte Barcode-Produkte werden wiedergefunden', () {
    const learned = Product(
      id: 'custom',
      name: 'Eigenes Produkt',
      unit: 'Artikel',
      group: 'custom',
      ean: '1234567890123',
    );
    expect(productForBarcode('1234567890123', [learned]), same(learned));
  });
}
