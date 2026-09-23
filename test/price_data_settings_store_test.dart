import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/services/price_data_settings_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('Preisdaten-Einstellungen werden gespeichert und geladen', () async {
    final store = PriceDataSettingsStore();
    const settings = PriceDataSettings(
      openPricesEnabled: false,
      openPricesMaxAgeDays: 45,
      autoSyncOnCatalogOpen: true,
    );

    await store.save(settings);
    final loaded = await store.load();

    expect(loaded.openPricesEnabled, isFalse);
    expect(loaded.openPricesMaxAgeDays, 45);
    expect(loaded.autoSyncOnCatalogOpen, isTrue);
  });

  test('Standardwerte sind sicher und konservativ', () async {
    final loaded = await PriceDataSettingsStore().load();

    expect(loaded.openPricesEnabled, isTrue);
    expect(loaded.openPricesMaxAgeDays, 60);
    expect(loaded.autoSyncOnCatalogOpen, isFalse);
  });
}
