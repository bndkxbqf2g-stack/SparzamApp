class MobilitySettings {
  const MobilitySettings({
    this.startAddress = '97225 Zellingen, Germany',
    this.euroPerKm = 0.22,
  });

  final String startAddress;
  final double euroPerKm;

  MobilitySettings copyWith({
    String? startAddress,
    double? euroPerKm,
  }) =>
      MobilitySettings(
        startAddress: startAddress ?? this.startAddress,
        euroPerKm: euroPerKm ?? this.euroPerKm,
      );

  Map<String, dynamic> toJson() => {
        'startAddress': startAddress,
        'euroPerKm': euroPerKm,
      };

  factory MobilitySettings.fromJson(Map<String, dynamic> json) =>
      MobilitySettings(
        startAddress:
            (json['startAddress'] as String?)?.trim().isNotEmpty == true
                ? (json['startAddress'] as String).trim()
                : '97225 Zellingen, Germany',
        euroPerKm: (json['euroPerKm'] as num?)?.toDouble() ?? 0.22,
      );
}
