import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/sparzam_theme.dart';
import '../../models/product.dart';
import '../catalog/unit_price.dart';
import '../offers/offer_import.dart';

/// A prospect offer keeps the public leaflet evidence visible at the point
/// where the user adds the exact offer-backed item to the shopping list.
class ProspectOfferCard extends StatefulWidget {
  const ProspectOfferCard({
    super.key,
    required this.record,
    this.product,
    this.onAdd,
    this.requiresManualConfirmation = false,
    this.listOnlyWithoutBranch = false,
    this.compact = false,
  });

  final OfferImportRecord record;
  final Product? product;
  final VoidCallback? onAdd;
  final bool requiresManualConfirmation;
  /// The item has current evidence but no exact branch. It can be added to
  /// the list after confirmation; it must not be treated as a route offer.
  final bool listOnlyWithoutBranch;
  final bool compact;

  @override
  State<ProspectOfferCard> createState() => _ProspectOfferCardState();
}

class _ProspectOfferCardState extends State<ProspectOfferCard> {
  bool added = false;

  void _add() {
    unawaited(_addAfterConfirmation());
  }

  Future<void> _addAfterConfirmation() async {
    final callback = widget.onAdd;
    if (callback == null) return;
    if (widget.requiresManualConfirmation) {
      final accepted = await _confirmManualAdd();
      if (!accepted || !mounted) return;
    }
    callback();
    if (!mounted) return;
    setState(() => added = true);
  }

  Future<bool> _confirmManualAdd() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Artikelidentität prüfen'),
          content: Text(
            widget.listOnlyWithoutBranch
                ? 'Für „${widget.record.productLabel}“ ist aktuell nur ein '
                    'regionaler Prospektnachweis vorhanden. Als eigenen '
                    'Artikel ohne Filialpreis in die Einkaufsliste übernehmen?'
                : 'Die Prospektquelle lässt für „${widget.record.productLabel}“ '
                    'keine eindeutige Katalogvariante zu. Als eigener Artikel '
                    'mit der exakten Bezeichnung in die Einkaufsliste '
                    'übernehmen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Als Artikel übernehmen'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: widget.compact ? _buildCompact(context) : _buildGrid(context),
    );
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
                  : widget.requiresManualConfirmation
                  ? widget.listOnlyWithoutBranch
                      ? 'Regional prüfen und nur zur Einkaufsliste'
                      : 'Bezeichnung prüfen und als Artikel übernehmen'
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
                    label: Text(
                      added
                          ? 'Hinzugefügt'
                          : widget.requiresManualConfirmation
                          ? widget.listOnlyWithoutBranch
                              ? 'Prüfen & nur zur Einkaufsliste'
                              : 'Prüfen & übernehmen'
                          : 'Zur Einkaufsliste',
                    ),
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
    final imageUrl = _imageUri(record.imageUrl);
    final image = imageUrl == null
        ? fallback
        : Image.network(
            imageUrl,
            // Offer grids can contain hundreds of records. Keep each tile on
            // the Canvas renderer so scrolling does not create one HTML
            // platform view per external retailer image. The prospect viewer
            // is the intentional single-image HTML fallback boundary.
            cacheWidth: expanded ? 720 : 360,
            cacheHeight: expanded ? 520 : 360,
            filterQuality: FilterQuality.low,
            webHtmlElementStrategy: WebHtmlElementStrategy.never,
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

String? _imageUri(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      uri.host.trim().isEmpty ||
      (scheme != 'http' && scheme != 'https')) {
    return null;
  }
  return raw;
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
    final validOriginalPrice = record.originalPrice != null &&
            record.originalPrice! > record.offerPrice &&
            record.originalPrice! > 0
        ? record.originalPrice
        : null;
    final savings = validOriginalPrice == null
        ? null
        : validOriginalPrice - record.offerPrice;
    final discount = validOriginalPrice == null
        ? null
        : ((savings! / validOriginalPrice) * 100).round();
    final unit = product?.unit.trim() ?? record.packageSize?.trim();
    final baseUnitPrice = product == null
        ? null
        : baseUnitPriceLabel(product!, record.offerPrice);
    final sourceBaseUnitPrice = baseUnitPrice == null
        ? record.priceByBaseUnit?.trim()
        : null;

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
            if (validOriginalPrice != null)
              Text(
                _price(validOriginalPrice),
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
        if (record.sourceAdapter?.trim().isNotEmpty == true)
          Text(
            'Quelle ${_sourceAdapterLabel(record.sourceAdapter!)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        if (record.regionalOnly)
          const Text(
            'Nur regional erkannt · Filiale noch nicht bestätigt',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.deepOrange,
              fontWeight: FontWeight.w700,
            ),
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
        if (baseUnitPrice != null)
          Text(
            'Grundpreis $baseUnitPrice',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        if (sourceBaseUnitPrice != null && sourceBaseUnitPrice.isNotEmpty)
          Text(
            'Grundpreis $sourceBaseUnitPrice',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        if (record.validFrom != null)
          Text(
            'Gültig ab ${_date(record.validFrom!)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        Text(
          'Gültig bis ${_date(record.validUntil)}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        if (record.capturedAt != null)
          Text(
            'Erfasst ${_dateTime(record.capturedAt!)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        if (record.brochurePage != null)
          Text(
            'Prospektseite ${record.brochurePage}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
      ],
    );
  }
}

String _sourceAdapterLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'kaufda':
      return 'KaufDA';
    case 'bring':
      return 'Bring';
    case 'structured_api':
      return 'Offizielle Händlerquelle';
    case 'structured_leaflet':
      return 'Offizieller Prospekt';
    case 'website_fallback':
      return 'Händler-Webseite';
    case 'netto':
      return 'Netto-Prospekt';
    default:
      return value.trim();
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

String _dateTime(DateTime value) {
  final local = value.toLocal();
  return '${_date(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} Uhr';
}


