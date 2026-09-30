import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final supportsReceiptImageOcr = Platform.isAndroid || Platform.isIOS;

Future<String?> _recognize(InputImage image) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final recognized = await recognizer.processImage(image);
    final text = recognized.text.trim();
    return text.isEmpty ? null : text;
  } finally {
    await recognizer.close();
  }
}

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

  try {
    return await _recognize(InputImage.fromFilePath(path));
  } finally {
    if (temporaryPath != null) {
      try {
        await File(temporaryPath).delete();
      } catch (_) {
        // A temporary OCR file is best-effort cleanup only.
      }
    }
  }
}

Future<String?> readReceiptBitmapText({
  required Uint8List bgraBytes,
  required int width,
  required int height,
}) async {
  if (!supportsReceiptImageOcr || width <= 0 || height <= 0) return null;
  final pixelCount = width * height;
  final byteCount = pixelCount * 4;
  if (pixelCount <= 0 || bgraBytes.length != byteCount) return null;

  // pdfrx exposes BGRA8888; ML Kit's bitmap bridge expects RGBA bytes.
  final rgbaBytes = Uint8List(byteCount);
  for (var index = 0; index < byteCount; index += 4) {
    rgbaBytes[index] = bgraBytes[index + 2];
    rgbaBytes[index + 1] = bgraBytes[index + 1];
    rgbaBytes[index + 2] = bgraBytes[index];
    rgbaBytes[index + 3] = bgraBytes[index + 3];
  }
  return _recognize(
    InputImage.fromBitmap(
      bitmap: rgbaBytes,
      width: width,
      height: height,
    ),
  );
}
