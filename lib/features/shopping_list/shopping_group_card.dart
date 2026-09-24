import 'package:flutter/material.dart';

import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import 'shopping_price_badge.dart';

class ShoppingGroupCard extends StatelessWidget {
  const ShoppingGroupCard({
    super.key,
    required this.group,
    required this.items,
    required this.checkedProductIds,
    required this.offers,
    required this.enabledStoreNames,
    required this.marketPrices,
    required this.priceObservations,
    required this.onToggle,
    required this.onChangeQuantity,
    required this.onEditDetails,
    this.tileView = false,
    required this.onOpenOffer,
  });

  final String group;
  final List<ListItem> items;
  final Set<String> checkedProductIds;
  final List<Offer> offers;
  final List<String> enabledStoreNames;
  final List<MarketPrice> marketPrices;
  final List<MarketPrice> priceObservations;
  final ValueChanged<Product> onToggle;
  final void Function(String productId, int delta) onChangeQuantity;
  final ValueChanged<ListItem> onEditDetails;
  final bool tileView;
  final ValueChanged<Offer> onOpenOffer;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              shoppingGroupLabel(group),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (tileView)
            LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: constraints.maxWidth >= 650 ? 3 : 2,
                childAspectRatio: 1.15,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final item in items)
                    _ShoppingItemCard(
                      item: item,
                      offers: offers,
                      priceObservations: priceObservations,
                      enabledStoreNames: enabledStoreNames,
                      onOpenOffer: onOpenOffer,
                      checked: checkedProductIds.contains(item.product.id),
                      onToggle: onToggle,
                      onChangeQuantity: onChangeQuantity,
                      onEditDetails: onEditDetails,
                    ),
                ],
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    _ShoppingItemTile(
                    item: items[index],
                    checked: checkedProductIds.contains(
                      items[index].product.id,
                    ),
                    offers: offers,
                    enabledStoreNames: enabledStoreNames,
                    marketPrices: marketPrices,
                    priceObservations: priceObservations,
                    onToggle: onToggle,
                    onChangeQuantity: onChangeQuantity,
                    onEditDetails: onEditDetails,
                    onOpenOffer: onOpenOffer,
                    ),
                    if (index < items.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      );
}

class _ShoppingItemCard extends StatelessWidget {
  const _ShoppingItemCard({
    required this.item,
    required this.checked,
    required this.offers,
    required this.priceObservations,
    required this.enabledStoreNames,
    required this.onOpenOffer,
    required this.onToggle,
    required this.onChangeQuantity,
    required this.onEditDetails,
  });

  final ListItem item;
  final bool checked;
  final List<Offer> offers;
  final List<MarketPrice> priceObservations;
  final List<String> enabledStoreNames;
  final ValueChanged<Offer> onOpenOffer;
  final ValueChanged<Product> onToggle;
  final void Function(String productId, int delta) onChangeQuantity;
  final ValueChanged<ListItem> onEditDetails;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onToggle(item.product),
          onLongPress: () => onEditDetails(item),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      checked ? Icons.check_circle : Icons.circle_outlined,
                      color: checked ? Colors.green.shade600 : Colors.black38,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration:
                              checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.note.isNotEmpty)
                  Text(
                    item.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ShoppingPriceBadge(
                  item: item,
                  prices: priceObservations,
                  offers: offers,
                  enabledStores: enabledStoreNames,
                  onOpenOffer: onOpenOffer,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: checked
                          ? null
                          : () => onChangeQuantity(item.product.id, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: checked
                          ? null
                          : () => onChangeQuantity(item.product.id, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _ShoppingItemTile extends StatelessWidget {
  const _ShoppingItemTile({
    required this.item,
    required this.checked,
    required this.offers,
    required this.enabledStoreNames,
    required this.marketPrices,
    required this.priceObservations,
    required this.onToggle,
    required this.onChangeQuantity,
    required this.onEditDetails,
    required this.onOpenOffer,
  });

  final ListItem item;
  final bool checked;
  final List<Offer> offers;
  final List<String> enabledStoreNames;
  final List<MarketPrice> marketPrices;
  final List<MarketPrice> priceObservations;
  final ValueChanged<Product> onToggle;
  final void Function(String productId, int delta) onChangeQuantity;
  final ValueChanged<ListItem> onEditDetails;
  final ValueChanged<Offer> onOpenOffer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onToggle(item.product),
      onLongPress: () => onEditDetails(item),
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? Colors.green.shade600 : Colors.transparent,
          border: Border.all(
            color: checked ? Colors.green.shade600 : Colors.black26,
            width: 2,
          ),
        ),
        child: checked
            ? const Icon(Icons.check, size: 17, color: Colors.white)
            : null,
      ),
      title: Text(
        item.product.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: checked ? TextDecoration.lineThrough : null,
          color: checked ? Colors.black45 : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.quantity > 1
                ? '${item.product.unit} · ×${item.quantity}'
                : item.product.unit,
          ),
          if (item.note.isNotEmpty)
            Text(
              item.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.blueGrey.shade700),
            ),
          ShoppingPriceBadge(
            item: item,
            prices: priceObservations,
            offers: offers,
            enabledStores: enabledStoreNames,
            onOpenOffer: onOpenOffer,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Menge verringern',
            onPressed: checked
                ? null
                : () => onChangeQuantity(item.product.id, -1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            item.quantity.toString(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            tooltip: 'Menge erhöhen',
            onPressed: checked
                ? null
                : () => onChangeQuantity(item.product.id, 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

String shoppingGroupLabel(String group) => switch (group) {
      'butter' || 'milch' => 'Milch & Käse',
      'obst' => 'Obst & Gemüse',
      'fleisch' => 'Fleisch',
      'nudeln' => 'Nudeln & Beilagen',
      _ => 'Weitere Produkte',
    };
