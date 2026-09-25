import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web bootstrap is self-contained and does not register Flutter service worker', () {
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    expect(bootstrap, contains("canvasKitBaseUrl: 'canvaskit/'"));
    expect(bootstrap, contains("getRegistrations()"));
    expect(bootstrap, contains("startsWith('/SparzamApp/')"));
    expect(bootstrap, isNot(contains('serviceWorkerSettings')));
  });

  test('web index exposes a Sparzam loading state', () {
    final index = File('web/index.html').readAsStringSync();

    expect(index, contains('<title>Sparzam</title>'));
    expect(index, contains('Sparzam wird geladen'));
  });
}
