class Driver {
  final String id;
  final String firstname;
  final String lastname;
  final String phoneNumber;
  final String email;
  final String role;
  final String status;
  final String? licenseNumber;
  final DateTime? licenseExpireDate;

  Driver({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.phoneNumber,
    required this.email,
    required this.role,
    required this.status,
    this.licenseNumber,
    this.licenseExpireDate,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      phoneNumber: json['phoneNumber'] != null
          ? json['phoneNumber'].toString() // ✅ Convert int to String
          : '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? 'unknown',
      licenseNumber: json['licenseNumber'],
      licenseExpireDate: json['licenseExpireDate'] != null
          ? DateTime.parse(json['licenseExpireDate'])
          : null,
    );
  }
}