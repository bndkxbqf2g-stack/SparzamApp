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
    return InkWell(
      onTap: quotes.isEmpty ? null : () => _showQuotes(context, quotes),
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
                quotes.isEmpty
                    ? 'Noch kein belegter Marktpreis'
                    : quotes.length == 1
                        ? '${quotes.first.storeName}: ${quotes.first.amountLabel}'
                        : '${quotes.length} Marktpreise und Angebote',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SparzamTheme.deepGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (quotes.isNotEmpty)
              const Icon(Icons.chevron_right,
                  size: 16, color: SparzamTheme.deepGreen),
          ],
        ),
      ),
    );
  }

  void _showQuotes(BuildContext context, List<ShoppingQuote> quotes) {
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
              const SizedBox(height: 6),
              const Text(
                'Bonpreise zeigen einen vergangenen Einkauf. '
                'Angebote gelten nur unter den Bedingungen des Händlers.',
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: quotes.length,
                  itemBuilder: (context, index) {
                    final quote = quotes[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(quote.storeName),
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
