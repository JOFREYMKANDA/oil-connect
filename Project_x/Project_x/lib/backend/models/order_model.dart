import 'package:intl/intl.dart';

class Order {
  String orderId;
  String? orderIdGenerated;
  String sharedGroupId;
  DateTime? createdDate;
  String fuelType;
  String routeWay;
  int capacity;
  String deliveryTime;
  String source;
  String stationName;
  String region;
  String depot;
  String companyName;
  double? price;
  double? distance;
  String status;
  String driverId;
  String driverName;
  String driverPhone;
  String driverStatus;
  String assignedOrder;
  String vehicleId;
  String customerFirstName;
  String customerLastName;
  String customerPhone;
  String district;
  double? depotLat;
  double? depotLng;
  double? stationLat;
  double? stationLng;
  DateTime? sharedSecondaryDate;
  DateTime? tripStartedAt;
  DateTime? completedAt;

  // Fields for shared orders
  List<Customer> customers;
  List<String> companyNames;

  // Multiple vehicles
  List<MatchingVehicle> matchingVehicles;

  // Populated data
  DriverDetails? populatedDriver;
  TruckOwnerDetails? populatedTruckOwner;
  VehicleDetails? populatedVehicle;

  List<StationDetailsPopulated> populatedStations;

  Order({
    required this.orderId,
    required this.orderIdGenerated,
    required this.sharedGroupId,
    required this.createdDate,
    required this.fuelType,
    required this.routeWay,
    required this.capacity,
    required this.deliveryTime,
    required this.source,
    required this.stationName,
    required this.region,
    required this.depot,
    required this.companyName,
    required this.price,
    required this.distance,
    required this.status,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverStatus,
    required this.assignedOrder,
    required this.vehicleId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerPhone,
    required this.district,
    this.depotLat,
    this.depotLng,
    this.stationLat,
    this.stationLng,
    this.customers = const [],
    this.companyNames = const [],
    this.matchingVehicles = const [],
    this.populatedDriver,
    this.populatedTruckOwner,
    this.populatedVehicle,
    this.populatedStations = const [],
  });

