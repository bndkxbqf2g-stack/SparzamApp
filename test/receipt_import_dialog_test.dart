import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/receipt/receipt_import_dialog.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  testWidgets('receipt import uses clear Bonpreise action label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptImportDialog(
            products: const [],
            onSavePrices: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Bonpreise übernehmen'), findsOneWidget);
    expect(find.text('Ausgewählte Preise übernehmen'), findsNothing);
  });
}
