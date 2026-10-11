import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/prospect_branch_resolver.dart';

void main() {
  const resolver = ProspectBranchResolver();

  test('extracts a German postcode from the start address', () {
    expect(
      resolver.extractPostalCode('Am Beispiel 1, 97225 Zellingen, Germany'),
      '97225',
    );
  });

  test('resolves only configured official branches for a known postcode', () {
    final branches = resolver.resolve('97225 Zellingen, Germany');

    expect(branches.map((branch) => branch.storeName), [
      'Lidl',
      'ALDI Süd',
      'EDEKA',
      'PENNY',
    ]);
    expect(branches.every((branch) => branch.branchId.isNotEmpty), isTrue);
  });

  test('finds the configured branch metadata by retailer name', () {
    expect(configuredProspectBranch('Netto')?.branchId, '4371');
    expect(configuredProspectBranch('Netto')?.location, 'Thüngersheim');
    expect(configuredProspectBranch('Unbekannt'), isNull);
  });

  test('keeps existing branches when the postcode is unknown', () {
    const current = [
      ProspectBranch(
        storeName: 'Netto',
        branchId: '4371',
        postalCode: '97291',
        location: 'Thüngersheim',
        officialUrl: 'https://www.netto-online.de/',
      ),
    ];

    expect(
      resolver.resolveOrKeep('00000 Unbekannt, Germany', current),
      current,
    );
  });
}
