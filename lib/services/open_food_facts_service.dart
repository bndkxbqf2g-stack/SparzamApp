import 'open_food_facts_product_source.dart';

export 'open_food_facts_product_source.dart';

/// Backwards-compatible name for callers that used the original service.
///
/// New code should depend on [ProductDataSource] and inject an
/// [OpenFoodFactsProductSource].
typedef OpenFoodFactsService = OpenFoodFactsProductSource;
