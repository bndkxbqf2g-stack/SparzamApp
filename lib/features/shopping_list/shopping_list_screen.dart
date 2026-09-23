import 'package:flutter/material.dart';

import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/named_shopping_list.dart';
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
import 'aisle_order_dialog.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({
    super.key,
    required this.items,
    this.shoppingLists = const <NamedShoppingList>[],
    this.activeShoppingListId = 'default',
    this.onSelectShoppingList,
    this.onCreateShoppingList,
    required this.onAdd,
    required this.onChangeQuantity,
    this.onUpdateItemNote,
    this.onUpdateItemChecked,
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
  final List<NamedShoppingList> shoppingLists;
  final String activeShoppingListId;
  final Future<void> Function(String id)? onSelectShoppingList;
  final Future<void> Function(String name)? onCreateShoppingList;
  final ValueChanged<Product> onAdd;
  final void Function(String productId, int delta) onChangeQuantity;
  final void Function(String productId, String note)? onUpdateItemNote;
  final void Function(String productId, bool checked)? onUpdateItemChecked;
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
  final Set<String> purchasingProductIds = <String>{};
  List<RecentPurchase> knownItems = <RecentPurchase>[];
  List<String> aisleOrder = <String>[];
  bool tileView = false;

  @override
  void initState() {
    super.initState();
    _loadKnownItems();
    _loadAisleOrder();
    _loadViewMode();
  }

  Future<void> _loadAisleOrder() async {
    final order = await widget.shoppingListStore.loadAisleOrder();
    if (mounted) setState(() => aisleOrder = order);
  }

  Future<void> _loadViewMode() async {
    final enabled = await widget.shoppingListStore.loadTileView();
    if (mounted) setState(() => tileView = enabled);
  }

  Future<void> toggleViewMode() async {
    final next = !tileView;
    setState(() => tileView = next);
    await widget.shoppingListStore.saveTileView(next);
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

  Set<String> get checkedProductIds => widget.items
      .where((item) => item.checked)
      .map((item) => item.product.id)
      .toSet();

  List<MapEntry<String, List<ListItem>>> orderedGroups(
    Map<String, List<ListItem>> grouped,
  ) {
    final entries = grouped.entries.toList();
    entries.sort((a, b) {
      final aIndex = aisleOrder.indexOf(a.key);
      final bIndex = aisleOrder.indexOf(b.key);
      if (aIndex < 0 && bIndex < 0) return 0;
      if (aIndex < 0) return 1;
      if (bIndex < 0) return -1;
      return aIndex.compareTo(bIndex);
    });
    return entries;
  }

  Future<void> editAisleOrder() async {
    final groups = itemsByGroup.keys.toList();
    if (groups.length < 2) return;
    final result = await showAisleOrderDialog(
      context,
      groups: groups,
      currentOrder: aisleOrder,
    );
    if (result == null) return;
    await widget.shoppingListStore.saveAisleOrder(result);
    if (mounted) setState(() => aisleOrder = result);
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

  Future<void> editItemDetails(ListItem item) async {
    final noteController = TextEditingController(text: item.note);
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.product.name),
        content: TextField(
          controller: noteController,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notiz / genaue Beschreibung',
            hintText: 'Zum Beispiel: Vollkorn, 500 g',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note != null) widget.onUpdateItemNote?.call(item.product.id, note);
  }

  void setItemChecked(ListItem item, bool checked) {
    final callback = widget.onUpdateItemChecked;
    if (callback != null) {
      callback(item.product.id, checked);
      return;
    }
    setState(() => item.checked = checked);
  }

  Future<void> toggleChecked(Product product) async {
    if (purchasingProductIds.contains(product.id)) return;
    final item = widget.items.firstWhere(
      (item) => item.product.id == product.id,
    );
    final wasChecked = item.checked;
    setItemChecked(item, !wasChecked);

    if (!wasChecked) {
      purchasingProductIds.add(product.id);
      try {
        await widget.onPurchased(product, item.quantity);
      } catch (_) {
        if (mounted) {
          setItemChecked(item, false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kauf konnte nicht gespeichert werden.')),
          );
        }
      } finally {
        purchasingProductIds.remove(product.id);
      }
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
                lists: widget.shoppingLists,
                activeListId: widget.activeShoppingListId,
                onSelectList: widget.onSelectShoppingList,
                onCreateList: widget.onCreateShoppingList,
                onEditAisleOrder: editAisleOrder,
                tileView: tileView,
                onToggleView: toggleViewMode,
                onClear: () {
                  if (purchasingProductIds.isNotEmpty) return;
                  widget.onClearPurchased(
                    widget.items.map((item) => item.product.id).toSet(),
                  );
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
                  if (purchasingProductIds.isNotEmpty) return;
                  final purchased = {...checkedProductIds};
                  widget.onClearPurchased(purchased);
                },
              ),
              if (widget.items.isEmpty)
                const EmptyShoppingListCard()
              else
                for (final entry in orderedGroups(grouped)) ...[
                  ShoppingGroupCard(
                    group: entry.key,
                    items: entry.value,
                    checkedProductIds: checkedProductIds,
                    offers: widget.offers,
                    enabledStoreNames: widget.mobility.enabledStoreNames,
                    marketPrices: widget.marketPrices,
                    onToggle: toggleChecked,
                    onChangeQuantity: widget.onChangeQuantity,
                    onEditDetails: editItemDetails,
                    tileView: tileView,
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
