import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/prospects/prospects_screen.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';
import 'package:sparzamapp/services/prospect_favorites_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('retailer favorites persist deterministically', () async {
    final store = ProspectFavoritesStore();

    expect(await store.load(), isNull);

    await store.save(['Lidl', 'ALDI Süd', 'Lidl', ' ']);

    expect(await store.load(), {'ALDI Süd', 'Lidl'});

    await store.save(const <String>[]);
    expect(await store.load(), isEmpty);
  });

  testWidgets('heart toggles a favorite without opening the prospect', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectsScreen(
            records: const [],
            prospects: const [
              ProspectIssue(
                storeName: 'Lidl',
                title: 'Aktionsprospekt',
                pages: [
                  ProspectPage(
                    number: 1,
                    imageUrl: 'https://example.test/lidl-page.png',
                  ),
                ],
              ),
              ProspectIssue(
                storeName: 'ALDI Süd',
                title: 'Aktionsprospekt',
                pages: [],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addFavorite = find.byTooltip('Lidl zu Favoriten hinzufügen');
    expect(addFavorite, findsNWidgets(2));

    await tester.tap(addFavorite.first);
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Lidl aus Favoriten entfernen'),
      findsNWidgets(2),
    );
    expect(find.text('Prospektseiten (1)'), findsNothing);

    await tester.tap(
      find.byTooltip('Lidl aus Favoriten entfernen').first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Noch keine Favoriten. Tippe auf das Herz, um einen Markt zu speichern.',
      ),
      findsOneWidget,
    );
  });
}
