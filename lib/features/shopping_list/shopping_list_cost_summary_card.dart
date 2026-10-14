import 'package:flutter/material.dart';

import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../offers/prospect_price_statistics.dart';
import 'shopping_price_quotes.dart';

/// Summarizes the evidence currently available for the visible shopping list.
///
/// The card is intentionally conservative: only a current quote contributes
/// to the known basket value. Historical prospect medians remain visible as
/// context, while missing prices never become a zero-valued item.
class ShoppingListCostSummaryCard extends StatelessWidget {
  const ShoppingListCostSummaryCard({
    super.key,
    required this.items,
    required this.marketPrices,
    required this.offers,
    this.prospectPriceHistory = const <String, ProspectPriceHistorySummary>{},
    this.enabledStoreNames = const <String>[],
    this.openPricesMaxAgeDays = 60,
    this.now,
    this.quoteSnapshot,
    this.onOpenRoute,
  });

  final List<ListItem> items;
  final List<MarketPrice> marketPrices;
  final List<Offer> offers;
  final Map<String, ProspectPriceHistorySummary> prospectPriceHistory;
  final List<String> enabledStoreNames;
  final int openPricesMaxAgeDays;
  final DateTime? now;
  final ShoppingPriceQuoteSnapshot? quoteSnapshot;
  final VoidCallback? onOpenRoute;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.price_check_outlined),
          title: Text('Preisabdeckung deiner Liste'),
          subtitle: Text('Füge Artikel hinzu, um aktuelle Preise zu vergleichen.'),
        ),
      );
    }

    var currentCount = 0;
    var historicalCount = 0;
    var unknownCount = 0;
    var knownTotal = 0.0;

    for (final item in items) {
      final quotes = quoteSnapshot?.quotesFor(item) ??
          shoppingQuotes(
            item,
            prices: marketPrices,
            offers: offers,
            prospectPriceHistory: prospectPriceHistory,
            enabledStores: enabledStoreNames,
            openPricesMaxAgeDays: openPricesMaxAgeDays,
            now: now,
          );
      final current = quotes.where((quote) => !quote.isHistorical).toList()
        ..sort(compareShoppingQuotes);
      if (current.isNotEmpty) {
        currentCount++;
        knownTotal += current.first.unitPrice * item.quantity;
      } else if (quotes.any((quote) => quote.isHistorical)) {
        historicalCount++;
      } else {
        unknownCount++;
      }
    }

    final complete = currentCount == items.length;
    final valueLabel = complete
        ? 'Aktueller Warenwert'
        : 'Bekannter Warenwert';
    final amount = '${knownTotal.toStringAsFixed(2).replaceAll('.', ',')} €';

    return Card(
      color: complete ? null : Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preisabdeckung deiner Liste',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text('Aktuell $currentCount'),
                ),
                if (historicalCount > 0)
                  Chip(
                    avatar: const Icon(Icons.history, size: 18),
                    label: Text('Historisch $historicalCount'),
                  ),
                if (unknownCount > 0)
                  Chip(
                    avatar: const Icon(Icons.help_outline, size: 18),
                    label: Text('Unbekannt $unknownCount'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    valueLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              complete
                  ? 'Alle Positionen haben mindestens einen aktuellen, vergleichbaren Preis.'
                  : 'Fehlende Positionen werden nicht als 0 € gerechnet. '
                      'Historische Werte sind nur Orientierung.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (onOpenRoute != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onOpenRoute,
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('Preisabdeckung in der Route prüfen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
