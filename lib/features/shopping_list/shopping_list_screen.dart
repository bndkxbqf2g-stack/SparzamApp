import 'package:flutter/material.dart';

import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import '../../models/price_point.dart';
import '../../models/recent_purchase.dart';
import '../../models/replenishment_suggestion.dart';
import '../../services/shopping_list_store.dart';
import '../offers/offer_details_screen.dart';
import 'shopping_item_sorter.dart';
import 'shopping_group_card.dart';
import 'replenishment_card.dart';
import 'shopping_offer_hint.dart';
import 'shopping_suggestions.dart';
import 'shopping_list_header.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onChangeQuantity,
    required this.preferredProductByGroup,
    required this.recentPurchases,
    required this.onPurchased,
    required this.onClearPurchased,
    required this.shoppingListStore,
    required this.onOpenScanner,
    required this.offers,
    required this.priceHistory,
    required this.mobility,
    required this.catalogProducts,
    required this.marketPrices,
    required this.replenishmentSuggestions,
  });

  final List<ListItem> items;
  final ValueChanged<Product> onAdd;
  final void Function(String productId, int delta) onChangeQuantity;
  final Map<String, String> preferredProductByGroup;
  final List<RecentPurchase> recentPurchases;
  final Future<void> Function(Product product, int quantity) onPurchased;
  final void Function(Set<String> productIds) onClearPurchased;
  final ShoppingListStore shoppingListStore;
  final VoidCallback onOpenScanner;
  final List<Offer> offers;
  final List<PricePoint> priceHistory;
  final MobilitySettings mobility;
  final List<Product> catalogProducts;
  final List<MarketPrice> marketPrices;
  final List<ReplenishmentSuggestion> replenishmentSuggestions;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final controller = TextEditingController();
  final _inputFocusNode = FocusNode();
  final Set<String> checkedProductIds = <String>{};
  List<RecentPurchase> knownItems = <RecentPurchase>[];

  @override
  void initState() {
    super.initState();
    _loadKnownItems();
  }

  Future<void> _loadKnownItems() async {
    final items = await widget.shoppingListStore.loadKnownItems();
    if (!mounted) {
      return;
    }
    setState(() {
      knownItems = items;
    });
  }

  List<Product> get suggestions => buildSuggestions(
        query: controller.text,
        knownItems: knownItems,
        recentPurchases: widget.recentPurchases,
        preferredProductByGroup: widget.preferredProductByGroup,
        catalogProducts: widget.catalogProducts,
      );

  List<Product> get quickProducts => buildQuickProducts(
        widget.preferredProductByGroup,
        catalogProducts: widget.catalogProducts,
      );

  Map<String, List<ListItem>> get itemsByGroup {
    final grouped = <String, List<ListItem>>{};

    for (final item in widget.items) {
      grouped.putIfAbsent(item.product.group, () => []).add(item);
    }

    for (final entry in grouped.entries) {
      grouped[entry.key] = prioritizeOfferItems(
        entry.value,
        widget.offers,
        enabledStoreNames: widget.mobility.enabledStoreNames,
        marketPrices: widget.marketPrices,
      );
    }

    return grouped;
  }

  void _focusShoppingInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _inputFocusNode.requestFocus();
    });
  }

  void add(Product product) {
    widget.onAdd(product);
    controller.clear();
    setState(() {});
    _focusShoppingInput();
  }

  void addReplenishment(ReplenishmentSuggestion suggestion) {
    for (var index = 0; index < suggestion.suggestedQuantity; index++) {
      widget.onAdd(suggestion.product);
    }
    _focusShoppingInput();
  }

  void addRecentPurchase(RecentPurchase purchase) {
    final product = purchase.toProduct();
    widget.onAdd(product);

    final learnedQuantity = purchase.averageQuantity.round();
    if (learnedQuantity > 1) {
      for (var index = 1; index < learnedQuantity; index++) {
        widget.onAdd(product);
      }
    }

    controller.clear();
    setState(() {});
    _focusShoppingInput();
  }

  void addCustomProduct() {
    final name = controller.text.trim();
    if (name.isEmpty) {
      return;
    }

    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final product = Product(
      id: 'custom_${slug.isEmpty ? 'artikel' : slug}',
      name: name,
      unit: 'Artikel',
      group: 'custom',
    );

    widget.onAdd(product);
    controller.clear();
    setState(() {});
    _focusShoppingInput();
  }

  Future<void> toggleChecked(Product product) async {
    final wasChecked = checkedProductIds.contains(product.id);

    setState(() {
      if (wasChecked) {
        checkedProductIds.remove(product.id);
      } else {
        checkedProductIds.add(product.id);
      }
    });

    if (!wasChecked) {
      final item = widget.items.firstWhere(
        (item) => item.product.id == product.id,
      );
      await widget.onPurchased(product, item.quantity);
    }
  }

  void openOffer(ShoppingOfferHint hint) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfferDetailsScreen(
          offer: hint.offer,
          priceHistory: widget.priceHistory,
          items: widget.items,
          offers: widget.offers,
          mobility: widget.mobility,
          catalogProducts: widget.catalogProducts,
          marketPrices: widget.marketPrices,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = itemsByGroup;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              ShoppingListHeader(
                itemCount: widget.items.length,
                onClear: () {
                  widget.onClearPurchased(
                    widget.items.map((item) => item.product.id).toSet(),
                  );
                  setState(() => checkedProductIds.clear());
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                focusNode: _inputFocusNode,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    return;
                  }

                  if (suggestions.isNotEmpty) {
                    add(suggestions.first);
                  } else {
                    addCustomProduct();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Was möchtest du einkaufen?',
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  suffixIcon: controller.text.isEmpty
                      ? IconButton(
                          tooltip: 'Barcode scannen',
                          onPressed: widget.onOpenScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                        )
                      : IconButton(
                          onPressed: () {
                            controller.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (controller.text.trim().isEmpty &&
                  widget.replenishmentSuggestions.isNotEmpty) ...[
                const SizedBox(height: 14),
                ReplenishmentCard(
                  suggestions: widget.replenishmentSuggestions,
                  onAdd: addReplenishment,
                ),
              ],
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final product in suggestions)
                        ListTile(
                          onTap: () => add(product),
                          leading: CircleAvatar(
                            radius: 18,
                            child: Icon(
                              widget.preferredProductByGroup[product.group] ==
                                      product.id
                                  ? Icons.auto_awesome
                                  : Icons.add,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            widget.preferredProductByGroup[product.group] ==
                                    product.id
                                ? '${product.name} · deine Auswahl'
                                : product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            () {
                              final purchase = widget.recentPurchases
                                  .where((item) => item.id == product.id)
                                  .firstOrNull;
                              if (purchase == null) {
                                return product.unit;
                              }
                              final quantity = purchase.averageQuantity.round();
                              return quantity > 1
                                  ? '${product.unit} · meist ×$quantity'
                                  : product.unit;
                            }(),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ListTile(
                        onTap: addCustomProduct,
                        leading: const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.playlist_add),
                        ),
                        title: Text(
                          '„${controller.text.trim()}“ zur Liste hinzufügen',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Noch kein bekanntes Produkt – wird trotzdem gespeichert.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ] else if (controller.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    onTap: addCustomProduct,
                    leading: const CircleAvatar(
                      child: Icon(Icons.playlist_add),
                    ),
                    title: Text(
                      '„${controller.text.trim()}“ hinzufügen',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Noch nicht bekannt – trotzdem direkt auf die Einkaufsliste.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  ),
                ),
              ] else if (controller.text.trim().isEmpty &&
                  widget.recentPurchases.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Zuletzt gekauft',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.recentPurchases.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final purchase = widget.recentPurchases[index];
                      return ActionChip(
                        onPressed: () => addRecentPurchase(purchase),
                        avatar: const Icon(Icons.history, size: 18),
                        label: Text(
                          purchase.averageQuantity > 1.5
                              ? '${purchase.name} · meist ×${purchase.averageQuantity.round()}'
                              : purchase.name,
                        ),
                      );
                    },
                  ),
                ),
              ] else if (controller.text.trim().isEmpty &&
                  quickProducts.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Schnell hinzufügen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: quickProducts.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final product = quickProducts[index];
                      return ActionChip(
                        onPressed: () => add(product),
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(product.name),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (checkedProductIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FilledButton.icon(
                    onPressed: () {
                      final purchased = {...checkedProductIds};
                      widget.onClearPurchased(purchased);
                      setState(() => checkedProductIds.clear());
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      '${checkedProductIds.length} erledigte Artikel entfernen',
                    ),
                  ),
                ),
              if (widget.items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 52,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Deine Liste ist noch leer.',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tippe oben ein Produkt ein oder füge es über '
                          '„Schnell hinzufügen“ direkt hinzu.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final entry in grouped.entries) ...[
                  ShoppingGroupCard(
                    group: entry.key,
                    items: entry.value,
                    checkedProductIds: checkedProductIds,
                    offers: widget.offers,
                    enabledStoreNames: widget.mobility.enabledStoreNames,
                    marketPrices: widget.marketPrices,
                    onToggle: toggleChecked,
                    onChangeQuantity: widget.onChangeQuantity,
                    onOpenOffer: openOffer,
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
