/// Parsed receipt data is a review draft, never a confirmed product price.
enum ReceiptRowKind { item, discount, deposit, returnDeposit, unresolved }

class ReceiptRow {
  const ReceiptRow({
    required this.line,
    required this.label,
    required this.cents,
    required this.kind,
    this.quantity,
    this.unitCents,
    this.linkedItemLine,
  });

  final int line;
  final String label;
  final int cents;
  final ReceiptRowKind kind;
  final num? quantity;
  final int? unitCents;
  /// Only immediate, unambiguous item discounts are linked.
  final int? linkedItemLine;
}

class ReceiptDraft {
  const ReceiptDraft({
    required this.rows,
    required this.totalCents,
    required this.calculatedCents,
    required this.unresolvedLines,
  });

  final List<ReceiptRow> rows;
  final int? totalCents;
  final int calculatedCents;
  final List<int> unresolvedLines;

  bool get balances =>
      totalCents != null && totalCents == calculatedCents &&
      unresolvedLines.isEmpty;
}

/// Handles text-layout exports from Kaufland and Netto. No product matching,
/// discount allocation or account metadata is inferred from the receipt.
ReceiptDraft parseReceiptLedger(String text) {
  final lines = text.split(RegExp(r'\r?\n'));
  final rows = <ReceiptRow>[];
  final unresolved = <int>[];
  final amount = RegExp(r'(-?\d+[,.]\d{2})(?:\*?\s*[AB])?\s*$');
  final total = RegExp(r'^\s*(?:Summe|SUMME\s*\[\d+\])\s+(\d+[,.]\d{2})\s*$');
  final quantityBefore = RegExp(r'^\s*(\d+)\s*x\s*(\d+[,.]\d{2})\s*$');
  final quantityInline = RegExp(r'(\d+)\s*\*\s*(\d+[,.]\d{2})\s*$');
  int? printedTotal;
  bool inItems = false;
  int? pendingQuantity;
  int? pendingUnit;
  String? pendingLabel;
  int? lastItemLine;

  for (var index = 0; index < lines.length; index++) {
    final raw = lines[index];
    final line = raw.trim();
    if (!inItems) {
      if (line == 'Preis EUR' || line == 'EUR') inItems = true;
      continue;
    }
    final totalMatch = total.firstMatch(line);
    if (totalMatch != null) {
      printedTotal = _cents(totalMatch.group(1)!);
      break;
    }
    if (line.isEmpty) continue;
    final quantityMatch = quantityBefore.firstMatch(line);
    if (quantityMatch != null) {
      pendingQuantity = int.parse(quantityMatch.group(1)!);
      pendingUnit = _cents(quantityMatch.group(2)!);
      continue;
    }
    final priceMatch = amount.firstMatch(line);
    if (priceMatch == null) {
      // Product names can wrap to the following quantity/price line.
      if (!line.startsWith('0,') && !line.startsWith('0.')) {
        pendingLabel = line;
      }
      continue;
    }
    final cents = _cents(priceMatch.group(1)!);
    var label = line.substring(0, priceMatch.start).trim();
    num? quantity = pendingQuantity;
    int? unitCents = pendingUnit;
    final inline = quantityInline.firstMatch(label);
    if (inline != null) {
      quantity = int.parse(inline.group(1)!);
      unitCents = _cents(inline.group(2)!);
      label = label.substring(0, inline.start).trim();
    }
    if (label.isEmpty && pendingLabel != null) label = pendingLabel;
    if (label.isEmpty && pendingQuantity == null) {
      unresolved.add(index + 1);
      continue;
    }
    pendingLabel = null;
    pendingQuantity = null;
    pendingUnit = null;
    final lower = label.toLowerCase();
    final isDiscount = cents < 0 && (lower.contains('rabatt') ||
        lower.contains('preisvorteil'));
    final isReturn = lower.startsWith('leergut getränke') && cents < 0;
    final isDeposit = lower.contains('pfand') ||
        lower.startsWith('leergut ');
    final kind = isDiscount ? ReceiptRowKind.discount
        : isReturn ? ReceiptRowKind.returnDeposit
        : isDeposit ? ReceiptRowKind.deposit
        : cents < 0 ? ReceiptRowKind.unresolved
        : ReceiptRowKind.item;
    final linked = isDiscount && !lower.contains('warenkorb') &&
        lastItemLine != null
        ? lastItemLine : null;
    rows.add(ReceiptRow(
      line: index + 1,
      label: label,
      cents: cents,
      kind: kind,
      quantity: quantity,
      unitCents: unitCents,
      linkedItemLine: linked,
    ));
    if (kind == ReceiptRowKind.item) lastItemLine = index + 1;
    if (kind == ReceiptRowKind.deposit ||
        kind == ReceiptRowKind.returnDeposit) lastItemLine = null;
    if (quantity != null && unitCents != null &&
        quantity * unitCents != cents) {
      unresolved.add(index + 1);
    }
    if (kind == ReceiptRowKind.unresolved) {
      unresolved.add(index + 1);
    }
  }
  if (pendingQuantity != null || pendingLabel != null) {
    unresolved.add(lines.length);
  }
  return ReceiptDraft(
    rows: rows,
    totalCents: printedTotal,
    calculatedCents: rows.fold(0, (sum, row) => sum + row.cents),
    unresolvedLines: unresolved,
  );
}

int _cents(String value) {
  final negative = value.startsWith('-');
  final parts = value.replaceAll('-', '').replaceAll(',', '.').split('.');
  final result = int.parse(parts[0]) * 100 + int.parse(parts[1]);
  return negative ? -result : result;
}
