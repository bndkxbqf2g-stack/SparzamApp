import 'package:shared_preferences/shared_preferences.dart';

import '../data/offers.dart';
import '../models/offer.dart';
import 'sequential_operation_queue.dart';

class OfferStore {
  static const _key = 'offers_v2';
  static final _queue = SequentialOperationQueue();

  Future<List<Offer>> load() => _queue.schedule(_loadNow);

  Future<List<Offer>> _loadNow() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);

    if (raw == null) {
      // A fresh installation must not make up current offers. Offers enter
      // the store through the verified prospect feed or explicit user input.
      await _saveNow(const <Offer>[]);
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
      await _saveNow(current);
    }
    return current;
  }

  Future<void> save(List<Offer> offers) {
    final snapshot = List<Offer>.of(offers, growable: false);
    return _queue.schedule(() => _saveNow(snapshot));
  }

  Future<void> _saveNow(List<Offer> offers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      offers.map((offer) => offer.toJson()).toList(),
    );
  }

  Future<List<Offer>> upsert(Offer offer, List<Offer> current) {
    final snapshot = List<Offer>.of(current, growable: false);
    return _queue.schedule(() async {
      final next = await _mergeWithStored(snapshot);
      final index = next.indexWhere((item) => item.id == offer.id);
      index < 0 ? next.add(offer) : next[index] = offer;
      await _saveNow(next);
      return next;
    });
  }

  Future<List<Offer>> remove(String id, List<Offer> current) {
    final snapshot = List<Offer>.of(current, growable: false);
    return _queue.schedule(() async {
      final next = (await _mergeWithStored(snapshot))
          .where((offer) => offer.id != id)
          .toList();
      await _saveNow(next);
      return next;
    });
  }

  Future<List<Offer>> _mergeWithStored(List<Offer> current) async {
    final byId = <String, Offer>{
      for (final offer in await _loadNow()) offer.id: offer,
    };
    for (final offer in current) {
      byId[offer.id] = offer;
    }
    return byId.values.toList();
  }
}
