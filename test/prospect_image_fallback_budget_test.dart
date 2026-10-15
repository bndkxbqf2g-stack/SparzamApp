import 'package:flutter_test/flutter_test.dart';

import 'package:sparzam_app/features/prospects/prospect_cover_section.dart';

void main() {
  test('cover fallback budget limits active platform views', () {
    final budget = ProspectImageFallbackBudget(maxActiveFallbacks: 2);

    expect(budget.tryAcquire(), isTrue);
    expect(budget.tryAcquire(), isTrue);
    expect(budget.tryAcquire(), isFalse);
    expect(budget.activeFallbacks, 2);

    budget.release();
    expect(budget.activeFallbacks, 1);
    expect(budget.tryAcquire(), isTrue);
    expect(budget.activeFallbacks, 2);
  });

  test('cover fallback budget release is safe at zero', () {
    final budget = ProspectImageFallbackBudget(maxActiveFallbacks: 1);

    budget.release();
    expect(budget.activeFallbacks, 0);

    expect(budget.tryAcquire(), isTrue);
    budget.release();
    budget.release();
    expect(budget.activeFallbacks, 0);
    expect(budget.tryAcquire(), isTrue);
  });
}
