import 'product_identity.dart';

export 'product_identity.dart';

String normalizeProductText(String value) => normalizeIdentityText(value);

String? broadProductFamily(String value) => identifyProduct(value).familyKey;

bool isGenericFamilyRequest(String value) => identifyProduct(value).isGeneric;
