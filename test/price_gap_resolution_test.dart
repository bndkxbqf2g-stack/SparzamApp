import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/price_gap_resolution.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('generic custom products are sent to concrete product selection', () {
    const product = Product(
      id: 'custom_milch',
      name: 'Milch',
      unit: 'Artikel',
      group: 'milch',
    );

    expect(shouldResolvePriceGapByProductSelection(product), isTrue);
  });

  test('unknown custom text remains eligible for manual price entry', () {
    const product = Product(
      id: 'custom_sonderwunsch',
      name: 'Sonderwunsch',
      unit: 'Artikel',
      group: 'custom',
    );

    expect(shouldResolvePriceGapByProductSelection(product), isFalse);
  });

  test('selected concrete products replace one gap and preserve quantity', () {
    const source = Product(
      id: 'custom_milch',
      name: 'Milch',
      unit: 'Artikel',
      group: 'milch',
    );
    const milk = Product(
      id: 'milk-15',
      name: 'Milch 1,5 %',
      unit: '1 l',
      group: 'milch',
    );
    final result = replacePriceGapItem(
      items: [ListItem(product: source, quantity: 2)],
      sourceProductId: source.id,
      selectedProducts: [milk],
    );

    expect(result, hasLength(1));
    expect(result!.single.product.id, milk.id);
    expect(result.single.quantity, 2);
    expect(result.single.note, 'Aus Auswahl aus „Milch“');
  });
}
