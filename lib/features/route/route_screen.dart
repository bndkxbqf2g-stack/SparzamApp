import 'package:flutter/material.dart';

import '../../models/list_item.dart';
import '../../models/offer.dart';
import 'route_alternative_card.dart';
import 'route_optimizer.dart';
import 'route_store_card.dart';
import 'route_summary_card.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({
    super.key,
    required this.items,
    required this.offers,
  });

  final List<ListItem> items;
  final List<Offer> offers;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyRoute();

    final optimizer = RouteOptimizer(items, offers);
    final best = optimizer.bestPlan();
    if (best == null) return const _MissingPrices();

    final single = optimizer.bestSingleStorePlan();
    final savings = single == null ? 0.0 : single.total - best.total;
    final alternatives = optimizer.alternatives();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text(
          'Einkaufsoptimierung',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Verglichen werden Normalpreise, aktive Angebote, Coupons, '
          'Cashback und Fahrtkosten für bis zu 3 Märkte.',
        ),
        const SizedBox(height: 18),
        RouteSummaryCard(best: best, extraSavings: savings),
        const SizedBox(height: 18),
        _Title('Dein Einkaufsplan'),
        const SizedBox(height: 10),
        for (final store in best.stores)
          RouteStoreCard(
            store: store,
            items: best.assignments[store]!,
            prices: optimizer.prices,
          ),
        const SizedBox(height: 18),
        _Title('Vergleich'),
        const SizedBox(height: 10),
        for (final plan in alternatives.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RouteAlternativeCard(plan: plan),
          ),
        const SizedBox(height: 10),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Fahrtkosten: weiterhin 0,22 €/km für Hin- und Rückfahrt je '
              'Markt. Der Warenkorb verwendet jetzt bereits den effektiven '
              'Preis nach Angebot, Coupon, Cashback und Mehrfachkauf.',
            ),
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      );
}

class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Füge zuerst Produkte zu deiner Einkaufsliste hinzu.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _MissingPrices extends StatelessWidget {
  const _MissingPrices();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Für mindestens einen Artikel ist noch kein Marktpreis hinterlegt.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}
