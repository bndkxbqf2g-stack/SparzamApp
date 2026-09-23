import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/sequential_write_queue.dart';

void main() {
  test('Schreibvorgänge laufen nacheinander', () async {
    final queue = SequentialWriteQueue();
    final first = Completer<void>();
    final calls = <String>[];
    final initial = queue.add(() async {
      calls.add('first');
      await first.future;
    });
    final later = queue.add(() async {
      calls.add('second');
    });

    await Future<void>.delayed(Duration.zero);
    expect(calls, ['first']);
    first.complete();
    await Future.wait([initial, later]);
    expect(calls, ['first', 'second']);
  });

  test('Fehler wird gemeldet, nächster Schreibvorgang startet trotzdem', () async {
    final queue = SequentialWriteQueue();
    final calls = <String>[];
    final failed = queue.add(() async {
      calls.add('failed');
      throw StateError('storage unavailable');
    });
    final recovered = queue.add(() async {
      calls.add('recovered');
    });

    await expectLater(failed, throwsStateError);
    await recovered;
    await queue.pending;
    expect(calls, ['failed', 'recovered']);
  });
}
