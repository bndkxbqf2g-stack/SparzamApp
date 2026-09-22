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
import 'shopping_group_card.dart';
import 'shopping_grouping.dart';
import 'replenishment_card.dart';
import 'shopping_offer_hint.dart';
import 'shopping_suggestions.dart';
import 'custom_shopping_product.dart';
import 'shopping_additions.dart';
import 'shopping_list_header.dart';
import 'shopping_input.dart';
import 'shopping_recent_choices.dart';
import 'shopping_search_results.dart';
import 'shopping_list_status.dart';

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

  Map<String, List<ListItem>> get itemsByGroup => groupShoppingItems(
        widget.items,
        widget.offers,
        enabledStoreNames: widget.mobility.enabledStoreNames,
        marketPrices: widget.marketPrices,
      );

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
    for (final product in productsForReplenishment(suggestion)) {
      widget.onAdd(product);
    }
    _focusShoppingInput();
  }

  void addRecentPurchase(RecentPurchase purchase) {
    for (final product in productsForRecentPurchase(purchase)) {
      widget.onAdd(product);
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

    widget.onAdd(customShoppingProduct(name));
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
              ShoppingInput(
                controller: controller,
                focusNode: _inputFocusNode,
                onChanged: () => setState(() {}),
                onSubmit: () {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;

                  if (suggestions.isNotEmpty) {
                    add(suggestions.first);
                  } else {
                    addCustomProduct();
                  }
                },
                onOpenScanner: widget.onOpenScanner,
              ),
              if (controller.text.trim().isEmpty &&
                  widget.replenishmentSuggestions.isNotEmpty) ...[
                const SizedBox(height: 14),
                ReplenishmentCard(
                  suggestions: widget.replenishmentSuggestions,
                  onAdd: addReplenishment,
                ),
              ],
              if (controller.text.trim().isNotEmpty)
                ShoppingSearchResults(
                  query: controller.text.trim(),
                  suggestions: suggestions,
                  preferredProductByGroup: widget.preferredProductByGroup,
                  recentPurchases: widget.recentPurchases,
                  onAdd: add,
                  onAddCustom: addCustomProduct,
                )
              else ...[
                ShoppingRecentChoices(
                  recentPurchases: widget.recentPurchases,
                  quickProducts: quickProducts,
                  onAddRecent: addRecentPurchase,
                  onAddProduct: add,
                ),
              ],
              const SizedBox(height: 22),
              CompletedItemsAction(
                count: checkedProductIds.length,
                onRemove: () {
                  final purchased = {...checkedProductIds};
                  widget.onClearPurchased(purchased);
                  setState(() => checkedProductIds.clear());
                },
              ),
              if (widget.items.isEmpty)
                const EmptyShoppingListCard()
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
