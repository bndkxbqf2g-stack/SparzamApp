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

  factory PriceDataSettings.fromJson(Map<String, dynamic> json) =>
      PriceDataSettings(
        openPricesEnabled: json['openPricesEnabled'] as bool? ?? true,
        openPricesMaxAgeDays:
            ((json['openPricesMaxAgeDays'] as num?)?.toInt() ?? 60)
                .clamp(7, 365)
                .toInt(),
        autoSyncOnCatalogOpen:
            json['autoSyncOnCatalogOpen'] as bool? ?? false,
      );
}
