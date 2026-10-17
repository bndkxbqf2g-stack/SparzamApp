import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../receipt/receipt_ocr.dart';
import '../../services/prospect_feed_service.dart';

/// The OCR result is deliberately separate from [OfferImportRecord]. OCR is a
/// suggestion only and must pass the existing page-offer review before it can
/// become a stored offer or a route price.
enum ProspectPageOcrStatus {
  ready,
  unsupported,
  unavailable,
  noText,
}

enum ProspectPageOcrConfidence {
  high,
  medium,
  low,
}

String prospectPageOcrConfidenceLabel(ProspectPageOcrConfidence confidence) =>
    switch (confidence) {
      ProspectPageOcrConfidence.high => 'HOHE SICHERHEIT',
      ProspectPageOcrConfidence.medium => 'MITTLERE SICHERHEIT',
      ProspectPageOcrConfidence.low => 'NIEDRIGE SICHERHEIT',
    };

class ProspectPageOcrCandidate {
  const ProspectPageOcrCandidate({
    required this.productLabel,
    required this.offerPrice,
    required this.confidence,
    this.originalPrice,
  });

  final String productLabel;
  final double offerPrice;
  final double? originalPrice;
  final ProspectPageOcrConfidence confidence;
}

class ProspectPageOcrResult {
  const ProspectPageOcrResult({
    required this.status,
    required this.message,
    this.candidates = const <ProspectPageOcrCandidate>[],
  });

  final ProspectPageOcrStatus status;
  final String message;
  final List<ProspectPageOcrCandidate> candidates;

  bool get isReady =>
      status == ProspectPageOcrStatus.ready && candidates.isNotEmpty;
}

typedef ProspectPageTextRecognizer = Future<String?> Function(Uint8List bytes);

const _maxProspectPageOcrBytes = 8 * 1024 * 1024;
final _prospectPageMoney = RegExp(
  r'(?:€|EUR)\s*(\d{1,3}(?:[.,]\d{1,2})?)|'
  r'(\d{1,3}(?:[.,]\d{1,2})?)\s*(?:€|EUR)(?!\w)',
  caseSensitive: false,
);
final _prospectPageNonProductLine = RegExp(
  r'^(?:summe|gesamt|zu zahlen|zahlbetrag|mwst|ust|rabatt|'
  r'coupon|gutschein|pfand|änderung|aenderung|bar|ec|karte|'
  r'vielen dank|kassenbon|datum|uhrzeit)\b',
  caseSensitive: false,
);

