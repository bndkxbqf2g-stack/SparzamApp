import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/sparzam_theme.dart';
import '../../models/product.dart';
import '../offers/offer_import.dart';

/// A prospect offer keeps the public leaflet evidence visible at the point
/// where the user adds the exact offer-backed item to the shopping list.
class ProspectOfferCard extends StatefulWidget {
  const ProspectOfferCard({
    super.key,
    required this.record,
    this.product,
    this.onAdd,
    this.compact = false,
  });

  final OfferImportRecord record;
  final Product? product;
  final VoidCallback? onAdd;
  final bool compact;

  @override
  State<ProspectOfferCard> createState() => _ProspectOfferCardState();
}

class _ProspectOfferCardState extends State<ProspectOfferCard> {
  bool added = false;

  void _add() {
    final callback = widget.onAdd;
    if (callback == null) return;
    callback();
    setState(() => added = true);
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact ? _buildCompact(context) : _buildGrid(context);
  }

  Widget _buildCompact(BuildContext context) {
    final proofUri = _proofUri(widget.record.proofRef);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            _OfferImage(record: widget.record, size: 88),
            const SizedBox(width: 10),
            Expanded(
              child: _OfferSummary(
                record: widget.record,
                product: widget.product,
                compact: true,
              ),
            ),
            const SizedBox(width: 4),
            if (proofUri != null)
              IconButton(
                tooltip: 'Prospektnachweis öffnen',
                onPressed: () => _openProof(proofUri),
                icon: const Icon(Icons.open_in_new),
              ),
            IconButton(
              tooltip: widget.onAdd == null
                  ? 'Artikel noch nicht eindeutig zugeordnet'
                  : added
                  ? 'Noch einmal zur Einkaufsliste'
                  : 'Zur Einkaufsliste',
              onPressed: widget.onAdd == null ? null : _add,
              icon: Icon(
                added ? Icons.check : Icons.add_shopping_cart_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final proofUri = _proofUri(widget.record.proofRef);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OfferImage(record: widget.record, size: 130, expanded: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OfferSummary(record: widget.record, product: widget.product),
                const SizedBox(height: 10),
                if (proofUri != null)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _openProof(proofUri),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Prospektnachweis öffnen'),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onAdd == null ? null : _add,
                    icon: Icon(added ? Icons.check : Icons.add_shopping_cart),
                    label: Text(added ? 'Hinzugefügt' : 'Zur Einkaufsliste'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProof(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Uri? _proofUri(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      uri.host.trim().isEmpty ||
      (scheme != 'http' && scheme != 'https')) {
    return null;
  }
  return uri;
}

class _OfferImage extends StatelessWidget {
  const _OfferImage({
    required this.record,
    required this.size,
    this.expanded = false,
  });

  final OfferImportRecord record;
  final double size;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Icon(
        Icons.local_offer_outlined,
        size: expanded ? 42 : 32,
        color: SparzamTheme.deepGreen,
      ),
    );
    final imageUrl = record.imageUrl;
    final image = imageUrl == null || imageUrl.trim().isEmpty
        ? fallback
        : Image.network(
            imageUrl,
            filterQuality: FilterQuality.low,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          );

    return SizedBox(
      width: expanded ? double.infinity : size,
      height: size,
      child: image,
    );
  }
}

class _OfferSummary extends StatelessWidget {
  const _OfferSummary({
    required this.record,
    required this.product,
    this.compact = false,
  });

  final OfferImportRecord record;
  final Product? product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final savings = record.originalPrice == null
        ? null
        : record.originalPrice! - record.offerPrice;
    final discount = record.originalPrice == null || record.originalPrice! <= 0
        ? null
        : ((savings! / record.originalPrice!) * 100).round();
    final unit = product?.unit.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _price(record.offerPrice),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SparzamTheme.deepGreen,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 16 : 20,
              ),
            ),
            if (record.originalPrice != null)
              Text(
                _price(record.originalPrice!),
                style: const TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            if (discount != null && discount > 0)
              _DiscountBadge(percent: discount),
          ],
        ),
        Text(
          record.productLabel,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 14 : 16,
          ),
        ),
        Text(
          record.storeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        if (record.location?.trim().isNotEmpty == true)
          Text(
            record.location!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        if (record.address?.trim().isNotEmpty == true)
          Text(
            record.address!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        if (unit != null && unit.isNotEmpty && unit != 'Packung')
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        Text(
          'Gültig bis ${_date(record.validUntil)}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          '-$percent %',
          style: const TextStyle(
            color: SparzamTheme.deepGreen,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

String _price(double value) =>
    '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

