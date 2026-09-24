import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/catalog/product_family.dart';
import '../models/product.dart';
import 'quantity_normalizer.dart';

class OpenFoodFactsProductDiscovery {
  OpenFoodFactsProductDiscovery({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<Product?> discover(Product product) async {
    if ((product.ean ?? '').trim().isNotEmpty) return product;
    if (isGenericFamilyRequest(product.name)) return null;
    if (product.packageAmount == null || product.packageUnit == null) return null;

    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': product.name,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '20',
      'fields': 'code,product_name,brands,quantity',
    });
    final response = await _client.get(uri, headers: const {
      'Accept': 'application/json',
      'User-Agent': 'SparzamApp/1.0 (product discovery)',
    }).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw http.ClientException('Open Food Facts HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final products = json['products'] as List<dynamic>? ?? const [];
    for (final raw in products) {
      if (raw is! Map<String, dynamic>) continue;
      final code = (raw['code'] as String?)?.trim();
      final name = (raw['product_name'] as String?)?.trim();
      final quantity = (raw['quantity'] as String?)?.trim();
      if (code == null || code.isEmpty || name == null || name.isEmpty) continue;
      if (!_nameMatches(product, name)) continue;
      if (!_packageMatches(product, quantity)) continue;
      return product.copyWith(
        ean: code,
        brand: (raw['brands'] as String?)?.trim(),
      );
    }
    return null;
  }

  bool _nameMatches(Product wanted, String candidate) {
    final wantedText = normalizeProductText(wanted.name);
    final candidateText = normalizeProductText(candidate);
    if (wantedText.isEmpty || candidateText.isEmpty) return false;
    final wantedTokens = wantedText.split(' ').where((token) => token.length > 2);
    return wantedTokens.isNotEmpty &&
        wantedTokens.every((token) => candidateText.contains(token));
  }

  bool _packageMatches(Product wanted, String? quantity) {
    if (quantity == null || quantity.isEmpty) return false;
    final match = RegExp(r'(\\d+(?:[.,]\\d+)?)\\s*(kg|g|ml|l|stk|stück|stueck)',
            caseSensitive: false)
        .firstMatch(quantity);
    if (match == null) return false;
    final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final unit = match.group(2);
    if (amount == null || unit == null) return false;
    final wantedNormalized =
        normalizeQuantity(wanted.packageAmount, wanted.packageUnit);
    final foundNormalized = normalizeQuantity(amount, unit);
    if (wantedNormalized == null || foundNormalized == null) return false;
    return wantedNormalized.dimension == foundNormalized.dimension &&
        (wantedNormalized.amount - foundNormalized.amount).abs() < 0.000001;
  }

  void close() => _client.close();
}
