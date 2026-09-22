class Store {
  const Store({
    required this.name,
    required this.location,
    required this.distanceKm,
    required this.prices,
    this.isBigShop = false,
  });

  final String name;
  final String location;
  final double distanceKm;
  final Map<String, double> prices;
  final bool isBigShop;
}
