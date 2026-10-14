import 'dart:convert';

import 'prospect_feed_service.dart';

/// Builds the cache key for a validated prospect feed.
///
/// Feed content alone is not sufficient: an unchanged feed must be processed
/// again when the calendar day changes because date-only offer validity can
/// activate or expire records without any source-field change.
String prospectFeedFingerprintFor(
  ProspectFeedLoadResult feed, {
  DateTime? now,
}) {
  final day = now ?? DateTime.now();
  final currentDay = DateTime(day.year, day.month, day.day);
  final values = <Object?>[
    'current-day:' + currentDay.toIso8601String(),
    for (final record in feed.records)
      ...[
        record.sourceId,
        record.productLabel,
        record.storeName,
        record.originalPrice,
        record.offerPrice,
        record.validFrom?.toIso8601String(),
        record.validUntil.toIso8601String(),
        record.source,
        record.proofRef,
        record.imageUrl,
        record.category,
        record.packageSize,
        record.priceByBaseUnit,
        record.sourceAdapter,
        record.regionalOnly,
        record.brochureId,
        record.brochurePage,
        record.publisherId,
        record.capturedAt?.toIso8601String(),
        record.branchId,
        record.location,
        record.address,
      ],
    for (final issue in feed.prospects)
      ...[
        issue.storeName,
        issue.title,
        issue.url,
        issue.thumbnailUrl,
        issue.branchId,
        issue.location,
        issue.address,
        issue.sourceStatus,
        issue.recordCount,
        issue.validFrom?.toIso8601String(),
        issue.validUntil?.toIso8601String(),
        for (final page in issue.pages)
          ...[page.number, page.imageUrl, page.zoomUrl, page.keyWords],
      ],
  ];
  return jsonEncode(values);
}
