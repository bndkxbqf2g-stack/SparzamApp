import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/safe_external_url.dart';

void main() {
  test('accepts absolute HTTP(S) URLs with a host', () {
    expect(safeExternalHttpUrl(' https://cdn.example.test/offer.jpg '),
        'https://cdn.example.test/offer.jpg');
    expect(safeExternalHttpUrl('http://cdn.example.test/offer.jpg'),
        'http://cdn.example.test/offer.jpg');
  });

  test('rejects unsafe, relative, and malformed image references', () {
    for (final value in <Object?>[
      null,
      '',
      '  ',
      'javascript:alert(1)',
      'data:image/png;base64,invalid',
      '/relative/offer.jpg',
      'https:///missing-host.jpg',
    ]) {
      expect(safeExternalHttpUrl(value), isNull, reason: '$value must be rejected');
    }
  });
}
