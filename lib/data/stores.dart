import '../models/store.dart';

const stores = <Store>[
  Store(
    name: 'Lidl',
    branchId: 'lidl_zellingen',
    location: 'Zellingen',
    address: 'Am Güßgraben 2, 97225 Zellingen, Germany',
    distanceKm: 1.2,
    // Marktpreise werden ausschließlich aus belegten Beobachtungen,
    // aktuellen Angeboten oder ausdrücklich gepflegten Nutzerpreisen
    // bezogen. Die Marktstammdaten enthalten keine Beispielpreise.
    prices: {},
  ),
  Store(
    name: 'EDEKA',
    branchId: '023738',
    location: 'Zellingen',
    address: 'Würzburger Str. 100, 97225 Zellingen, Germany',
    distanceKm: 1.4,
    prices: {},
  ),
  Store(
    name: 'PENNY',
    branchId: '230061',
    location: 'Zellingen',
    address: 'Am Güßgraben 1, 97225 Zellingen, Germany',
    distanceKm: 1.1,
    prices: {},
  ),
  Store(
    name: 'ALDI Süd',
    branchId: 'B384',
    location: 'Zellingen',
    address: 'Würzburger Str. 74, 97225 Zellingen, Germany',
    distanceKm: 1.6,
    prices: {},
  ),
  Store(
    name: 'Netto',
    branchId: '4371',
    location: 'Thüngersheim',
    address: 'Am Straßacker 1, 97291 Thüngersheim, Germany',
    distanceKm: 5.8,
    prices: {},
  ),
  Store(
    name: 'Kaufland',
    branchId: 'DE5103',
    location: 'Würzburg · Nürnberger Straße',
    address: 'Nürnberger Str. 12, 97076 Würzburg, Germany',
    distanceKm: 25.0,
    isBigShop: true,
    prices: {},
  ),
];
