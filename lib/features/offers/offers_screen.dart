import 'package:flutter/material.dart';

import '../../models/offer.dart';
import '../../models/price_point.dart';
import 'offer_card.dart';
import 'offer_editor_screen.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({
    super.key,
    required this.offers,
    required this.priceHistory,
    required this.onSave,
    required this.onDelete,
  });

  final List<Offer> offers;
  final List<PricePoint> priceHistory;
  final Future<void> Function(Offer offer) onSave;
  final Future<void> Function(Offer offer) onDelete;

  Future<void> _edit(BuildContext context, [Offer? offer]) async {
    final result = await Navigator.of(context).push<Offer>(
      MaterialPageRoute(builder: (_) => OfferEditorScreen(offer: offer)),
    );
    if (result != null) await onSave(result);
  }

  Future<void> _delete(BuildContext context, Offer offer) async {
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
    if (confirmed) await onDelete(offer);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Angebote')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
          label: const Text('Angebot'),
        ),
        body: offers.isEmpty
            ? const Center(child: Text('Noch keine Angebote gespeichert.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: offers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (_, index) => OfferCard(
                  offer: offers[index],
                  priceHistory: priceHistory,
                  onEdit: () => _edit(context, offers[index]),
                  onDelete: () => _delete(context, offers[index]),
                ),
              ),
      );
}
