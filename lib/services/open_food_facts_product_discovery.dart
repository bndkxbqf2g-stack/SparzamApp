import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/catalog/product_family.dart';
import '../models/product.dart';
import 'barcode_normalizer.dart';
import 'quantity_normalizer.dart';

class OpenFoodFactsProductDiscovery {
  OpenFoodFactsProductDiscovery({
    http.Client? client,
    this.enabled = true,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final bool enabled;

  Future<Product?> discover(Product product) async {
    if (!enabled) return null;
    if (product.ean != null && normalizeBarcode(product.ean!) != null) {
      return product;
    }
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
      final codeValue = raw['code'];
      final code = codeValue == null
          ? null
          : normalizeBarcode(codeValue.toString());
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
    final wantedTokens = wantedText
        .split(RegExp(r'\s+'))
        .where((token) => token.length >= 3 || RegExp(r'\d').hasMatch(token))
        .toSet();
    final candidateTokens = candidateText.split(RegExp(r'\s+')).toSet();
    if (wantedTokens.isEmpty ||
        !wantedTokens.every(candidateTokens.contains)) {
      return false;
    }

    // Token boundaries prevent a generic word such as "Milch" from matching
    // "Milchgetränk". Known identities add the stronger family/variant gate
    // so e.g. Milch 1,5 % cannot discover a 3,5-% EAN by shared wording.
    final wantedIdentity = identifyProduct(wanted.name);
    final candidateIdentity = identifyProduct(candidate);
    if (wantedIdentity.isKnown || candidateIdentity.isKnown) {
      return wantedIdentity.isKnown &&
          candidateIdentity.isKnown &&
          compatibleProductIdentity(wantedIdentity, candidateIdentity);
    }
    return true;
  }

  bool _packageMatches(Product wanted, String? quantity) {
    if (quantity == null || quantity.isEmpty) return false;
    final normalized = quantity.replaceAll(',', '.').toLowerCase();
    final multi = RegExp(
      r'(\d+(?:\.\d+)?)\s*[x×]\s*'
      r'(\d+(?:\.\d+)?)\s*(kg|g|ml|cl|l|stk|stück|stueck)\b',
    ).firstMatch(normalized);
    final match = multi ??
        RegExp(
          r'(\d+(?:\.\d+)?)\s*(kg|g|ml|cl|l|stk|stück|stueck)\b',
        ).firstMatch(normalized);
    if (match == null) return false;
    final multiplier = multi == null
        ? 1.0
        : double.tryParse(multi.group(1)!) ?? double.nan;
    final amountGroup = multi == null ? 1 : 2;
    final unitGroup = multi == null ? 2 : 3;
    final parsedAmount = double.tryParse(match.group(amountGroup)!);
    final amount = parsedAmount == null || !multiplier.isFinite
        ? null
        : parsedAmount * multiplier;
    final unit = match.group(unitGroup);
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
