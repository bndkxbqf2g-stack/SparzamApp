import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/prospects/prospects_screen.dart';
import 'package:sparzamapp/features/prospects/prospect_issue_identity.dart';
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

  test('ein paralleler Read wartet auf einen Favoriten-Write', () async {
    final store = ProspectFavoritesStore();
    final reader = ProspectFavoritesStore();
    final writing = store.save(['Lidl', 'ALDI Süd']);
    final reading = reader.load();

    await writing;
    expect(await reading, {'ALDI Süd', 'Lidl'});
  });

  test('branch-specific favorites do not cross-match same-name stores', () {
    const zellingen = ProspectIssue(
      storeName: 'Lidl',
      branchId: 'lidl-zellingen',
      title: 'Aktionsprospekt',
      pages: [],
    );
    const wuerzburg = ProspectIssue(
      storeName: 'Lidl',
      branchId: 'lidl-wuerzburg',
      title: 'Aktionsprospekt',
      pages: [],
    );

    expect(prospectFavoriteKey(zellingen), 'Lidl#lidl-zellingen');
    expect(
      prospectFavoriteMatches(
        storedKey: prospectFavoriteKey(zellingen),
        issue: zellingen,
      ),
      isTrue,
    );
    expect(
      prospectFavoriteMatches(
        storedKey: prospectFavoriteKey(zellingen),
        issue: wuerzburg,
      ),
      isFalse,
    );
    // Existing store-only data remains readable during migration.
    expect(
      prospectFavoriteMatches(storedKey: 'Lidl', issue: zellingen),
      isTrue,
    );
  });

  test('indexed favorites keep branch and legacy matching semantics', () {
    const zellingen = ProspectIssue(
      storeName: 'Lidl',
      branchId: 'lidl-zellingen',
      title: 'Aktionsprospekt',
      pages: [],
    );
    const wuerzburg = ProspectIssue(
      storeName: 'Lidl',
      branchId: 'lidl-wuerzburg',
      title: 'Aktionsprospekt',
      pages: [],
    );
    final index = ProspectFavoriteIndex.from([
      prospectFavoriteKey(zellingen),
    ]);

    expect(index.matches(zellingen), isTrue);
    expect(index.matches(wuerzburg), isFalse);
    expect(ProspectFavoriteIndex.from(['Lidl']).matches(zellingen), isTrue);
    expect(ProspectFavoriteIndex.from(['Lidl']).matches(wuerzburg), isTrue);
    expect(
      ProspectFavoriteIndex.from([prospectFavoriteKey(zellingen)])
          .matches(const ProspectIssue(
            storeName: 'ALDI Süd',
            branchId: 'aldi-sued',
            title: 'Aktionsprospekt',
            pages: [],
          )),
      isFalse,
    );
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
    expect(addFavorite, findsAtLeastNWidgets(1));

    await tester.tap(addFavorite.first);
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Lidl aus Favoriten entfernen'),
      findsAtLeastNWidgets(1),
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