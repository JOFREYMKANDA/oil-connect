class Station {
  final String stationName;
  final String label;
  final String region;
  final String district;
  final double latitude;
  final double longitude;

  Station({
    required this.stationName,
    required this.label,
    required this.region,
    required this.district,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'stationName': stationName,
      'label': label,
      'region': region,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      stationName: json['stationName'] ?? '',
      label: json['label'] ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}
