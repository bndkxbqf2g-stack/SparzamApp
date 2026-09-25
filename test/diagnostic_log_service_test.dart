import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/services/diagnostic_log_service.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('Diagnoseeinträge werden gespeichert und exportiert', () async {
    final service = DiagnosticLogService();
    await service.record(
      category: 'Scanner',
      message: 'Erneuter Scan bleibt leer',
      details: 'Barcode im Markt getestet',
    );

    final loaded = await service.load();
    final export = await service.exportText();
    expect(loaded, hasLength(1));
    expect(export, contains('Scanner'));
    expect(export, contains('Erneuter Scan bleibt leer'));
    expect(export, contains('Barcode im Markt getestet'));
  });

  test('leere Diagnosefelder werden nicht gespeichert', () async {
    final service = DiagnosticLogService();
    await service.record(category: ' ', message: ' ');

    expect(await service.load(), isEmpty);
    expect(await service.exportText(), contains('Keine Einträge'));
  });
}
