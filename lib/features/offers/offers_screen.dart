import 'package:flutter/material.dart';

import '../../models/offer.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import 'offer_card.dart';
import 'offer_editor_screen.dart';
import 'offer_filter.dart';
import 'offer_filter_bar.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({
    super.key,
    required this.offers,
    required this.priceHistory,
    required this.onSave,
    required this.onDelete,
    required this.catalogProducts,
  });

  final List<Offer> offers;
  final List<PricePoint> priceHistory;
  final Future<List<Offer>> Function(Offer offer) onSave;
  final Future<List<Offer>> Function(Offer offer) onDelete;
  final List<Product> catalogProducts;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final searchController = TextEditingController();
  late List<Offer> offers;
  var filter = OfferStatusFilter.active;
  var query = '';
  var busy = false;

  @override
  void initState() {
    super.initState();
    offers = [...widget.offers];
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _edit([Offer? offer]) async {
    if (busy || widget.catalogProducts.isEmpty) return;
    setState(() => busy = true);
    try {
      final result = await Navigator.of(context).push<Offer>(
        MaterialPageRoute(
          builder: (_) => OfferEditorScreen(
            offer: offer,
            catalogProducts: widget.catalogProducts,
          ),
        ),
      );
      if (!mounted || result == null) return;
      final next = await widget.onSave(result);
      if (mounted) setState(() => offers = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angebot konnte nicht gespeichert werden.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _delete(Offer offer) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Angebot löschen?'),
            content: const Text('Das Angebot wird dauerhaft aus der App entfernt.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ??
        false;
      if (!mounted || !confirmed) return;

      final next = await widget.onDelete(offer);
      if (mounted) setState(() => offers = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angebot konnte nicht gelöscht werden.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = filterOffers(
      offers,
      status: filter,
      query: query,
      catalogProducts: widget.catalogProducts,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Angebote'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy || widget.catalogProducts.isEmpty ? null : _edit,
        icon: const Icon(Icons.add),
        label: const Text('Angebot'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const Center(child: Text('Die besten Preise. Für dich.')),
          const SizedBox(height: 18),
          OfferFilterBar(
            controller: searchController,
            filter: filter,
            onQueryChanged: (value) => setState(() => query = value),
            onFilterChanged: (value) => setState(() => filter = value),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            _EmptyOffers(filter: filter, hasQuery: query.trim().isNotEmpty)
          else
            for (var index = 0; index < visible.length; index++) ...[
              OfferCard(
                offer: visible[index],
                priceHistory: widget.priceHistory,
                catalogProducts: widget.catalogProducts,
                onEdit: busy ? null : () => _edit(visible[index]),
                onDelete: busy ? null : () => _delete(visible[index]),
              ),
              if (index < visible.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers({required this.filter, required this.hasQuery});

  final OfferStatusFilter filter;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final text = hasQuery
        ? 'Keine passenden Angebote gefunden.'
        : switch (filter) {
            OfferStatusFilter.active => 'Keine aktiven Angebote.',
            OfferStatusFilter.expired => 'Keine abgelaufenen Angebote.',
            OfferStatusFilter.all => 'Noch keine Angebote gespeichert.',
          };

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(child: Text(text)),
    );
  }
}
