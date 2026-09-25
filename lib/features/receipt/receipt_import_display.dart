import 'receipt_ledger.dart';

typedef ReceiptDisplayEntry = ({String name, ReceiptDraft draft});

List<ReceiptDisplayEntry> orderReceiptDraftsForDisplay(
  Iterable<ReceiptDisplayEntry> entries,
) {
  final drafts = [...entries];
  drafts.sort((a, b) {
    final balanceCompare =
        (b.draft.balances ? 1 : 0).compareTo(a.draft.balances ? 1 : 0);
    if (balanceCompare != 0) return balanceCompare;
    return a.name.compareTo(b.name);
  });
  return drafts;
}

int importableReceiptCount(Iterable<ReceiptDisplayEntry> entries) =>
    entries.where((entry) => entry.draft.balances).length;
