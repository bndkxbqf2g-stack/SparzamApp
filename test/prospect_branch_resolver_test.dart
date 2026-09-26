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

  test('keeps existing branches when the postcode is unknown', () {
    const current = [
      ProspectBranch(
        storeName: 'REWE',
        branchId: '461683',
        postalCode: '97209',
        location: 'Veitshöchheim',
        officialUrl: 'https://www.rewe.de/',
      ),
    ];

    expect(
      resolver.resolveOrKeep('00000 Unbekannt, Germany', current),
      current,
    );
  });
}
