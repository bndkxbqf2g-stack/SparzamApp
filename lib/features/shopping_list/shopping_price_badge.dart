import 'package:flutter/material.dart';

import '../../design/sparzam_theme.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../offers/prospect_price_statistics.dart';
import 'shopping_price_quotes.dart';

class ShoppingPriceBadge extends StatelessWidget {
  const ShoppingPriceBadge({
    super.key,
    required this.item,
    required this.prices,
    required this.offers,
    required this.enabledStores,
    this.prospectPriceHistory = const {},
    this.onOpenOffer,
  });

  final ListItem item;
  final List<MarketPrice> prices;
  final List<Offer> offers;
  final List<String> enabledStores;
  final Map<String, ProspectPriceHistorySummary> prospectPriceHistory;
  final ValueChanged<Offer>? onOpenOffer;

  @override
  Widget build(BuildContext context) {
    final quotes = shoppingQuotes(
      item,
      prices: prices,
      offers: offers,
      prospectPriceHistory: prospectPriceHistory,
      enabledStores: enabledStores,
    );
    final matrix = shoppingPriceMatrix(
      item,
      prices: prices,
      offers: offers,
      prospectPriceHistory: prospectPriceHistory,
      enabledStores: enabledStores,
    );
    final pricedMarkets = matrix.where((entry) => entry.hasCurrentQuote).length;
    final historicalMarkets = matrix
        .where((entry) => entry.hasHistoricalQuote)
        .length;
    final offersToday = quotes
        .where((q) => q.kind == ShoppingQuoteKind.offer)
        .toList();
    offersToday.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
    final receiptQuotes = quotes
        .where((q) => q.kind == ShoppingQuoteKind.receipt)
        .toList();
    receiptQuotes.sort((a, b) => b.observedAt!.compareTo(a.observedAt!));
    final highlighted = offersToday.isNotEmpty
        ? offersToday.first
        : receiptQuotes.isNotEmpty
        ? receiptQuotes.first
        : quotes.isNotEmpty
        ? quotes.first
        : null;
    return InkWell(
      onTap: matrix.isEmpty ? null : () => _showQuotes(context, matrix),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sell_outlined, size: 15, color: SparzamTheme.deepGreen),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                highlighted == null
                    ? 'Noch kein belegter Marktpreis'
                    : '${highlighted.displayPrefix} ${highlighted.storeName}: ${highlighted.amountLabel}'
                          '${highlighted.savingsLabel == null ? '' : ' · ${highlighted.savingsLabel}'}'
                          '${quotes.length > 1 ? ' · +${quotes.length - 1}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SparzamTheme.deepGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (matrix.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '$pricedMarkets/${matrix.length} Märkte'
                  '${historicalMarkets == 0 ? '' : ' · $historicalMarkets Historie'}',
                  style: const TextStyle(
                    color: SparzamTheme.deepGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (matrix.isNotEmpty)
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: SparzamTheme.deepGreen,
              ),
          ],
        ),
      ),
    );
  }

  void _showQuotes(
    BuildContext context,
    List<ShoppingPriceMatrixEntry> matrix,
  ) {
    final pricedMarkets = matrix.where((entry) => entry.hasCurrentQuote).length;
    final historicalMarkets = matrix
        .where((entry) => entry.hasHistoricalQuote)
        .length;
    final history = _prospectHistorySummaries();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (item.product.imageUrl?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.product.imageUrl!,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              const Text(
                'Bonpreise zeigen einen vergangenen Einkauf. '
                'Historische Prospekt-Mediane zeigen frühere Angebots- oder '
                'Normalpreisniveaus. Angebote gelten nur unter den Bedingungen '
                'des Händlers.',
              ),
              const SizedBox(height: 6),
              Text(
                '$pricedMarkets von ${matrix.length} Märkten mit aktuellem '
                'Preisbeleg für genau diese Produktvariante.'
                '${historicalMarkets == 0 ? '' : ' $historicalMarkets Markt${historicalMarkets == 1 ? '' : 'e'} mit historischer Prospektorientierung.'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (history.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showProspectHistory(context, history),
                    icon: const Icon(Icons.history, size: 18),
                    label: Text(
                      'Prospekt-Historie (${history.length} '
                      '${history.length == 1 ? 'Markt' : 'Märkte'})',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: matrix.length,
                  itemBuilder: (context, index) {
                    final entry = matrix[index];
                    final quote = entry.quote;
                    if (quote == null) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.help_outline,
                          color: Colors.amber.shade800,
                        ),
                        title: Text(entry.storeName),
                        subtitle: const Text(
                          'Kein aktueller, vergleichbarer Preisbeleg',
                        ),
                        trailing: const Text(
                          'fehlt',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    }
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: quote.offer?.imageUrl?.trim().isNotEmpty == true
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                quote.offer!.imageUrl!,
                                width: 54,
                                height: 54,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.local_offer_outlined),
                              ),
                            )
                          : Icon(
                              quote.isHistorical
                                  ? Icons.history_toggle_off_outlined
                                  : Icons.local_offer_outlined,
                            ),
                      title: Text(
                        '${item.product.name} · ${entry.storeName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${quote.evidenceLabel}'
                        '${quote.savingsLabel == null ? '' : ' · ${quote.savingsLabel}'}',
                      ),
                      trailing: Text(
                        quote.amountLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onTap: quote.offer == null || onOpenOffer == null
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              onOpenOffer!(quote.offer!);
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ProspectPriceHistorySummary> _prospectHistorySummaries() {
    final summaries = [
      ...(prospectPriceHistory[item.product.id]?.allSummaries ??
          const <ProspectPriceHistorySummary>[]),
    ].where((summary) {
      return summary.storeName.trim().isNotEmpty &&
          summary.medianPrice.isFinite &&
          summary.medianPrice > 0 &&
          (enabledStores.isEmpty || enabledStores.contains(summary.storeName));
    }).toList();
    summaries.sort((a, b) {
      final store = a.storeName.compareTo(b.storeName);
      if (store != 0) return store;
      return b.latestValidUntil.compareTo(a.latestValidUntil);
    });
    return summaries;
  }

  void _showProspectHistory(
    BuildContext context,
    List<ProspectPriceHistorySummary> history,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (historyContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.product.name} · Prospekt-Historie',
                style: Theme.of(historyContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Diese Mediane stammen aus abgeschlossenen Prospekten. '
                'Sie zeigen gelernte Preisniveaus und sind keine aktuellen '
                'Angebote oder Routenpreise.',
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final summary in history)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(summary.storeName),
                        subtitle: Text(
                          '${summary.observationCount} '
                          'Prospektbeobachtung(en) · '
                          '${summary.kind == PriceObservationKind.offer ? 'Angebotshistorie' : 'Normalpreishistorie'} · '
                          'bis ${_formatDate(summary.latestValidUntil)}',
                        ),
                        trailing: Text(
                          '${summary.medianPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
