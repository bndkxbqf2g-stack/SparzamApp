import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/offers/offers_screen.dart';
import 'package:sparzamapp/features/prospects/prospect_cover_section.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  testWidgets('zeigt Coverkarten im Angebote-Reiter und öffnet die Seitenansicht', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final issue = ProspectIssue(
      storeName: 'Lidl',
      title: 'Aktionsprospekt',
      pages: const [
        ProspectPage(
          number: 1,
          imageUrl: 'https://example.test/lidl-cover.jpg',
        ),
      ],
      thumbnailUrl: 'https://example.test/lidl-cover.jpg',
      location: 'Thüngersheim',
      sourceStatus: 'ok',
      recordCount: 12,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectIssues: [issue],
          now: DateTime(2026, 10, 13),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Deine Favoriten'), findsOneWidget);
    expect(find.text('Weitere Prospekte'), findsOneWidget);
    // Both the favorite rail and the grid use the bounded adaptive image;
    // only failed Canvas decodes may opt into the HTML fallback.
    expect(find.byType(ProspectAdaptiveImage), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('offer-cover-open-grid-Lidl')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('offer-cover-open-grid-Lidl'),
            ),
          )
          .height,
      324,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('offer-cover-open-favorite-Lidl'),
            ),
          )
          .height,
      340,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('offer-cover-details-grid-Lidl'),
            ),
          )
          .height,
      156,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('offer-cover-details-favorite-Lidl'),
            ),
          )
          .height,
      159,
    );

    final cover = find.byKey(
      const ValueKey('offer-cover-open-grid-Lidl'),
    );
    await tester.ensureVisible(cover);
    await tester.tap(cover);
    await tester.pumpAndSettle();

    expect(find.text('Prospektseiten (1)'), findsOneWidget);
    expect(find.text('Aktionsprospekt'), findsOneWidget);
  });

  testWidgets('verwendet URL-spezifische Schlüssel für adaptive Coverbilder', (
    tester,
  ) async {
    const firstUrl = 'https://example.test/lidl-cover.jpg';
    const secondUrl = 'https://example.test/aldi-cover.jpg';

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            ProspectAdaptiveImage(
              url: firstUrl,
              cacheWidth: 120,
              cacheHeight: 100,
              fit: BoxFit.cover,
              placeholder: const SizedBox.shrink(),
            ),
            ProspectAdaptiveImage(
              url: secondUrl,
              cacheWidth: 120,
              cacheHeight: 100,
              fit: BoxFit.cover,
              placeholder: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('prospect-adaptive-image-https://example.test/lidl-cover.jpg')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prospect-adaptive-image-https://example.test/aldi-cover.jpg')),
      findsOneWidget,
    );
  });

  testWidgets('zeigt gleichnamige Filialen als getrennte Prospektkarten', (
    tester,
  ) async {
    final issues = [
      ProspectIssue(
        storeName: 'Lidl',
        title: 'Filiale Zellingen',
        pages: const [
          ProspectPage(
            number: 1,
            imageUrl: 'https://example.test/lidl-zellingen.jpg',
          ),
        ],
        thumbnailUrl: 'https://example.test/lidl-zellingen.jpg',
        branchId: 'LIDL-ZELLINGEN',
        location: 'Zellingen',
        validFrom: DateTime(2026, 10, 12),
        validUntil: DateTime(2026, 10, 17),
      ),
      ProspectIssue(
        storeName: 'Lidl',
        title: 'Filiale Würzburg',
        pages: const [
          ProspectPage(
            number: 1,
            imageUrl: 'https://example.test/lidl-wuerzburg.jpg',
          ),
        ],
        thumbnailUrl: 'https://example.test/lidl-wuerzburg.jpg',
        branchId: 'lidl-wuerzburg',
        location: 'Würzburg',
        validFrom: DateTime(2026, 10, 12),
        validUntil: DateTime(2026, 10, 17),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectIssues: issues,
          now: DateTime(2026, 10, 13),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('offer-cover-open-grid-Lidl#lidl-zellingen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('offer-cover-open-grid-Lidl#lidl-wuerzburg')),
      findsOneWidget,
    );
    // Each branch is rendered in both the favorite rail and the grid.
    expect(find.text('Zellingen'), findsNWidgets(2));
    expect(find.text('Würzburg'), findsNWidgets(2));
  });

}
