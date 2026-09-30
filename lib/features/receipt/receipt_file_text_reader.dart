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
    try {
      return await (imageTextReader ?? readReceiptImageText)(
        bytes: bytes,
        filePath: filePath,
      );
    } catch (_) {
      // OCR is optional. The caller keeps the original image as an unreadable
      // reference so a transient/native OCR error never drops the import.
      return null;
    }
  }
  if (!lowerName.endsWith('.pdf')) return null;

  final PdfDocument document;
  try {
    await pdfrxFlutterInitialize();
    document = await PdfDocument.openData(bytes, sourceName: fileName);
  } catch (_) {
    return null;
  }
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
      PdfImage? rendered;
      try {
        rendered = await page.render(
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
        );
      } catch (_) {
        continue;
      }
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
