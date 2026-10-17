import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/prospects/prospect_issue_identity.dart';
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

  test('matches retailer presentation without merging branches', () {
    expect(prospectStoreMatchKey(' LIDL '), prospectStoreMatchKey('Lidl'));
    expect(
      prospectStoreMatchKey('ALDI Süd'),
      prospectStoreMatchKey('ALDI SUED'),
    );
    expect(
      prospectBranchMatchKey(storeName: 'LIDL', branchId: 'B384'),
      prospectBranchMatchKey(storeName: 'Lidl', branchId: 'b384'),
    );
    expect(
      prospectBranchMatchKey(storeName: 'Lidl', branchId: 'b384'),
      isNot(prospectBranchMatchKey(storeName: 'Lidl', branchId: 'lidl-wuerzburg')),
    );
  });

  test('matches configured branches and rejects another filial', () {
    expect(matchesConfiguredBranch('Lidl', 'lidl_zellingen'), isTrue);
    expect(matchesConfiguredBranch('Lidl', 'lidl-wuerzburg'), isFalse);
    expect(matchesConfiguredBranch('Lidl', null), isTrue);
  });

  test('keeps exact branches when retailer labels vary', () {
    expect(matchesConfiguredBranch('LIDL', 'lidl_zellingen'), isTrue);
    expect(matchesConfiguredBranch('LIDL', 'lidl_wuerzburg'), isFalse);
    expect(matchesConfiguredBranch('ALDI SUED', 'B384'), isTrue);
  });
}
