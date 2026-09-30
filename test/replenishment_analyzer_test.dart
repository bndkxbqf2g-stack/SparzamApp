import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/replenishment_analyzer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/purchase_record.dart';
import 'package:sparzamapp/models/receipt_observation.dart';

void main() {
  const milk = Product(id: 'milk', name: 'Milch', unit: '1 l', group: 'milch');
  const coffee = Product(
    id: 'coffee',
    name: 'Kaffee',
    unit: '500 g',
    group: 'kaffee',
  );

  PurchaseRecord purchase(
    DateTime date,
    String productId,
    String name,
    int quantity,
  ) => PurchaseRecord(
    id: date.microsecondsSinceEpoch.toString(),
    createdAt: date,
    storeNames: const ['Lidl'],
    items: [PurchaseLine(productId: productId, name: name, quantity: quantity)],
    basket: 1,
    travel: 0,
    total: 1,
    baselineTotal: 1,
  );

  test('lernt Wiederkaufrhythmus und durchschnittliche Menge', () {
    final suggestions = buildReplenishmentSuggestions(
      history: [
        purchase(DateTime(2026, 9, 1), 'milk', 'Milch', 2),
        purchase(DateTime(2026, 9, 8), 'milk', 'Milch', 3),
        purchase(DateTime(2026, 9, 15), 'milk', 'Milch', 1),
      ],
      catalogProducts: const [milk],
      currentListProductIds: const {},
      now: DateTime(2026, 9, 20),
    );

    expect(suggestions, hasLength(1));
    final suggestion = suggestions.single;
    expect(suggestion.intervalDays, 7);
    expect(suggestion.daysUntilDue, 2);
    expect(suggestion.averageQuantity, 2);
    expect(suggestion.suggestedQuantity, 2);
    expect(suggestion.timingLabel, 'voraussichtlich in 2 Tagen');
  });

  test('Median schützt Rhythmus vor einzelnem langen Ausreißer', () {
    final suggestions = buildReplenishmentSuggestions(
      history: [
        purchase(DateTime(2026, 8, 1), 'coffee', 'Kaffee', 1),
        purchase(DateTime(2026, 8, 8), 'coffee', 'Kaffee', 1),
        purchase(DateTime(2026, 8, 15), 'coffee', 'Kaffee', 1),
        purchase(DateTime(2026, 9, 14), 'coffee', 'Kaffee', 1),
      ],
      catalogProducts: const [coffee],
      currentListProductIds: const {},
      now: DateTime(2026, 9, 20),
    );

    expect(suggestions.single.intervalDays, 7);
    expect(suggestions.single.daysUntilDue, 1);
  });

  test('Produkt auf aktueller Einkaufsliste wird nicht vorgeschlagen', () {
    final suggestions = buildReplenishmentSuggestions(
      history: [
        purchase(DateTime(2026, 9, 1), 'milk', 'Milch', 1),
        purchase(DateTime(2026, 9, 8), 'milk', 'Milch', 1),
      ],
      catalogProducts: const [milk],
      currentListProductIds: const {'milk'},
      now: DateTime(2026, 9, 15),
    );

    expect(suggestions, isEmpty);
  });

  test('ein einzelner Kauf reicht nicht für eine Prognose', () {
    final suggestions = buildReplenishmentSuggestions(
      history: [purchase(DateTime(2026, 9, 1), 'milk', 'Milch', 1)],
      catalogProducts: const [milk],
      currentListProductIds: const {},
      now: DateTime(2026, 9, 20),
    );

    expect(suggestions, isEmpty);
  });

  test('mehrere Käufe am selben Tag zählen als eine Beobachtung', () {
    final suggestions = buildReplenishmentSuggestions(
      history: [
        purchase(DateTime(2026, 9, 1, 9), 'milk', 'Milch', 1),
        purchase(DateTime(2026, 9, 1, 18), 'milk', 'Milch', 2),
        purchase(DateTime(2026, 9, 8), 'milk', 'Milch', 1),
      ],
      catalogProducts: const [milk],
      currentListProductIds: const {},
      now: DateTime(2026, 9, 15),
    );

    expect(suggestions, hasLength(1));
    expect(suggestions.single.purchaseCount, 2);
    expect(suggestions.single.intervalDays, 7);
    expect(suggestions.single.averageQuantity, 2);
  });

  test('überfällige Produkte stehen vor bald fälligen', () {
    final suggestions = buildReplenishmentSuggestions(
      history: [
        purchase(DateTime(2026, 9, 1), 'milk', 'Milch', 1),
        purchase(DateTime(2026, 9, 6), 'milk', 'Milch', 1),
        purchase(DateTime(2026, 9, 10), 'coffee', 'Kaffee', 1),
        purchase(DateTime(2026, 9, 17), 'coffee', 'Kaffee', 1),
      ],
      catalogProducts: const [milk, coffee],
      currentListProductIds: const {},
      now: DateTime(2026, 9, 22),
    );

    expect(suggestions.map((item) => item.product.id), ['milk', 'coffee']);
    expect(suggestions.first.daysUntilDue, lessThan(0));
    expect(suggestions.last.daysUntilDue, 2);
  });

  test(
    'bestätigte Bonbeobachtungen lernen ebenfalls den Wiederkaufrhythmus',
    () {
      final suggestions = buildReplenishmentSuggestions(
        history: const [],
        receiptObservations: [
          receipt('r1', DateTime(2026, 9, 1), quantity: 2),
          receipt('r2', DateTime(2026, 9, 8), quantity: 1),
        ],
        catalogProducts: const [milk],
        currentListProductIds: const {},
        now: DateTime(2026, 9, 15),
      );

      expect(suggestions, hasLength(1));
      expect(suggestions.single.daysUntilDue, 0);
      expect(suggestions.single.averageQuantity, 1.5);
      expect(suggestions.single.evidenceLabel, 'bestätigte Bons');
    },
  );

  test(
    'unbestätigte oder gewichtete Bons erzeugen keinen Nachkaufvorschlag',
    () {
      final suggestions = buildReplenishmentSuggestions(
        history: const [],
        receiptObservations: [
          receipt(
            'u1',
            DateTime(2026, 9, 1),
            quantity: 1,
            identityConfirmed: false,
          ),
          receipt(
            'u2',
            DateTime(2026, 9, 8),
            quantity: 1,
            identityConfirmed: false,
          ),
          receipt(
            'kg1',
            DateTime(2026, 9, 1),
            quantity: 1,
            quantityUnit: 'kg',
            identityConfirmed: true,
          ),
          receipt(
            'kg2',
            DateTime(2026, 9, 8),
            quantity: 1,
            quantityUnit: 'kg',
            identityConfirmed: true,
          ),
        ],
        catalogProducts: const [milk],
        currentListProductIds: const {},
        now: DateTime(2026, 9, 15),
      );

      expect(suggestions, isEmpty);
    },
  );

  test(
    'gleicher Einkaufstag aus Bon und Kaufhistorie wird nicht doppelt gezählt',
    () {
      final suggestions = buildReplenishmentSuggestions(
        history: [
          purchase(DateTime(2026, 9, 1), 'milk', 'Milch', 2),
          purchase(DateTime(2026, 9, 8), 'milk', 'Milch', 1),
        ],
        receiptObservations: [
          receipt('duplicate-1', DateTime(2026, 9, 1), quantity: 2),
          receipt('duplicate-2', DateTime(2026, 9, 8), quantity: 1),
        ],
        catalogProducts: const [milk],
        currentListProductIds: const {},
        now: DateTime(2026, 9, 15),
      );

      expect(suggestions, hasLength(1));
      expect(suggestions.single.purchaseCount, 2);
      expect(suggestions.single.averageQuantity, 1.5);
      expect(
        suggestions.single.evidenceLabel,
        'Kaufhistorie + bestätigte Bons',
      );
    },
  );
}

ReceiptObservation receipt(
  String id,
  DateTime observedAt, {
  required double quantity,
  String quantityUnit = 'Stück',
  bool identityConfirmed = true,
}) => ReceiptObservation(
  id: id,
  receiptFingerprint: id,
  rowLine: 1,
  rawLabel: 'Milch',
  familyKey: 'milch',
  storeName: 'Lidl',
  observedAt: observedAt,
  totalPrice: quantity,
  quantity: quantity,
  quantityUnit: quantityUnit,
  unitPrice: null,
  discounted: false,
  productId: identityConfirmed ? 'milk' : null,
  identityConfirmed: identityConfirmed,
);
