enum MobilityMode { car, bike, walk }

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
    this.mode = MobilityMode.car,
    this.maxStores = 3,
    this.minExtraStoreSavings = 0.50,
    this.enabledStoreNames = const <String>[],
  });

  final String startAddress;
  final double euroPerKm;
  final MobilityMode mode;
  final int maxStores;
  final double minExtraStoreSavings;
  final List<String> enabledStoreNames;

  double get effectiveEuroPerKm =>
      mode == MobilityMode.car ? euroPerKm : 0.0;

  bool isStoreEnabled(String storeName) =>
      enabledStoreNames.isEmpty || enabledStoreNames.contains(storeName);

  MobilitySettings copyWith({
    String? startAddress,
    double? euroPerKm,
    MobilityMode? mode,
    int? maxStores,
    double? minExtraStoreSavings,
    List<String>? enabledStoreNames,
  }) =>
      MobilitySettings(
        startAddress: startAddress ?? this.startAddress,
        euroPerKm: euroPerKm ?? this.euroPerKm,
        mode: mode ?? this.mode,
        maxStores: maxStores ?? this.maxStores,
        minExtraStoreSavings:
            minExtraStoreSavings ?? this.minExtraStoreSavings,
        enabledStoreNames: enabledStoreNames ?? this.enabledStoreNames,
      );

  Map<String, dynamic> toJson() => {
        'startAddress': startAddress,
        'euroPerKm': euroPerKm,
        'mode': mode.name,
        'maxStores': maxStores,
        'minExtraStoreSavings': minExtraStoreSavings,
        'enabledStoreNames': enabledStoreNames,
      };

  factory MobilitySettings.fromJson(Map<String, dynamic> json) {
    final rawMode = json['mode'] as String?;
    final mode = MobilityMode.values.where((item) => item.name == rawMode);
    final stores = (json['enabledStoreNames'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];
    final euroPerKm = (json['euroPerKm'] as num?)?.toDouble();
    final minSavings = (json['minExtraStoreSavings'] as num?)?.toDouble();

    return MobilitySettings(
      startAddress:
          (json['startAddress'] as String?)?.trim().isNotEmpty == true
              ? (json['startAddress'] as String).trim()
              : '97225 Zellingen, Germany',
      euroPerKm: euroPerKm != null && euroPerKm.isFinite &&
              euroPerKm >= 0 && euroPerKm <= 5
          ? euroPerKm
          : 0.22,
      mode: mode.isEmpty ? MobilityMode.car : mode.first,
      maxStores:
          ((json['maxStores'] as num?)?.toInt() ?? 3).clamp(1, 3).toInt(),
      minExtraStoreSavings: minSavings != null && minSavings.isFinite &&
              minSavings >= 0 && minSavings <= 50
          ? minSavings
          : 0.50,
      enabledStoreNames: stores,
    );
  }
}
