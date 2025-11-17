class TruckLocation {
  final String id;
  final String vehicleType;
  final String plateNumber;
  final String vehicleColor;
  final String status;
  final String vehicleIdentity;
  final double latitude;
  final double longitude;
  final double? speed;
  final String? driverName;
  final String? truckOwnerName;
  final DateTime? lastUpdated;
  final bool isOnline;

  TruckLocation({
    required this.id,
    required this.vehicleType,
    required this.plateNumber,
    required this.vehicleColor,
    required this.status,
    required this.vehicleIdentity,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.driverName,
    this.truckOwnerName,
    this.lastUpdated,
    this.isOnline = false,
  });

  factory TruckLocation.fromJson(Map<String, dynamic> json) {
    return TruckLocation(
      id: json['_id'] ?? json['id'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      plateNumber: _extractPlateNumber(json['plateNumber']),
      vehicleColor: json['vehicleColor'] ?? '',
      status: json['status'] ?? '',
      vehicleIdentity: json['vehicleIdentity'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      speed: json['speed']?.toDouble(),
      driverName: json['driverName'],
      truckOwnerName: json['truckOwnerName'],
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.tryParse(json['lastUpdated'].toString())
          : null,
      isOnline: json['isOnline'] ?? false,
    );
  }

  static String _extractPlateNumber(dynamic plateData) {
    if (plateData is Map<String, dynamic>) {
      return plateData['trailerPlate'] ?? 
             plateData['headPlate'] ?? 
             plateData['specialPlate'] ?? 
             'N/A';
    }
    return plateData?.toString() ?? 'N/A';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'vehicleColor': vehicleColor,
      'status': status,
      'vehicleIdentity': vehicleIdentity,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'driverName': driverName,
      'truckOwnerName': truckOwnerName,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  String get displayName => '$vehicleType ($plateNumber)';
  
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Available';
      case 'busy':
        return 'On Delivery';
      case 'submitted':
        return 'Pending Approval';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
