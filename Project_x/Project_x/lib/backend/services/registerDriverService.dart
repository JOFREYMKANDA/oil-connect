import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:oil_connect/utils/api_constants.dart';
import '../models/driver_model.dart';
import '../models/user_model.dart';

class DriverRegistrationService {
  Future<bool> registerDriver(User user, String token) async {
    final url = ApiConstants.registerDriverUrl;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        try {
          final body = jsonDecode(response.body);
          final message = body['message'] ?? 'Unknown error';

          if (response.statusCode == 400) {
            if (message.toLowerCase().contains('email already registered') || 
                message.toLowerCase().contains('email already exists')) {
              Get.snackbar(
                'Email Already Exists',
                'This email address is already registered. Please use a different email or try logging in.',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            } else if (message.toLowerCase().contains('all fields are required') || 
                       message.toLowerCase().contains('required fields')) {
              Get.snackbar(
                'Missing Information',
                'Please fill in all required fields to complete driver registration.',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            } else {
              Get.snackbar(
                'Invalid Information',
                message,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          } else if (response.statusCode == 500) {
            Get.snackbar(
              'Registration Failed',
              'Server error occurred during driver registration. Please try again later.',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          } else {
            Get.snackbar(
              'Error',
              message,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }

          throw Exception(message);
        } catch (e) {
          throw Exception('Unexpected error occurred');
        }
      }
    } catch (e) {
      // Log error and rethrow to controller
      print('Exception registering driver: $e');
      throw Exception(e.toString());
    }
  }


  // ✅ Fetch drivers
  Future<List<Driver>> fetchDrivers(String token) async {
    final url = ApiConstants.driverDetailsUrl;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('drivers') && data['drivers'] is List) {
          return (data['drivers'] as List)
              .map((json) => Driver.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Invalid response format: Missing "drivers" key');
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {

      throw Exception('Error fetching drivers: $e');
    }
  }

  static Future<bool> updateDriver(
      String token, String driverId, Map<String, dynamic> data) async {
    final url = ApiConstants.updateDriverUrl.replaceFirst(':driverId', driverId);

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update driver: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating driver: $e');
      return false;
    }
  }

  static Future<bool> deleteDriver(String driverId, String token) async {
    final url = ApiConstants.deleteDriverUrl.replaceFirst(':driverId', driverId);

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete driver: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting driver: $e');
      throw Exception('Error deleting driver: $e');
    }
  }
}
