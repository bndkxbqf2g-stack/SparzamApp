class PriceDataSettings {
  const PriceDataSettings({
    this.openPricesEnabled = true,
    this.openPricesMaxAgeDays = 60,
    this.autoSyncOnCatalogOpen = false,
  });

  final bool openPricesEnabled;
  final int openPricesMaxAgeDays;
  final bool autoSyncOnCatalogOpen;

  PriceDataSettings copyWith({
    bool? openPricesEnabled,
    int? openPricesMaxAgeDays,
    bool? autoSyncOnCatalogOpen,
  }) =>
      PriceDataSettings(
        openPricesEnabled: openPricesEnabled ?? this.openPricesEnabled,
        openPricesMaxAgeDays:
            openPricesMaxAgeDays ?? this.openPricesMaxAgeDays,
        autoSyncOnCatalogOpen:
            autoSyncOnCatalogOpen ?? this.autoSyncOnCatalogOpen,
      );

  Map<String, dynamic> toJson() => {
        'openPricesEnabled': openPricesEnabled,
        'openPricesMaxAgeDays': openPricesMaxAgeDays,
        'autoSyncOnCatalogOpen': autoSyncOnCatalogOpen,
      };

  factory PriceDataSettings.fromJson(Map<String, dynamic> json) {
    final rawAge = (json['openPricesMaxAgeDays'] as num?)?.toDouble();
    final age = rawAge != null && rawAge.isFinite ? rawAge.toInt() : 60;
    return PriceDataSettings(
      openPricesEnabled: json['openPricesEnabled'] as bool? ?? true,
      openPricesMaxAgeDays: age.clamp(7, 365).toInt(),
      autoSyncOnCatalogOpen:
          json['autoSyncOnCatalogOpen'] as bool? ?? false,
    );
  }
}
