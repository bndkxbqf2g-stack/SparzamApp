import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<Product?> fetchProductByEan(
    String ean, {
    Product? existing,
  }) async {
    final code = ean.trim();
    if (code.isEmpty) return null;

    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$code.json',
      {
        'fields':
            'code,product_name,brands,quantity,product_quantity,product_quantity_unit,image_front_small_url,categories',
      },
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'SparzamApp/1.0 (product enrichment)',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if ((json['status'] as num?)?.toInt() != 1) return null;
      final raw = json['product'];
      if (raw is! Map<String, dynamic>) return null;

      final name = (raw['product_name'] as String?)?.trim();
      if ((name ?? '').isEmpty && existing == null) return null;

      final brand = (raw['brands'] as String?)?.trim();
      final quantity = _quantity(raw);
      final category = _firstCategory(raw['categories'] as String?);

      return Product(
        id: existing?.id ?? 'barcode_$code',
        name: (name?.isNotEmpty == true ? name! : existing!.name),
        unit: existing?.unit ??
            (quantity == null
                ? 'Artikel'
                : '${_formatAmount(quantity.amount)} ${quantity.unit}'),
        group: existing?.group ??
            (category?.isNotEmpty == true ? category! : 'custom'),
        aliases: existing?.aliases ?? const [],
        isFavorite: existing?.isFavorite ?? false,
        ean: code,
        brand: brand?.isNotEmpty == true ? brand : existing?.brand,
        packageAmount: quantity?.amount ?? existing?.packageAmount,
        packageUnit: quantity?.unit ?? existing?.packageUnit,
        imageUrl: (raw['image_front_small_url'] as String?)?.trim().isNotEmpty ==
                true
            ? (raw['image_front_small_url'] as String).trim()
            : existing?.imageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  _ParsedQuantity? _quantity(Map<String, dynamic> raw) {
    final amount = (raw['product_quantity'] as num?)?.toDouble();
    final unit = (raw['product_quantity_unit'] as String?)?.trim().toLowerCase();

    if (amount != null && amount > 0 && unit != null && unit.isNotEmpty) {
      return _ParsedQuantity(amount: amount, unit: _normalizeUnit(unit));
    }

    final quantity = (raw['quantity'] as String?)?.trim();
    if (quantity == null || quantity.isEmpty) return null;

    final normalized = quantity.replaceAll(',', '.').toLowerCase();
    final match = RegExp(
      r'([0-9]+(?:\.[0-9]+)?)\s*(kg|g|ml|cl|l|stück|stuck|stk|st)',
    ).firstMatch(normalized);
    if (match == null) return null;

    final parsed = double.tryParse(match.group(1)!);
    if (parsed == null || parsed <= 0) return null;

    var parsedUnit = _normalizeUnit(match.group(2)!);
    var parsedAmount = parsed;
    if (parsedUnit == 'cl') {
      parsedAmount *= 10;
      parsedUnit = 'ml';
    }

    return _ParsedQuantity(amount: parsedAmount, unit: parsedUnit);
  }

  String _normalizeUnit(String value) => switch (value) {
        'stück' || 'stuck' || 'stk' || 'st' => 'st',
        _ => value,
      };

  String? _firstCategory(String? categories) {
    if (categories == null || categories.trim().isEmpty) return null;
    return categories.split(',').first.trim().toLowerCase();
  }

  String _formatAmount(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);

  void close() => _client.close();
}

class _ParsedQuantity {
  const _ParsedQuantity({
    required this.amount,
    required this.unit,
  });

  final double amount;
  final String unit;
}
