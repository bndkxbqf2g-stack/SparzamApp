import 'package:flutter/material.dart';

import '../../design/sparzam_theme.dart';
import 'dashboard_data.dart';

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

  String euro(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Center(
            child: Column(
              children: [
                Text('sparzam',
                    style: TextStyle(
                      color: SparzamTheme.deepGreen,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7,
                    )),
                Text('Mehr drin für euch.',
                    style: TextStyle(color: SparzamTheme.muted)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SavingsCard(
            amount: euro(data.todaySavings),
            itemCount: data.itemCount,
            onTap: data.itemCount == 0 ? onOpenList : onOpenRoute,
          ),
          const SizedBox(height: 26),
          _SectionHeader(title: 'Dein Einkauf', onTap: onOpenList),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewCard(
                  icon: Icons.shopping_basket_outlined,
                  title: 'Einkaufsliste',
                  value: '${data.itemCount} Artikel',
                  onTap: onOpenList,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewCard(
                  icon: Icons.route_outlined,
                  title: 'Beste Route',
                  value: data.routeTotal == 0
                      ? 'Berechnen'
                      : euro(data.routeTotal),
                  onTap: data.itemCount == 0 ? onOpenList : onOpenRoute,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _SectionHeader(title: 'Aktuelle Highlights', onTap: onOpenOffers),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFF1F7ED),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onOpenOffers,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_outlined,
                        color: SparzamTheme.deepGreen, size: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Angebote entdecken',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('${data.activeOffers} aktuell gültige Angebote'),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          if (data.replenishmentCount > 0) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.autorenew,
              label: 'Bald wieder nötig',
              detail: data.replenishmentPreview,
              onTap: onOpenList,
            ),
          ],
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Lebensmittelbudget',
            detail: data.budgetConfigured
                ? '${euro(data.budgetRemaining)} verfügbar'
                : 'Jetzt einrichten',
            onTap: onOpenBudget,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Produkt scannen'),
          ),
        ],
      );
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({
    required this.amount,
    required this.itemCount,
    required this.onTap,
  });

  final String amount;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        color: SparzamTheme.deepGreen,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dein Sparpotenzial',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17)),
                      const SizedBox(height: 4),
                      const Text('für deinen Einkauf',
                          style: TextStyle(color: Color(0xFFE1EDE1))),
                      const SizedBox(height: 14),
                      Text(amount,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800)),
                      Text(
                        itemCount == 0
                            ? 'Füge Artikel zur Einkaufsliste hinzu'
                            : 'auf $itemCount ausgewählten Produkten',
                        style: const TextStyle(color: Color(0xFFE1EDE1)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_circle_right,
                    color: Colors.white, size: 30),
              ],
            ),
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          TextButton(onPressed: onTap, child: const Text('Alle anzeigen')),
        ],
      );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: SparzamTheme.deepGreen),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: SparzamTheme.deepGreen),
          title: Text(label),
          subtitle: Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
