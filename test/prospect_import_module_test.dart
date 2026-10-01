import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/services/prospect_import_module.dart';

void main() {
  test(
    'start-address URL enrichment keeps prospect branch provenance',
    () async {
      final client = MockClient(
        (_) async => http.Response('''
{
  "generatedAt": "2026-10-01T04:15:00Z",
  "sources": [
    {
      "storeName": "ALDI Süd",
      "status": "ok",
      "branchId": "B384",
      "location": "Zellingen",
      "address": "Würzburger Str. 74, 97225 Zellingen, Germany"
    }
  ],
  "offers": []
}
''', 200),
      );

      final result = await ProspectImportModule(client: client)
          .execute(startAddress: '97225 Zellingen, Germany');
      final aldi = result.prospects.firstWhere(
        (issue) => issue.storeName == 'ALDI Süd',
      );

      expect(aldi.url, 'https://www.aldi-sued.de/');
      expect(aldi.branchId, 'B384');
      expect(aldi.location, 'Zellingen');
      expect(aldi.address, contains('Würzburger Str. 74'));
    },
  );
}
