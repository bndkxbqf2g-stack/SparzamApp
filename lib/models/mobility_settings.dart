enum MobilityMode { car, bike, walk }

/// Maximum number of markets the current project catalog can route through.
const maximumSupportedRouteStores = 7;

extension MobilityModeLabel on MobilityMode {
  String get label => switch (this) {
    MobilityMode.car => 'Auto',
    MobilityMode.bike => 'Fahrrad',
    MobilityMode.walk => 'Zu Fuß',
  };

  double get averageSpeedKmh => switch (this) {
    MobilityMode.car => 45,
    MobilityMode.bike => 18,
    MobilityMode.walk => 5,
  };
}

class MobilitySettings {
  const MobilitySettings({
    this.startAddress = '97225 Zellingen, Germany',
    this.euroPerKm = 0.22,
    this.fuelConsumptionLitersPer100Km = 5.0,
    this.fuelPricePerLiter = 1.70,
    this.timeValuePerHour = 0,
    this.mode = MobilityMode.car,
    this.maxStores = 3,
    this.minExtraStoreSavings = 0.50,
    this.additionalStoreCost = 0,
    this.enabledStoreNames = const <String>[],
  });

  final String startAddress;
  /// Legacy manual €/km value retained for old saved settings and callers.
  final double euroPerKm;
  final double fuelConsumptionLitersPer100Km;
  final double fuelPricePerLiter;

  /// Optional personal value of travel time used only for route comparison.
  /// Zero keeps the monetary recommendation unchanged while still displaying
  /// the estimated travel time.
  final double timeValuePerHour;
  final MobilityMode mode;
  final int maxStores;
  final double minExtraStoreSavings;
  /// Optional planning cost for every market after the first one.
  final double additionalStoreCost;
  final List<String> enabledStoreNames;

  double get effectiveEuroPerKm => mode == MobilityMode.car
      ? fuelConsumptionLitersPer100Km / 100 * fuelPricePerLiter
      : 0.0;

  bool isStoreEnabled(String storeName) =>
      enabledStoreNames.isEmpty || enabledStoreNames.contains(storeName);

  MobilitySettings copyWith({
    String? startAddress,
    double? euroPerKm,
    double? fuelConsumptionLitersPer100Km,
    double? fuelPricePerLiter,
    double? timeValuePerHour,
    MobilityMode? mode,
    int? maxStores,
    double? minExtraStoreSavings,
    double? additionalStoreCost,
    List<String>? enabledStoreNames,
  }) => MobilitySettings(
    startAddress: startAddress ?? this.startAddress,
    euroPerKm: euroPerKm ?? this.euroPerKm,
    fuelConsumptionLitersPer100Km:
        fuelConsumptionLitersPer100Km ?? this.fuelConsumptionLitersPer100Km,
    fuelPricePerLiter: fuelPricePerLiter ?? this.fuelPricePerLiter,
    timeValuePerHour: timeValuePerHour ?? this.timeValuePerHour,
    mode: mode ?? this.mode,
    maxStores: maxStores ?? this.maxStores,
    minExtraStoreSavings: minExtraStoreSavings ?? this.minExtraStoreSavings,
    additionalStoreCost: additionalStoreCost ?? this.additionalStoreCost,
    enabledStoreNames: enabledStoreNames ?? this.enabledStoreNames,
  );

  Map<String, dynamic> toJson() => {
    'startAddress': startAddress,
    'euroPerKm': euroPerKm,
    'fuelConsumptionLitersPer100Km': fuelConsumptionLitersPer100Km,
    'fuelPricePerLiter': fuelPricePerLiter,
    'timeValuePerHour': timeValuePerHour,
    'mode': mode.name,
    'maxStores': maxStores,
    'minExtraStoreSavings': minExtraStoreSavings,
    'additionalStoreCost': additionalStoreCost,
    'enabledStoreNames': enabledStoreNames,
  };

  factory MobilitySettings.fromJson(Map<String, dynamic> json) {
    final rawMode = json['mode'] as String?;
    final mode = MobilityMode.values.where((item) => item.name == rawMode);
    final stores =
        (json['enabledStoreNames'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];
    final euroPerKm = (json['euroPerKm'] as num?)?.toDouble();
    final fuelConsumption =
        (json['fuelConsumptionLitersPer100Km'] as num?)?.toDouble();
    final fuelPrice = (json['fuelPricePerLiter'] as num?)?.toDouble();
    final timeValuePerHour = (json['timeValuePerHour'] as num?)?.toDouble();
    final minSavings = (json['minExtraStoreSavings'] as num?)?.toDouble();
    final additionalStoreCost =
        (json['additionalStoreCost'] as num?)?.toDouble();

    return MobilitySettings(
      startAddress: (json['startAddress'] as String?)?.trim().isNotEmpty == true
          ? (json['startAddress'] as String).trim()
          : '97225 Zellingen, Germany',
      euroPerKm:
          euroPerKm != null &&
              euroPerKm.isFinite &&
              euroPerKm >= 0 &&
              euroPerKm <= 5
          ? euroPerKm
          : 0.22,
      fuelConsumptionLitersPer100Km:
          fuelConsumption != null &&
                  fuelConsumption.isFinite &&
                  fuelConsumption > 0 &&
                  fuelConsumption <= 30
              ? fuelConsumption
              : 5.0,
      fuelPricePerLiter:
          fuelPrice != null && fuelPrice.isFinite && fuelPrice > 0 && fuelPrice <= 10
              ? fuelPrice
              : 1.70,
      timeValuePerHour:
          timeValuePerHour != null &&
              timeValuePerHour.isFinite &&
              timeValuePerHour >= 0 &&
              timeValuePerHour <= 100
          ? timeValuePerHour
          : 0,
      mode: mode.isEmpty ? MobilityMode.car : mode.first,
      maxStores: ((json['maxStores'] as num?)?.toInt() ?? 3)
          .clamp(1, maximumSupportedRouteStores)
          .toInt(),
      minExtraStoreSavings:
          minSavings != null &&
              minSavings.isFinite &&
              minSavings >= 0 &&
              minSavings <= 50
          ? minSavings
          : 0.50,
      additionalStoreCost:
          additionalStoreCost != null &&
              additionalStoreCost.isFinite &&
              additionalStoreCost >= 0 &&
              additionalStoreCost <= 50
          ? additionalStoreCost
          : 0,
      enabledStoreNames: stores,
    );
  }
}
