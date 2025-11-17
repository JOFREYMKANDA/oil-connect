import 'package:oil_connect/utils/url_utils.dart';

class User {
  final String? id;
  final String firstname;
  final String lastname;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final String? region;
  final String? district;
  final String? licenseNumber;
  final DateTime? licenseExpireDate;
  final double? latitude;
  final double? longitude;
  final String? userDepo;
  final String? password;
  final String? workingPosition;
  final String role;
  final String? status;
  final String? vehicleId;

  User({
    this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    this.region,
    this.district,
    this.licenseNumber,
    this.licenseExpireDate,
    this.latitude,
    this.longitude,
    this.userDepo,
    this.password,
    this.workingPosition,
    required this.role,
    this.status,
    this.vehicleId,
  });

  User copyWith({
    String? firstname,
    String? lastname,
    String? email,
    String? phoneNumber,
    String? profileImage,
    String? region,
    String? district,
    String? licenseNumber,
    DateTime? licenseExpireDate,
    double? latitude,
    double? longitude,
    String? userDepo,
    String? password,
    String? workingPosition,
    String? role,
    String? status,
  }) {
    return User(
      id: id ?? id,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      region: region ?? this.region,
      district: district ?? this.district,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpireDate: licenseExpireDate ?? this.licenseExpireDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userDepo: userDepo ?? this.userDepo,
      password: password ?? this.password,
      workingPosition: workingPosition ?? this.workingPosition,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'].toString(),
      profileImage: UrlUtils.absoluteImageUrl(json['profileImage']),
      region: json['region'],
      district: json['district'],
      licenseNumber: json['licenseNumber'],
      licenseExpireDate: json['licenseExpireDate'] != null
          ? DateTime.tryParse(json['licenseExpireDate'])
          : null,
      latitude:
          json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude:
          json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      userDepo: json['userDepo'],
      password: json['password'],
      workingPosition: json['workingPosition'],
      role: json['role'] ?? 'user',
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'phoneNumber': phoneNumber ?? '',
      'profileImage': profileImage,
      'region': region,
      'district': district,
      'licenseNumber': licenseNumber,
      'licenseExpireDate': licenseExpireDate?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'userDepo': userDepo,
      'password': password,
      'workingPosition': workingPosition,
      'role': role,
      'status': status,
    };
  }

  // ✅ Added override for printing user details clearly
  @override
  String toString() {
    return '''
User Details:
  ID: $id
  Name: $firstname $lastname
  Email: $email
  Phone: $phoneNumber
  Profile Image: $profileImage
  Region: $region
  District: $district
  License Number: $licenseNumber
  License Expire Date: $licenseExpireDate
  Latitude: $latitude
  Longitude: $longitude
  User Depo: $userDepo
  Password: $password
  Working Position: $workingPosition
  Role: $role
  Status: $status
  Vehicle ID: $vehicleId
''';
  }
}
