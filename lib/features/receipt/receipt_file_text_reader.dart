import 'dart:convert';
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import 'receipt_ocr.dart';

bool isReceiptImageFile(String fileName) =>
    RegExp(r'\.(jpe?g|png)$').hasMatch(fileName.toLowerCase());

typedef ReceiptImageTextReader = Future<String?> Function({
  required Uint8List bytes,
  String? filePath,
});

Future<String?> readReceiptFileText({
  required String fileName,
  required Uint8List bytes,
  String? filePath,
  ReceiptImageTextReader? imageTextReader,
}) async {
  final lowerName = fileName.toLowerCase();
  if (lowerName.endsWith('.txt') || lowerName.endsWith('.csv')) {
    return utf8.decode(bytes, allowMalformed: true);
  }
  if (isReceiptImageFile(lowerName)) {
    return (imageTextReader ?? readReceiptImageText)(
      bytes: bytes,
      filePath: filePath,
    );
  }
  if (!lowerName.endsWith('.pdf')) return null;

  await pdfrxFlutterInitialize();
  final document = await PdfDocument.openData(bytes, sourceName: fileName);
  try {
    final text = StringBuffer();
    for (final page in document.pages) {
      final pageText = await page.loadStructuredText();
      if (pageText.fullText.trim().isNotEmpty) {
        text.writeln(pageText.fullText);
      }
    }
    return text.toString();
  } finally {
    await document.dispose();
  }
}
