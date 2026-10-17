import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/features/prospects/prospect_page_ocr.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  test('parses product prices while keeping totals out', () {
    final candidates = parseProspectPageOcrText('''
Jacobs Kaffee Crema 500 g 4,99 € statt 5,99 €
Frische Vollmilch 1 l 0,99 €
SUMME 5,98 €
Zu zahlen 5,98 €
''');

    expect(candidates, hasLength(2));
    expect(candidates.first.productLabel, 'Jacobs Kaffee Crema 500 g');
    expect(candidates.first.offerPrice, 4.99);
    expect(candidates.first.originalPrice, 5.99);
    expect(
      candidates.first.confidence,
      ProspectPageOcrConfidence.high,
    );
    expect(candidates.last.productLabel, 'Frische Vollmilch 1 l');
  });

  test('accepts currency before the amount and keeps the regular price', () {
    final candidates = parseProspectPageOcrText(
      'Butter € 1,99 statt € 2,49',
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.productLabel, 'Butter');
    expect(candidates.single.offerPrice, 1.99);
    expect(candidates.single.originalPrice, 2.49);
  });

  test('keeps short OCR labels visible as low confidence suggestions', () {
    final candidates = parseProspectPageOcrText('''
Ei 1,29 €
''');

    expect(candidates, hasLength(1));
    expect(candidates.single.confidence, ProspectPageOcrConfidence.low);
  });

  test('downloads only the public page and forwards bytes to local OCR', () async {
    Uint8List? recognizedBytes;
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://example.test/page.png');
      expect(request.headers['Accept'], 'image/*');
      expect(request.headers['User-Agent'], contains('SparzamApp'));
      return http.Response.bytes(<int>[1, 2, 3], 200);
    });

    final result = await analyzeProspectPage(
      const ProspectPage(
        number: 1,
        imageUrl: 'https://example.test/page.png',
      ),
      client: client,
      recognizeText: (bytes) async {
        recognizedBytes = bytes;
        return 'Käse 2,49 €';
      },
    );
    client.close();

    expect(result.status, ProspectPageOcrStatus.ready);
    expect(result.candidates.single.productLabel, 'Käse');
    expect(result.candidates.single.offerPrice, 2.49);
    expect(recognizedBytes, orderedEquals(<int>[1, 2, 3]));
  });

  test('rejects non-public page URLs before any request', () async {
    var requests = 0;
    final result = await analyzeProspectPage(
      const ProspectPage(number: 1, imageUrl: 'javascript:alert(1)'),
      client: MockClient((_) async {
        requests++;
        return http.Response('', 200);
      }),
      recognizeText: (_) async => 'Käse 2,49 €',
    );

    expect(result.status, ProspectPageOcrStatus.unavailable);
    expect(requests, 0);
  });
}