/// Parses OCR text into conservative product/price suggestions.
/// Both `1,99 €` and `€ 1,99` are accepted; a bare number remains ignored.
///
/// A line without an explicit euro amount is never promoted to a candidate.
/// Totals, payment lines and common receipt metadata are ignored because they
/// are not product evidence. The parser does not assign a catalog identity.
List<ProspectPageOcrCandidate> parseProspectPageOcrText(String text) {
  final seen = <String>{};
  final candidates = <ProspectPageOcrCandidate>[];
  for (final rawLine in text.split(RegExp(r'[\r\n]+'))) {
    final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (line.isEmpty || _prospectPageNonProductLine.hasMatch(line)) continue;
    final matches = _prospectPageMoney.allMatches(line).toList(growable: false);
    if (matches.isEmpty) continue;

    final prices = <double>[];
    for (final match in matches) {
      final token = match.group(1) ?? match.group(2);
      if (token == null) continue;
      final normalized = token.replaceAll(',', '.');
      final value = double.tryParse(normalized);
      if (value == null || !value.isFinite || value <= 0 || value > 500) {
        continue;
      }
      prices.add(value);
    }
    if (prices.isEmpty) continue;

    final firstPrice = matches.first;
    var label = line.substring(0, firstPrice.start).trim();
    if (label.isEmpty && firstPrice.end < line.length) {
      label = line.substring(firstPrice.end).trim();
    }
    label = label
        .replaceAll(RegExp(r'^[|•·*:+-]+'), '')
        .replaceAll(RegExp(r'[|•·*]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (label.length < 2) continue;

    prices.sort();
    final offerPrice = prices.first;
    final originalPrice = prices.length > 1 && prices.last > offerPrice
        ? prices.last
        : null;
    final confidence = _candidateConfidence(
      label,
      priceCount: matches.length,
    );
    final key = '${label.toLowerCase()}|${offerPrice.toStringAsFixed(2)}';
    if (!seen.add(key)) continue;
    candidates.add(
      ProspectPageOcrCandidate(
        productLabel: label,
        offerPrice: offerPrice,
        originalPrice: originalPrice,
        confidence: confidence,
      ),
    );
    if (candidates.length >= 20) break;
  }
  return candidates;
}

ProspectPageOcrConfidence _candidateConfidence(
  String label, {
  required int priceCount,
}) {
  if (label.length >= 8 && priceCount <= 2) {
    return ProspectPageOcrConfidence.high;
  }
  if (label.length >= 5) return ProspectPageOcrConfidence.medium;
  return ProspectPageOcrConfidence.low;
}

Future<ProspectPageOcrResult> analyzeProspectPage(
  ProspectPage page, {
  http.Client? client,
  ProspectPageTextRecognizer? recognizeText,
}) async {
  final rawUrl = page.imageUrl.trim();
  final uri = Uri.tryParse(rawUrl);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      uri.host.isEmpty ||
      (scheme != 'http' && scheme != 'https')) {
    return const ProspectPageOcrResult(
      status: ProspectPageOcrStatus.unavailable,
      message: 'Diese Prospektseite hat keinen gültigen öffentlichen Bildlink.',
    );
  }
  if (!supportsReceiptImageOcr && recognizeText == null) {
    return const ProspectPageOcrResult(
      status: ProspectPageOcrStatus.unsupported,
      message:
          'Bild-OCR ist auf dieser Plattform nicht verfügbar. Bitte die Seite '
          'manuell prüfen.',
    );
  }

  final httpClient = client ?? http.Client();
  final ownsClient = client == null;
  try {
    final response = await httpClient
        .get(
          uri,
          headers: const {
            'Accept': 'image/*',
            'User-Agent': 'SparzamApp/1.0 (prospect page review)',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return ProspectPageOcrResult(
        status: ProspectPageOcrStatus.unavailable,
        message:
            'Prospektseite konnte nicht geladen werden (HTTP ${response.statusCode}).',
      );
    }
    if (response.bodyBytes.isEmpty ||
        response.bodyBytes.length > _maxProspectPageOcrBytes) {
      return const ProspectPageOcrResult(
        status: ProspectPageOcrStatus.unavailable,
        message: 'Die Prospektseite ist für die lokale Prüfung nicht geeignet.',
      );
    }

    final text = await (recognizeText ??
        (bytes) => readReceiptImageText(bytes: bytes))(
      response.bodyBytes,
    );
    if (text == null || text.trim().isEmpty) {
      return const ProspectPageOcrResult(
        status: ProspectPageOcrStatus.noText,
        message: 'Auf dieser Seite wurde kein lesbarer Angebotstext erkannt.',
      );
    }
    final candidates = parseProspectPageOcrText(text);
    if (candidates.isEmpty) {
      return const ProspectPageOcrResult(
        status: ProspectPageOcrStatus.noText,
        message:
            'Es wurden keine eindeutigen Produktpreise erkannt. Bitte die Seite '
            'manuell prüfen.',
      );
    }
    return ProspectPageOcrResult(
      status: ProspectPageOcrStatus.ready,
      message:
          '${candidates.length} Vorschlag${candidates.length == 1 ? '' : 'e'} '
          'gefunden. Vor dem Speichern bitte prüfen.',
      candidates: candidates,
    );
  } catch (_) {
    return const ProspectPageOcrResult(
      status: ProspectPageOcrStatus.unavailable,
      message: 'Die lokale Seitenprüfung ist momentan nicht verfügbar.',
    );
  } finally {
    if (ownsClient) httpClient.close();
  }
}
