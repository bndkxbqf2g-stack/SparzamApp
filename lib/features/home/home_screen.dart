import 'package:flutter/material.dart';

import 'dashboard_data.dart';
import 'dashboard_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.data,
    required this.onOpenList,
    required this.onOpenRoute,
    required this.onOpenOffers,
    required this.onOpenBudget,
    required this.onOpenScanner,
  });

  final DashboardData data;
  final VoidCallback onOpenList;
  final VoidCallback onOpenRoute;
  final VoidCallback onOpenOffers;
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenScanner;

  String euro(double value) => '${value.toStringAsFixed(2)} €';

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text(
            'sparzamApp',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Text('Dein Einkaufs- und Spar-Dashboard'),
          const SizedBox(height: 20),
          DashboardTile(
            icon: Icons.savings_outlined,
            title: 'Heutiges Sparpotenzial',
            value: euro(data.todaySavings),
            subtitle: data.itemCount == 0 ? 'Noch keine Einkaufsliste' : 'gegenüber bestem Einzelmarkt',
            onTap: data.itemCount == 0 ? onOpenList : onOpenRoute,
          ),
          const SizedBox(height: 10),
          DashboardTile(
            icon: Icons.route_outlined,
            title: 'Günstigste Route',
            value: data.routeNames,
            subtitle: data.routeTotal == 0
                ? 'Route berechnen'
                : '${euro(data.routeTotal)} · ${data.mobilityLabel} · '
                    'ca. ${data.routeTravelMinutes} Min.',
            onTap: data.itemCount == 0 ? onOpenList : onOpenRoute,
          ),
          const SizedBox(height: 10),
          DashboardTile(
            icon: Icons.local_offer_outlined,
            title: 'Neue Angebote',
            value: '${data.activeOffers}',
            subtitle: 'aktuell gültige Angebote',
            onTap: onOpenOffers,
          ),
          const SizedBox(height: 10),
          DashboardTile(
            icon: Icons.shopping_cart_outlined,
            title: 'Einkaufsliste',
            value: '${data.itemCount} Artikel',
            subtitle: 'Tippen zum Bearbeiten · Scanner verfügbar',
            onTap: onOpenList,
          ),
          const SizedBox(height: 10),
          DashboardTile(
            icon: Icons.calendar_month_outlined,
            title: 'Monatsersparnis',
            value: euro(data.monthlySavings),
            subtitle: data.monthlyPurchases == 0
                ? 'noch kein bestätigter Einkauf'
                : '${data.monthlyPurchases} bestätigte Einkäufe',
          ),
          const SizedBox(height: 10),
          DashboardTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budgetstatus',
            value: data.budgetConfigured ? euro(data.budgetRemaining) : 'Einrichten',
            subtitle: data.budgetConfigured ? 'nach aktuellem Einkaufsplan übrig' : 'Monats- und Lebensmittelbudget festlegen',
            onTap: onOpenBudget,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onOpenScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Produkt scannen'),
          ),
        ],
      );
}
