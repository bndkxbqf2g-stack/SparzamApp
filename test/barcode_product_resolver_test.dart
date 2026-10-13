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

  test('normalisiert Eingaben mit Trennzeichen', () {
    expect(normalizeBarcode(' 2990-0000 00019 '), '2990000000019');
    expect(productForBarcode('2990-0000 00019')?.id, 'butter_streichzart');
  });

  test('normalisiert zwölfstellige UPC-A-Codes zu GTIN-13', () {
    expect(normalizeBarcode('123456789012'), '0123456789012');
  });

  test('nichtnumerische Eingaben erzeugen keine Produktidentität', () {
    expect(normalizeBarcode('EAN-ABC'), isNull);
    expect(productForBarcode('EAN-ABC'), isNull);
  });
}
