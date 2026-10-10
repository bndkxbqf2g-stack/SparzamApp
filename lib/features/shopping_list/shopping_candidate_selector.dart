import 'package:flutter/material.dart';

import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import '../offers/prospect_price_statistics.dart';
import 'shopping_candidate_service.dart';

Future<List<Product>?> showShoppingCandidateSelector({
  required BuildContext context,
  required String request,
  required List<Product> catalogProducts,
  required List<Offer> offers,
  required List<MarketPrice> marketPrices,
  required List<ReceiptPriceStat> receiptPriceStats,
  Map<String, ProspectPriceHistorySummary> prospectPriceHistory = const {},
  required List<String> enabledStores,
  int openPricesMaxAgeDays = 60,
}) {
  final candidates = buildShoppingCandidates(
    request: request,
    catalogProducts: catalogProducts,
    offers: offers,
    marketPrices: marketPrices,
    receiptPriceStats: receiptPriceStats,
    prospectPriceHistory: prospectPriceHistory,
    enabledStores: enabledStores,
    openPricesMaxAgeDays: openPricesMaxAgeDays,
  );
  return showModalBottomSheet<List<Product>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ShoppingCandidateSheet(
      request: request,
      candidates: candidates,
    ),
  );
}

class _ShoppingCandidateSheet extends StatefulWidget {
  const _ShoppingCandidateSheet({required this.request, required this.candidates});

  final String request;
  final List<ShoppingCandidate> candidates;

  @override
  State<_ShoppingCandidateSheet> createState() => _ShoppingCandidateSheetState();
}

class _ShoppingCandidateSheetState extends State<_ShoppingCandidateSheet> {
  final selected = <String>{};
  String? recommendedProductId;

  @override
  void initState() {
    super.initState();
    for (final candidate in widget.candidates) {
      // A current offer or market/receipt quote is strong enough to make a
      // reversible recommendation. Historical prospect medians remain visible
      // context, but must not silently become the user's product choice.
      if (candidate.quotes.any((quote) => !quote.isHistorical)) {
        recommendedProductId = candidate.product.id;
        selected.add(candidate.product.id);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('„${widget.request}“ auswählen',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Mehrere konkrete Artikel möglich. Nur ausgewählte Artikel werden später geroutet.'),
            ),
            if (recommendedProductId != null)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  'Die günstigste aktuell belegte Empfehlung ist bereits '
                  'ausgewählt. Du kannst sie ändern oder weitere Varianten '
                  'hinzunehmen.',
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.candidates.isEmpty
                  ? const Center(child: Text('Noch keine passenden Artikel mit Preisdaten bekannt.'))
                  : ListView.builder(
                      itemCount: widget.candidates.length,
                      itemBuilder: (context, index) {
                        final candidate = widget.candidates[index];
                        final isSelected = selected.contains(candidate.product.id);
                        final isRecommended =
                            candidate.product.id == recommendedProductId;
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              selected.add(candidate.product.id);
                            } else {
                              selected.remove(candidate.product.id);
                            }
                          }),
                          secondary: _CandidateImage(
                            product: candidate.product,
                            fallbackImageUrl: candidate.imageUrl,
                          ),
                          title: Text(
                            isRecommended
                                ? '${candidate.product.name} · Empfehlung'
                                : candidate.product.name,
                          ),
                          subtitle: Text(_quoteText(candidate)),
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(widget.candidates
                          .where((candidate) => selected.contains(candidate.product.id))
                          .map((candidate) => candidate.product)
                          .toList()),
                  icon: const Icon(Icons.check),
                  label: Text('${selected.length} Artikel übernehmen'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _quoteText(ShoppingCandidate candidate) {
  if (candidate.quotes.isEmpty) return 'Kein Preis in den letzten 60 Tagen';
  return candidate.quotes
      .take(4)
      .map((quote) {
        final date = quote.validUntil == null
            ? quote.isHistorical && quote.observedAt != null
                ? ' · Stand ${_date(quote.observedAt!)}'
                : ''
            : ' · bis ${_date(quote.validUntil!)}';
        final labels = <String>[
          if (quote.evidenceLabel != null) quote.evidenceLabel!,
          quote.label,
          if (quote.savings != null)
            'Ersparnis ${quote.savings!.toStringAsFixed(2).replaceAll('.', ',')} €',
        ];
        return '${quote.storeName}: ${quote.price.toStringAsFixed(2).replaceAll('.', ',')} € (${labels.join(' · ')}$date)';
      })
      .join('\n');
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

class _CandidateImage extends StatelessWidget {
  const _CandidateImage({required this.product, this.fallbackImageUrl});

  final Product product;
  final String? fallbackImageUrl;

  @override
  Widget build(BuildContext context) {
    final image = (product.imageUrl ?? fallbackImageUrl)?.trim();
    if (image == null || image.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.shopping_basket_outlined));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(image, width: 52, height: 52, fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported_outlined)),
    );
  }
}
