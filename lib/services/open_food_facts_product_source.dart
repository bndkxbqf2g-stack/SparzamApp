import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'barcode_normalizer.dart';
import 'product_data_cache.dart';
import 'product_data_source.dart';

/// Open Food Facts product enrichment through its documented read API.
///
/// The adapter only supplies product metadata. It never turns an external
/// match into a confirmed product identity or a route price.
class OpenFoodFactsProductSource implements ProductDataSource {
  OpenFoodFactsProductSource({
    http.Client? client,
    this.cache,
    this.enabled = true,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final ProductDataCache? cache;

  @override
  final bool enabled;

  @override
  Future<Product?> fetchProductByEan(
    String ean, {
    Product? existing,
  }) async {
    if (!enabled) return null;
    final code = normalizeBarcode(ean);
    if (code == null) return null;

    final cached = await _loadCached(code, existing);
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$code.json',
      {
        'fields':
            'code,product_name,brands,quantity,product_quantity,'
            'product_quantity_unit,image_front_small_url,categories',
      },
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              // Open Food Facts recommends identifying API clients with a
              // stable user agent so public access remains well behaved.
              'User-Agent': 'SparzamApp/1.0 (product enrichment)',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return cached;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if ((json['status'] as num?)?.toInt() != 1) return cached;
      final raw = json['product'];
      if (raw is! Map<String, dynamic>) return cached;
      for (final returnedCode in [json['code'], raw['code']]) {
        if (returnedCode != null &&
            normalizeBarcode(returnedCode.toString()) != code) {
          return cached;
        }
      }

      final name = (raw['product_name'] as String?)?.trim();
      if ((name ?? '').isEmpty && existing == null) return cached;

      final enriched = _productFromApi(
        raw,
        code: code,
        existing: existing,
        name: name,
      );
      if (enriched == null) return cached;

      // Persist only the metadata response. Local favorites, aliases and
      // custom identity are restored by _merge for the current caller.
      await cache?.save(enriched);
      return _merge(enriched, existing, code);
    } catch (_) {
      // Offline/network failures are expected for an optional source. A
      // validated local response remains useful, but never becomes a price.
      return cached;
    }
  }

  Product? _productFromApi(
    Map<String, dynamic> raw, {
    required String code,
    required Product? existing,
    required String? name,
  }) {
    final brand = (raw['brands'] as String?)?.trim();
    final quantity = _quantity(raw);
    final category = _firstCategory(raw['categories'] as String?);
    final resolvedName = name?.isNotEmpty == true
        ? name!
        : existing?.name;
    if (resolvedName == null || resolvedName.trim().isEmpty) return null;

    final image = (raw['image_front_small_url'] as String?)?.trim();
    return Product(
      id: 'barcode_$code',
      name: resolvedName,
      unit: quantity == null
          ? (existing?.unit ?? 'Artikel')
          : '${_formatAmount(quantity.amount)} ${quantity.unit}',
      group: category?.isNotEmpty == true
          ? category!
          : (existing?.group ?? 'custom'),
      aliases: const <String>[],
      ean: code,
      brand: brand?.isNotEmpty == true ? brand : null,
      packageAmount: quantity?.amount,
      packageUnit: quantity?.unit,
      imageUrl: image?.isNotEmpty == true ? image : null,
    );
  }

  Future<Product?> _loadCached(String code, Product? existing) async {
    try {
      final value = await cache?.load(code);
      return value == null ? null : _merge(value, existing, code);
    } catch (_) {
      return null;
    }
  }

  Product _merge(Product enriched, Product? existing, String code) {
    final existingUnit = existing?.unit.trim();
    final keepExistingUnit =
        existingUnit != null &&
        existingUnit.isNotEmpty &&
        existingUnit.toLowerCase() != 'artikel';

    return Product(
      id: existing?.id ?? enriched.id,
      name: enriched.name.trim().isNotEmpty
          ? enriched.name
          : (existing?.name ?? enriched.name),
      // A generic scanner placeholder must not hide a verified package size.
      // Explicit user-entered units remain authoritative.
      unit: keepExistingUnit ? existing!.unit : enriched.unit,
      group: existing?.group ?? enriched.group,
      aliases: existing?.aliases ?? enriched.aliases,
      isFavorite: existing?.isFavorite ?? enriched.isFavorite,
      isStaple: existing?.isStaple ?? enriched.isStaple,
      ean: code,
      brand: enriched.brand ?? existing?.brand,
      packageAmount: enriched.packageAmount ?? existing?.packageAmount,
      packageUnit: enriched.packageUnit ?? existing?.packageUnit,
      imageUrl: enriched.imageUrl ?? existing?.imageUrl,
    );
  }

  _ParsedQuantity? _quantity(Map<String, dynamic> raw) {
    final amount = (raw['product_quantity'] as num?)?.toDouble();
    final unit = (raw['product_quantity_unit'] as String?)?.trim().toLowerCase();

    if (amount != null &&
        amount.isFinite &&
        amount > 0 &&
        unit != null &&
        unit.isNotEmpty) {
      var normalizedAmount = amount;
      final normalizedUnit = _normalizeUnit(unit);
      if (normalizedUnit == null) return null;
      if (normalizedUnit == 'cl') {
        normalizedAmount *= 10;
        if (!normalizedAmount.isFinite) return null;
        return _ParsedQuantity(amount: normalizedAmount, unit: 'ml');
      }
      return _ParsedQuantity(amount: normalizedAmount, unit: normalizedUnit);
    }

    final quantity = (raw['quantity'] as String?)?.trim();
    if (quantity == null || quantity.isEmpty) return null;

    final normalized = quantity.replaceAll(',', '.').toLowerCase();
    final multi = RegExp(
      r'([0-9]+)\s*[x×]\s*([0-9]+(?:\.[0-9]+)?)\s*'
      r'(kg|g|ml|cl|l|stück|stuck|stk|st)',
    ).firstMatch(normalized);
    final match = multi ??
        RegExp(
          r'([0-9]+(?:\.[0-9]+)?)\s*'
          r'(kg|g|ml|cl|l|stück|stuck|stk|st)',
        ).firstMatch(normalized);
    if (match == null) return null;

    final multiplier = multi == null
        ? 1.0
        : (double.tryParse(multi.group(1)!) ?? 1);
    final amountGroup = multi == null ? 1 : 2;
    final unitGroup = multi == null ? 2 : 3;
    final parsed = double.tryParse(match.group(amountGroup)!);
    if (parsed == null ||
        !parsed.isFinite ||
        parsed <= 0 ||
        !multiplier.isFinite ||
        multiplier <= 0) {
      return null;
    }

    final parsedUnitValue = _normalizeUnit(match.group(unitGroup)!);
    if (parsedUnitValue == null) return null;
    var parsedUnit = parsedUnitValue;
    var parsedAmount = parsed * multiplier;
    if (parsedUnit == 'cl') {
      parsedAmount *= 10;
      parsedUnit = 'ml';
    }
    if (!parsedAmount.isFinite) return null;

    return _ParsedQuantity(amount: parsedAmount, unit: parsedUnit);
  }

  String? _normalizeUnit(String value) => switch (value.trim().toLowerCase()) {
        'g' || 'gramm' || 'gram' => 'g',
        'kg' || 'kilogramm' || 'kilogram' => 'kg',
        'ml' || 'milliliter' || 'millilitre' => 'ml',
        'cl' || 'centiliter' || 'centilitre' => 'cl',
        'l' || 'liter' || 'litre' => 'l',
        'stück' || 'stuck' || 'stk' || 'st' => 'st',
        _ => null,
      };

  String? _firstCategory(String? categories) {
    if (categories == null || categories.trim().isEmpty) return null;
    return categories.split(',').first.trim().toLowerCase();
  }

  String _formatAmount(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);

  @override
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
