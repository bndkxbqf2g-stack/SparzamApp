import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
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

  test(
    'leitet Bildbons an OCR weiter und übergibt den Text an den Bonreview',
    () async {
      String? capturedPath;
      final text = await readReceiptFileText(
        fileName: 'bon.JPG',
        filePath: '/tmp/bon.JPG',
        bytes: Uint8List.fromList([1, 2, 3]),
        imageTextReader: ({required bytes, filePath}) async {
          capturedPath = filePath;
          return '''
Kaufland
Preis EUR
Milch 1,29 B
Summe 1,29
''';
        },
      );

      expect(isReceiptImageFile('bon.JPG'), isTrue);
      expect(isReceiptImageFile('bon.pdf'), isFalse);
      expect(capturedPath, '/tmp/bon.JPG');
      final draft = parseReceiptLedger(text!);
      expect(draft.retailer, 'Kaufland');
      expect(draft.rows.single.label, 'Milch');
      expect(draft.balances, isTrue);
    },
  );
}
