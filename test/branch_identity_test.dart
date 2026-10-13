import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/branch_identity.dart';

void main() {
  test('normalizes only whitespace and case for branch comparison', () {
    expect(canonicalBranchId('  B384 '), 'b384');
    expect(canonicalBranchId('lidl_zellingen'), 'lidl_zellingen');
    expect(canonicalBranchId(''), isNull);
    expect(canonicalBranchId(null), isNull);
  });

  test('does not invent punctuation aliases', () {
    expect(
      canonicalBranchId('lidl-zellingen'),
      isNot(canonicalBranchId('lidl_zellingen')),
    );
  });

  test('matches configured branches and rejects another filial', () {
    expect(matchesConfiguredBranch('Lidl', 'lidl_zellingen'), isTrue);
    expect(matchesConfiguredBranch('Lidl', 'lidl-wuerzburg'), isFalse);
    expect(matchesConfiguredBranch('Lidl', null), isTrue);
  });
}
