import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final supportsReceiptImageOcr = Platform.isAndroid || Platform.isIOS;

Future<String?> readReceiptImageText({
  required Uint8List bytes,
  String? filePath,
}) async {
  if (!supportsReceiptImageOcr) return null;

  var path = filePath?.trim();
  String? temporaryPath;
  if (path == null || path.isEmpty) {
    if (bytes.isEmpty) return null;
    final temporary = File(
      '${Directory.systemTemp.path}/sparzam_receipt_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await temporary.writeAsBytes(bytes, flush: true);
    path = temporary.path;
    temporaryPath = path;
  }

  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final recognized = await recognizer.processImage(
      InputImage.fromFilePath(path),
    );
    final text = recognized.text.trim();
    return text.isEmpty ? null : text;
  } finally {
    await recognizer.close();
    if (temporaryPath != null) {
      try {
        await File(temporaryPath).delete();
      } catch (_) {
        // A temporary OCR file is best-effort cleanup only.
      }
    }
  }
}
