class Store {
  const Store({
    required this.name,
    required this.location,
    this.address = '',
    required this.distanceKm,
    required this.prices,
    this.isBigShop = false,
  });

  final String name;
  final String location;
  final String address;
  final double distanceKm;
  final Map<String, double> prices;
  final bool isBigShop;
}
