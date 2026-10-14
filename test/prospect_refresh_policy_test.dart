import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/prospect_refresh_policy.dart';

void main() {
  final now = DateTime.utc(2026, 10, 14, 12);

  test('refreshes when no validated feed timestamp is known', () {
    expect(
      shouldRefreshProspectsOnResume(generatedAt: null, now: now),
      isTrue,
    );
  });

  test('keeps a recent validated feed without another network request', () {
    expect(
      shouldRefreshProspectsOnResume(
        generatedAt: now.subtract(const Duration(hours: 5, minutes: 59)),
        now: now,
      ),
      isFalse,
    );
  });

  test('refreshes a feed older than six hours', () {
    expect(
      shouldRefreshProspectsOnResume(
        generatedAt: now.subtract(const Duration(hours: 6)),
        now: now,
      ),
      isTrue,
    );
  });

  test('does not refresh a future timestamp after clock correction', () {
    expect(
      shouldRefreshProspectsOnResume(
        generatedAt: now.add(const Duration(minutes: 10)),
        now: now,
      ),
      isFalse,
    );
  });

  test('a non-positive test interval forces a refresh', () {
    expect(
      shouldRefreshProspectsOnResume(
        generatedAt: now,
        now: now,
        maxAge: Duration.zero,
      ),
      isTrue,
    );
  });
}
