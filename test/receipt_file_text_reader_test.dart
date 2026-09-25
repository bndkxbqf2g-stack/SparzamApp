import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_file_text_reader.dart';

void main() {
  test('liest Text- und CSV-Bons aus Dateidaten', () async {
    final text = await readReceiptFileText(
      fileName: 'bon.txt',
      bytes: Uint8List.fromList(utf8.encode('Milch;1,29')),
    );
    final csv = await readReceiptFileText(
      fileName: 'bon.csv',
      bytes: Uint8List.fromList(utf8.encode('Butter;1,89')),
    );

    expect(text, 'Milch;1,29');
    expect(csv, 'Butter;1,89');
  });
}
