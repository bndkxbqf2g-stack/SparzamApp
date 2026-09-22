import 'package:shared_preferences/shared_preferences.dart';

import '../data/price_history.dart';
import '../models/price_point.dart';

class PriceHistoryStore {
  static const _key = 'price_history_v1';

  Future<List<PricePoint>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) {
      await save(samplePriceHistory);
      return [...samplePriceHistory];
    }
    return raw.map(PricePoint.fromJson).toList();
  }

  Future<void> save(List<PricePoint> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, history.map((item) => item.toJson()).toList());
  }

  Future<List<PricePoint>> add(PricePoint point, List<PricePoint> current) async {
    final next = [...current, point];
    await save(next);
    return next;
  }
}
