import 'dart:convert';

class Vehicle {
  final String vehicleType;
  final PlateNumber plateNumber;
  final String vehicleColor;
  final int vehicleModelYear;
  final String fuelType;
  final double tankCapacity;
  final double latitude;
  final double longitude;
  final int numberOfCompartments;
  final List<double> compartmentCapacities;
  //final VehicleRegister vehicleRegister;
  final List<Document> documents;
  final String? status;
  final String? vehicleIdentity;

  Vehicle({
    required this.vehicleType,
    required this.plateNumber,
    required this.vehicleColor,
    required this.vehicleModelYear,
    required this.fuelType,
    required this.tankCapacity,
    required this.latitude,
    required this.longitude,
    required this.numberOfCompartments,
    required this.compartmentCapacities,
    //required this.vehicleRegister,
    required this.documents,
    this.vehicleIdentity,
    this.status,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleType: json['vehicleType'] ?? '',
      plateNumber: PlateNumber.fromJson(json['plateNumber'] ?? {}),
      vehicleColor: json['vehicleColor'] ?? '',
      vehicleModelYear: json['vehicleModelYear'] ?? 0,
      fuelType: json['fuelType'] ?? '',
      tankCapacity: (json['tankCapacity'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      numberOfCompartments: json['numberOfCompartments'] ?? 0,
      compartmentCapacities: (json['compartmentCapacities'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      //vehicleRegister: VehicleRegister.fromJson(json['vehicleRegister'] ?? {}),
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map((doc) => Document.fromJson(doc))
          .toList(),
      status: json['status'],
      vehicleIdentity: json['vehicleIdentity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType,
      'plateNumber': plateNumber.toJson(),
      'vehicleColor': vehicleColor,
      'vehicleModelYear': vehicleModelYear,
      'fuelType': fuelType,
      'tankCapacity': tankCapacity,
      'latitude': latitude,
      'longitude': longitude,
      'numberOfCompartments': numberOfCompartments,
      'compartmentCapacities': compartmentCapacities,
      //'vehicleRegister': vehicleRegister.toJson(),
      'documents': documents.map((doc) => doc.toJson()).toList(),
      if (status != null) 'status': status,
    };
  }
}

class PlateNumber {
  final String? headPlate;
  final String? trailerPlate;
  final String? specialPlate;

  PlateNumber({this.headPlate, this.trailerPlate, this.specialPlate});

  factory PlateNumber.fromJson(Map<String, dynamic> json) {
    return PlateNumber(
      headPlate: json['headPlate'],
      trailerPlate: json['trailerPlate'],
      specialPlate: json['specialPlate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headPlate': headPlate,
      'trailerPlate': trailerPlate,
      'specialPlate': specialPlate,
    };
  }
}

// class VehicleRegister {
//   final String fullname;
//   final String phoneNumber;
//   final String email;
//   final String address;
//
//   VehicleRegister({
//     required this.fullname,
//     required this.phoneNumber,
//     required this.email,
//     required this.address,
//   });
//
//   factory VehicleRegister.fromJson(Map<String, dynamic> json) {
//     return VehicleRegister(
//       fullname: json['fullname'] ?? '',
//       phoneNumber: json['phoneNumber'] ?? '',
//       email: json['email'] ?? '',
//       address: json['address'] ?? '',
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'fullname': fullname,
//       'phoneNumber': phoneNumber,
//       'email': email,
//       'address': address,
//     };
//   }
// }

class Document {
  final String name;
  final String filePath;

  Document({required this.name, required this.filePath});

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      name: json['name'] ?? '',
      filePath: json['filePath'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filePath': filePath,
    };
  }
}