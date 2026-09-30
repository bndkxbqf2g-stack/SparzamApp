import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import 'receipt_ocr.dart';

bool isReceiptImageFile(String fileName) =>
    RegExp(r'\.(jpe?g|png)$').hasMatch(fileName.toLowerCase());

typedef ReceiptImageTextReader = Future<String?> Function({
  required Uint8List bytes,
  String? filePath,
});

typedef ReceiptBitmapTextReader = Future<String?> Function({
  required Uint8List bgraBytes,
  required int width,
  required int height,
});

Future<String?> readReceiptFileText({
  required String fileName,
  required Uint8List bytes,
  String? filePath,
  ReceiptImageTextReader? imageTextReader,
  ReceiptBitmapTextReader? bitmapTextReader,
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
        continue;
      }
      if (!supportsReceiptImageOcr) continue;

      final scale = math.min(
        2.5,
        math.sqrt(
          4000000 / math.max(1.0, page.width * page.height),
        ),
      );
      final rendered = await page.render(
        fullWidth: page.width * scale,
        fullHeight: page.height * scale,
      );
      if (rendered == null) continue;
      try {
        final renderedText = await (bitmapTextReader ?? readReceiptBitmapText)(
          bgraBytes: rendered.pixels,
          width: rendered.width,
          height: rendered.height,
        );
        if (renderedText != null && renderedText.trim().isNotEmpty) {
          text.writeln(renderedText);
        }
      } catch (_) {
        // OCR is an optional fallback. The original PDF remains importable
        // and the review will show it as unreadable when no text was found.
      } finally {
        rendered.dispose();
      }
    }
    return text.toString();
  } finally {
    await document.dispose();
  }
}
