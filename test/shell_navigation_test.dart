import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_navigation.dart';
import 'package:sparzamapp/features/shell/shell_pages.dart';

void main() {
  test('Hauptnavigation behält Reihenfolge und Bezeichnungen', () {
    expect(
      shellDestinations.map((destination) => destination.label),
      ['Start', 'Liste', 'Angebote', 'Prospekte', 'Preise', 'Mehr'],
    );
  });
}


  test('Shell-Seiten werden bei unverändertem Datenstand wiederverwendet', () {
    final cache = ShellPageCache();
    var builds = 0;

    final first = cache.resolve(
      signature: 7,
      builder: () {
        builds++;
        return [const SizedBox(key: ValueKey('shell-page'))];
      },
    );
    final reused = cache.resolve(
      signature: 7,
      builder: () {
        builds++;
        return [const SizedBox(key: ValueKey('unexpected-rebuild'))];
      },
    );
    final changed = cache.resolve(
      signature: 8,
      builder: () {
        builds++;
        return [const SizedBox(key: ValueKey('changed-page'))];
      },
    );

    expect(identical(first, reused), isTrue);
    expect(identical(first, changed), isFalse);
    expect(builds, 2);
  });
