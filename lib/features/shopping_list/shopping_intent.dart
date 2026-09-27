import '../../models/product.dart';
import '../catalog/product_identity.dart';

/// A custom family request is a question that still needs a concrete article.
/// It must not silently turn into an estimated route price.
bool isGenericShoppingIntent(Product product) =>
    product.id.startsWith('custom_') && identifyProduct(product.name).isGeneric;
