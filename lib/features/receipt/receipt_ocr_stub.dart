import 'dart:typed_data';

const supportsReceiptImageOcr = false;

Future<String?> readReceiptImageText({
  required Uint8List bytes,
  String? filePath,
}) async => null;

Future<String?> readReceiptBitmapText({
  required Uint8List bgraBytes,
  required int width,
  required int height,
}) async => null;
