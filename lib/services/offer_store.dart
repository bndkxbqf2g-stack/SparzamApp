import 'package:shared_preferences/shared_preferences.dart';

import '../data/offers.dart';
import '../models/offer.dart';

class OfferStore {
  static const _key = 'offers_v2';

  Future<List<Offer>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);

    if (raw == null) {
      // A fresh installation must not make up current offers. Offers enter
      // the store through the verified prospect feed or explicit user input.
      await save(const <Offer>[]);
      return <Offer>[];
    }

    final offers = <Offer>[];
    for (final value in raw) {
      try {
        offers.add(Offer.fromJson(value));
      } catch (_) {
        // Einzelne defekte Angebote dürfen den restlichen Bestand nicht blockieren.
      }
    }
    // Older releases seeded sample offers on first start. Remove exactly
    // those known demo IDs while preserving all user-created offers.
    final sampleIds = sampleOffers.map((offer) => offer.id).toSet();
    final current = offers
        .where((offer) => !sampleIds.contains(offer.id))
        .toList(growable: false);
    if (current.length != offers.length) {
      await save(current);
    }
    return current;
  }

  Future<void> save(List<Offer> offers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      offers.map((offer) => offer.toJson()).toList(),
    );
  }

  Future<List<Offer>> upsert(Offer offer, List<Offer> current) async {
    final next = [...current];
    final index = next.indexWhere((item) => item.id == offer.id);
    index < 0 ? next.add(offer) : next[index] = offer;
    await save(next);
    return next;
  }

  Future<List<Offer>> remove(String id, List<Offer> current) async {
    final next = current.where((offer) => offer.id != id).toList();
    await save(next);
    return next;
  }
}
