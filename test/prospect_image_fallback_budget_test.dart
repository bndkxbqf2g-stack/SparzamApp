import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/prospects/prospect_cover_section.dart';
import 'package:sparzamapp/features/prospects/prospects_screen.dart';

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


  test('viewer uses a separate bounded budget for later pages', () {
    expect(prospectPageHtmlFallbackBudget, 2);
    expect(prospectViewerImageFallbackBudget.maxActiveFallbacks, 2);
    expect(prospectPageHtmlFallbackAllowed(0), isTrue);
    expect(prospectPageHtmlFallbackAllowed(2), isFalse);
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
