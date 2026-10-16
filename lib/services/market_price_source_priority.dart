import '../models/market_price.dart';

/// Stable precedence for equally priced, equally fresh market evidence.
///
/// Quality and freshness are evaluated before this order. The precedence only
/// resolves a tie and keeps stronger first-party evidence visible when two
/// sources claim the same amount.
int marketPriceSourcePriority(MarketPriceSource source) => switch (source) {
  MarketPriceSource.manual => 0,
  MarketPriceSource.receipt => 1,
  MarketPriceSource.prospect => 2,
  MarketPriceSource.openPrices => 3,
};
