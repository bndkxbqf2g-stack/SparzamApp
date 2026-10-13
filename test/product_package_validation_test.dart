import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_editor_screen.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  Future<void> openEditor(WidgetTester tester, ValueChanged<Product> onSaved) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final product = await Navigator.of(context).push<Product>(
                MaterialPageRoute(builder: (_) => const ProductEditorScreen()),
              );
              if (product != null) onSaved(product);
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
  }

  testWidgets('Ungültige Packungsmenge verhindert Speichern', (tester) async {
    Product? saved;
    await openEditor(tester, (product) => saved = product);
    await tester.enterText(find.widgetWithText(TextFormField, 'Produktname'), 'Milch');
    await tester.enterText(find.widgetWithText(TextFormField, 'Packungsmenge'), '-2');
    await tester.ensureVisible(find.text('Produkt speichern'));
    await tester.tap(find.text('Produkt speichern'));
    await tester.pump();
    expect(find.text('Gültige Menge über 0 eingeben'), findsOneWidget);
    expect(saved, isNull);
  });

  testWidgets('Packungsmenge benötigt Einheit', (tester) async {
    Product? saved;
    await openEditor(tester, (product) => saved = product);
    await tester.enterText(find.widgetWithText(TextFormField, 'Produktname'), 'Milch');
    await tester.enterText(find.widgetWithText(TextFormField, 'Packungsmenge'), '500');
    await tester.ensureVisible(find.text('Produkt speichern'));
    await tester.tap(find.text('Produkt speichern'));
    await tester.pump();
    expect(find.text('Einheit eingeben'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'Mengeneinheit'), 'ml');
    await tester.ensureVisible(find.text('Produkt speichern'));
    await tester.tap(find.text('Produkt speichern'));
    await tester.pumpAndSettle();
    expect(saved?.packageAmount, 500);
    expect(saved?.packageUnit, 'ml');
  });

  testWidgets('EAN wird normalisiert und ungültige Zeichen werden abgelehnt', (
    tester,
  ) async {
    Product? saved;
    await openEditor(tester, (product) => saved = product);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Produktname'),
      'UPC-Produkt',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'EAN / Barcode'),
      '123-456789012',
    );
    await tester.ensureVisible(find.text('Produkt speichern'));
    await tester.tap(find.text('Produkt speichern'));
    await tester.pumpAndSettle();

    expect(saved?.ean, '0123456789012');

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Produktname'),
      'Ungültig',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'EAN / Barcode'),
      'ABC-123',
    );
    await tester.ensureVisible(find.text('Produkt speichern'));
    await tester.tap(find.text('Produkt speichern'));
    await tester.pump();
    expect(
      find.text('Nur Ziffern, Leerzeichen oder Bindestriche eingeben'),
      findsOneWidget,
    );
  });
}
