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
}) {
  final candidates = buildShoppingCandidates(
    request: request,
    catalogProducts: catalogProducts,
    offers: offers,
    marketPrices: marketPrices,
    receiptPriceStats: receiptPriceStats,
    prospectPriceHistory: prospectPriceHistory,
    enabledStores: enabledStores,
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
            const SizedBox(height: 8),
            Expanded(
              child: widget.candidates.isEmpty
                  ? const Center(child: Text('Noch keine passenden Artikel mit Preisdaten bekannt.'))
                  : ListView.builder(
                      itemCount: widget.candidates.length,
                      itemBuilder: (context, index) {
                        final candidate = widget.candidates[index];
                        final isSelected = selected.contains(candidate.product.id);
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
                          title: Text(candidate.product.name),
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
        return '${quote.storeName}: ${quote.price.toStringAsFixed(2).replaceAll('.', ',')} € (${quote.label}$date)';
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
