import 'package:shared_preferences/shared_preferences.dart';

import '../data/offers.dart';
import '../models/offer.dart';

class OfferStore {
  static const _key = 'offers_v2';
  static const _demoVersionKey = 'offers_demo_version';
  static const _demoVersion = 3;

  Future<List<Offer>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);

    if (raw == null) {
      await save(sampleOffers);
      await prefs.setInt(_demoVersionKey, _demoVersion);
      return [...sampleOffers];
    }

    var offers = raw.map(Offer.fromJson).toList();
    if ((prefs.getInt(_demoVersionKey) ?? 0) < _demoVersion) {
      offers = _refreshDemoOffers(offers);
      await save(offers);
      await prefs.setInt(_demoVersionKey, _demoVersion);
    }
    return offers;
  }

  Future<void> save(List<Offer> offers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, offers.map((offer) => offer.toJson()).toList());
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

  List<Offer> _refreshDemoOffers(List<Offer> current) {
    final demos = {for (final offer in sampleOffers) offer.id: offer};
    return current.map((offer) => demos[offer.id] ?? offer).toList();
  }
}
