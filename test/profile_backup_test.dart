import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/profile/profile_screen.dart';
import 'package:sparzamapp/models/mobility_settings.dart';

void main() {
  testWidgets('zeigt lokale Backup-Aktionen und löst sie aus', (tester) async {
    var exports = 0;
    var imports = 0;

    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            mobility: const MobilitySettings(),
            onEditMobility: () {},
            onEditStores: () {},
            storeCount: 6,
            onOpenCatalog: () {},
            productCount: 12,
            onEditPriceData: () {},
            priceDataSummary: 'Open Prices · max. 60 Tage',
            onOpenDiagnostics: () {},
            onExportBackup: () async => exports++,
            onImportBackup: () async => imports++,
          ),
        ),
      ),
    );

    expect(find.text('Lokales Backup exportieren'), findsOneWidget);
    expect(find.text('Lokales Backup importieren'), findsOneWidget);

    final exportFinder = find.text('Lokales Backup exportieren');
    final importFinder = find.text('Lokales Backup importieren');
    await tester.ensureVisible(exportFinder);
    await tester.tap(exportFinder);
    await tester.ensureVisible(importFinder);
    await tester.tap(importFinder);
    await tester.pump();

    expect(exports, 1);
    expect(imports, 1);
  });
}
