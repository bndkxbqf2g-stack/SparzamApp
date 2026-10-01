import 'package:flutter/material.dart';

import '../../design/sparzam_theme.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import 'shopping_price_quotes.dart';

class ShoppingPriceBadge extends StatelessWidget {
  const ShoppingPriceBadge({
    super.key,
    required this.item,
    required this.prices,
    required this.offers,
    required this.enabledStores,
    this.onOpenOffer,
  });

  final ListItem item;
  final List<MarketPrice> prices;
  final List<Offer> offers;
  final List<String> enabledStores;
  final ValueChanged<Offer>? onOpenOffer;

  @override
  Widget build(BuildContext context) {
    final quotes = shoppingQuotes(
      item,
      prices: prices,
      offers: offers,
      enabledStores: enabledStores,
    );
    final matrix = shoppingPriceMatrix(
      item,
      prices: prices,
      offers: offers,
      enabledStores: enabledStores,
    );
    final pricedMarkets = matrix.where((entry) => entry.hasQuote).length;
    final offersToday = quotes.where((q) => q.kind == ShoppingQuoteKind.offer).toList();
    offersToday.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
    final receiptQuotes = quotes.where((q) => q.kind == ShoppingQuoteKind.receipt).toList();
    receiptQuotes.sort((a, b) => b.observedAt!.compareTo(a.observedAt!));
    final highlighted = offersToday.isNotEmpty
        ? offersToday.first
        : receiptQuotes.isNotEmpty
            ? receiptQuotes.first
            : quotes.isNotEmpty ? quotes.first : null;
    return InkWell(
      onTap: matrix.isEmpty ? null : () => _showQuotes(context, matrix),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sell_outlined,
                size: 15, color: SparzamTheme.deepGreen),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                highlighted == null
                    ? 'Noch kein belegter Marktpreis'
                    : '${highlighted.displayPrefix} ${highlighted.storeName}: ${highlighted.amountLabel}'
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
                  '$pricedMarkets/${matrix.length} Märkte',
                  style: const TextStyle(
                    color: SparzamTheme.deepGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (matrix.isNotEmpty)
              const Icon(Icons.chevron_right,
                  size: 16, color: SparzamTheme.deepGreen),
          ],
        ),
      ),
    );
  }

  void _showQuotes(
    BuildContext context,
    List<ShoppingPriceMatrixEntry> matrix,
  ) {
    final pricedMarkets = matrix.where((entry) => entry.hasQuote).length;
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
              Text(item.product.name,
                  style: Theme.of(context).textTheme.titleLarge),
              if (item.product.imageUrl?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.product.imageUrl!,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              const Text(
                'Bonpreise zeigen einen vergangenen Einkauf. '
                'Angebote gelten nur unter den Bedingungen des Händlers.',
              ),
              const SizedBox(height: 6),
              Text(
                '$pricedMarkets von ${matrix.length} Märkten mit belastbarem '
                'Preisbeleg für genau diese Produktvariante.',
                style: Theme.of(context).textTheme.bodySmall,
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
                          : const Icon(Icons.local_offer_outlined),
                      title: Text(
                        '${item.product.name} · ${entry.storeName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(quote.sourceLabel),
                      trailing: Text(quote.amountLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
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
}
