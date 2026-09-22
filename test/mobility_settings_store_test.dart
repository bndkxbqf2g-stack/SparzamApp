import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/services/mobility_settings_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('Mobilitätseinstellungen werden gespeichert und geladen', () async {
    final store = MobilitySettingsStore();
    const settings = MobilitySettings(
      startAddress: 'Teststraße 1, 97070 Würzburg, Germany',
      euroPerKm: 0.35,
      mode: MobilityMode.bike,
      maxStores: 2,
      minExtraStoreSavings: 1.25,
      enabledStoreNames: ['Lidl', 'ALDI Süd'],
    );

    await store.save(settings);
    final loaded = await store.load();

    expect(loaded.startAddress, settings.startAddress);
    expect(loaded.euroPerKm, settings.euroPerKm);
    expect(loaded.mode, MobilityMode.bike);
    expect(loaded.maxStores, 2);
    expect(loaded.minExtraStoreSavings, 1.25);
    expect(loaded.enabledStoreNames, ['Lidl', 'ALDI Süd']);
    expect(loaded.effectiveEuroPerKm, 0);
  });

  test('Standardwerte bleiben ohne gespeicherte Einstellungen erhalten', () async {
    final loaded = await MobilitySettingsStore().load();

    expect(loaded.startAddress, '97225 Zellingen, Germany');
    expect(loaded.euroPerKm, 0.22);
  });
}