  /// Convert Order object to JSON
  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'orderIdGenerated': orderIdGenerated,
    'sharedGroupId': sharedGroupId,
    'createdDate': createdDate?.toIso8601String(),
    'fuelType': fuelType,
    'routeWay': routeWay,
    'capacity': capacity,
    'deliveryTime': deliveryTime,
    'source': source,
    'stationName': stationName,
    'region': region,
    'depot': depot,
    'companyName': companyName,
    'price': price,
    'distance': distance,
    'status': status,
    'driverId': driverId,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'driverStatus': driverStatus,
    'assignedOrder': assignedOrder,
    'vehicleId': vehicleId,
    'customerFirstName': customerFirstName,
    'customerLastName': customerLastName,
    'customerPhone': customerPhone,
    'district': district,
    'depotLat': depotLat,
    'depotLng': depotLng,
    'stationLat': stationLat,
    'stationLng': stationLng,
    'sharedSecondaryDate': sharedSecondaryDate?.toIso8601String(),
    'customers': customers.map((customer) {
      return {
        'id': customer.id,
        'firstname': customer.firstname,
        'lastname': customer.lastname,
        'phoneNumber': customer.phoneNumber,
        'capacity': customer.capacity,
        'price': customer.price,
        'stationDetails': customer.stationDetails.map((station) => {
          'stationName': station.stationName,
          'district': station.district,
          'region': station.region,
        }).toList(),
        'orderId': customer.orderId,
      };
    }).toList(),
    'companyNames': companyNames,
    'matchingVehicles': matchingVehicles.map((vehicle) => {
      'id': vehicle.id,
      'fuelType': vehicle.fuelType,
      'tankCapacity': vehicle.tankCapacity,
      'vehicleIdentity': vehicle.vehicleIdentity,
    }).toList(),
    'populatedDriver': populatedDriver?.toJson(),
    'populatedTruckOwner': populatedTruckOwner?.toJson(),
    'populatedVehicle': populatedVehicle?.toJson(),
    'populatedStations': populatedStations.map((station) => station.toJson()).toList(),
  };

  /// Minimal search JSON
  Map<String, dynamic> toSearchJson() => {
        'fuelType': fuelType,
        'depot': depot,
        'source': source,
        'company': companyName,
        'region': region,
      };

  /// Factory constructor to safely parse JSON
  factory Order.fromJson(Map<String, dynamic> json) {
  final stationsJson = json["stations"] as List<dynamic>? ?? [];
  final firstStation = (stationsJson.isNotEmpty) ? stationsJson[0] as Map<String, dynamic> : null;
  
  final companiesJson = json["companies"] as List<dynamic>? ?? [];
  
  // Extract customer data
  final customerJson = json["customerId"] is Map<String, dynamic> ? json["customerId"] as Map<String, dynamic> : null;
  
  return Order(
    orderId: json["_id"]?.toString() ?? "",
    orderIdGenerated: json["orderId"]?.toString() ?? "N/A",
    sharedGroupId: json["sharedGroupId"] ?? "",
    createdDate: json["formattedCreatedAt"] != null
        ? _parseDate(json["formattedCreatedAt"])
        : DateTime.tryParse(json["createdAt"] ?? ''),
    fuelType: json["fuelType"] ?? "Unknown Fuel",
    routeWay: json["routeWay"] ?? "Unknown Route",
    capacity: json["capacity"] ?? 0,
    // FIX: Use deliveryTime instead of formattedDeliveryTime
    deliveryTime: json["deliveryTime"]?.toString() ?? "Not Available",
    source: json["source"] ?? "Unknown Source",
    stationName: firstStation?["stationName"] ?? "Unknown Station",
    depot: json["depot"] ?? "Unknown Depot",
    companyName: companiesJson.isNotEmpty
        ? companiesJson[0]["name"] ?? "Unknown Company"
        : "Unknown Company",
    region: firstStation?["region"] ?? "",
    district: firstStation?["district"] ?? "",
    price: double.tryParse(json["price"]?.toString() ?? '') ?? 0.0,
    distance: double.tryParse(json["distance"]?.toString() ?? '') ?? 0.0,
    vehicleId: json["vehicleId"]?.toString() ?? "",
    status: json["status"] ?? "Pending",
    driverId: json["driverId"]?.toString() ?? "",
    driverName: "",
    driverPhone: "",
    driverStatus: "",
    assignedOrder: '',
    // FIX: Extract customer data from customerId field
    customerFirstName: customerJson?["firstname"] ?? '',
    customerLastName: customerJson?["lastname"] ?? '',
    customerPhone: customerJson?["phoneNumber"]?.toString() ?? '',
    depotLat: companiesJson.isNotEmpty
        ? double.tryParse(companiesJson[0]["latitude"]?.toString() ?? '')
        : null,
    depotLng: companiesJson.isNotEmpty
        ? double.tryParse(companiesJson[0]["longitude"]?.toString() ?? '')
        : null,
    stationLat: firstStation != null
        ? double.tryParse(firstStation["latitude"]?.toString() ?? '')
        : null,
    stationLng: firstStation != null
        ? double.tryParse(firstStation["longitude"]?.toString() ?? '')
        : null,
    customers: [],
    companyNames: (json['companyNames'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    matchingVehicles: (json["matchingVehicles"] as List<dynamic>? ?? [])
        .map((v) => MatchingVehicle.fromJson(v))
        .toList(),
    populatedDriver: (json["driverId"] is Map<String, dynamic>)
        ? DriverDetails.fromJson(json["driverId"])
        : null,
    populatedTruckOwner: (json["truckOwnerId"] is Map<String, dynamic>)
        ? TruckOwnerDetails.fromJson(json["truckOwnerId"])
        : null,
    populatedVehicle: (json["vehicleId"] is Map<String, dynamic>)
        ? VehicleDetails.fromJson(json["vehicleId"])
        : null,
    populatedStations: stationsJson
        .map((s) => StationDetailsPopulated.fromJson(
            s is String ? {"stationName": s} : s))
        .toList(),
  );
}

  String getFormattedDate() {
    return createdDate != null
        ? DateFormat("dd MMM yyyy, hh:mm a").format(createdDate!)
        : "Unknown Date";
  }

  static DateTime? _parseDate(String dateString) {
    try {
      return DateFormat("yyyy-MM-dd HH:mm").parse(dateString);
    } catch (e) {
      print("⚠️ Date parsing error: $e for value: $dateString");
      return null;
    }
  }
}

/// ---------------------- Nested Classes ----------------------

class StationDetailsPopulated {
  final String label;
  final String stationName;
  final String district;
  final String region;
  final double? latitude;
  final double? longitude;

  StationDetailsPopulated({
    required this.label,
    required this.stationName,
    required this.district,
    required this.region,
    this.latitude,
    this.longitude,
  });

  factory StationDetailsPopulated.fromJson(Map<String, dynamic> json) {
    return StationDetailsPopulated(
      label: json['label'] ?? json['stationName'] ?? '',
      stationName: json['stationName'] ?? '',
      district: json['district'] ?? '',
      region: json['region'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'stationName': stationName,
        'district': district,
        'region': region,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class Customer {
  final String id;
  final String firstname;
  final String lastname;
  final String phoneNumber;
  final int capacity;
  final double price;
  final List<StationDetail> stationDetails;
  final String orderId;

  Customer({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.phoneNumber,
    required this.capacity,
    required this.price,
    required this.stationDetails,
    required this.orderId,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    var stationDetailsJson = json['stationDetails'] as List? ?? [];
    return Customer(
      id: json['_id'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      phoneNumber: json['phoneNumber'].toString(),
      capacity: json['capacity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      stationDetails:
          stationDetailsJson.map((e) => StationDetail.fromJson(e)).toList(),
      orderId: json['orderId'] ?? '',
    );
  }
}

class StationDetail {
  final String stationName;
  final String district;
  final String region;

  StationDetail({
    required this.stationName,
    required this.district,
    required this.region,
  });

  factory StationDetail.fromJson(Map<String, dynamic> json) {
    return StationDetail(
      stationName: json['stationName'] ?? '',
      district: json['district'] ?? '',
      region: json['region'] ?? '',
    );
  }
}

class MatchingVehicle {
  final String id;
  final String fuelType;
  final int tankCapacity;
  final String vehicleIdentity;

  MatchingVehicle({
    required this.id,
    required this.fuelType,
    required this.tankCapacity,
    required this.vehicleIdentity,
  });

  factory MatchingVehicle.fromJson(Map<String, dynamic> json) {
    return MatchingVehicle(
      id: json['_id'] ?? '',
      fuelType: json['fuelType'] ?? '',
      tankCapacity: json['tankCapacity'] ?? 0,
      vehicleIdentity: json['vehicleIdentity'] ?? '',
    );
  }
}

class DriverDetails {
  final String id;
  final String name;
  final String phone;
  final String status;

  DriverDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "phone": phone,
        "status": status,
      };
}

class TruckOwnerDetails {
  final String id;
  final String name;
  final String phone;
  final String company;

  TruckOwnerDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.company,
  });

  factory TruckOwnerDetails.fromJson(Map<String, dynamic> json) {
    return TruckOwnerDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      company: json['company'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "phone": phone,
        "company": company,
      };
}

class VehicleDetails {
  final String id;
  final String fuelType;
  final int tankCapacity;
  final String vehicleIdentity;

  VehicleDetails({
    required this.id,
    required this.fuelType,
    required this.tankCapacity,
    required this.vehicleIdentity,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      id: json['_id'] ?? '',
      fuelType: json['fuelType'] ?? '',
      tankCapacity: json['tankCapacity'] ?? 0,
      vehicleIdentity: json['vehicleIdentity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "fuelType": fuelType,
        "tankCapacity": tankCapacity,
        "vehicleIdentity": vehicleIdentity,
      };
}
