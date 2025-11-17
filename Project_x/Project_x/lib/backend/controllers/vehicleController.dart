import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/api_constants.dart';
import '../../utils/shared_pref_utils.dart';
import '../models/vehicle_model.dart';
import 'package:http/http.dart' as http;
import '../services/vehicleServices.dart';
import '../../screens/login screens/login.dart';

class VehicleController extends GetxController {
  final VehicleService _vehicleService = VehicleService();
  var isLoading = false.obs;
  var vehicles = <Vehicle>[].obs;

  Future<bool> submitRegistration(
      Map<String, dynamic> formData, List<File?> attachments) async {
    isLoading.value = true;

    try {
      // Ensure SharedPrefsUtil is initialized
      await SharedPrefsUtil().init();
      
      String? token = SharedPrefsUtil().getToken();
      String? role = SharedPrefsUtil().getRole();
      print("🔍 Token retrieved: ${token != null ? 'Present' : 'Null'}");
      print("👤 Role retrieved: $role");


      if (token == null || token.isEmpty) {
        Get.snackbar(
          "Error",
          "Authentication token not found. Please log in again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return false;
      }

      // Check if user has the correct role for vehicle registration
      if (role != "TruckOwner") {
        Get.snackbar(
          "Access Denied",
          "Only truck owners can register vehicles. Your role: $role",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return false;
      }

      // Validate file sizes before submission
      const maxFileSize = 1024 * 1024; // 1MB limit
      for (int i = 0; i < attachments.length; i++) {
        if (attachments[i] != null) {
          final fileSize = await attachments[i]!.length();
          if (fileSize > maxFileSize) {
            final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
            Get.snackbar(
              "File Too Large",
              "File ${i + 1} is ${fileSizeMB}MB. Maximum allowed is 1MB per file.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            isLoading.value = false;
            return false;
          }
        }
      }

      // Debug token information
      print("🔐 Token being used: $token");
      print("🔐 Token length: ${token.length}");
      
      // Validate token format
      if (!token.contains('.')) {
        Get.snackbar(
          "Invalid Token",
          "Token format is invalid. Please login again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return false;
      }
      
      try {
        // Decode token to extract user ID
        final payload = json.decode(
            utf8.decode(base64.decode(base64.normalize(token.split(".")[1]))));
        final userId = payload['id'];
        print("👤 User ID from token: $userId");
        
        // Check if token is expired
        final exp = payload['exp'];
        if (exp != null) {
          final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          final now = DateTime.now();
          print("⏰ Token expires at: $expirationTime");
          print("⏰ Current time: $now");
          
          if (now.isAfter(expirationTime)) {
            Get.snackbar(
              "Session Expired",
              "Your session has expired. Please login again.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            isLoading.value = false;
            return false;
          }
        }
      } catch (e) {
        print("❌ Error decoding token: $e");
        Get.snackbar(
          "Invalid Token",
          "Token is corrupted. Please login again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return false;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.vehicleRegisterUrl),
      );

      request.headers['Authorization'] = 'Bearer $token';
      print("🔐 Authorization header: Bearer $token");

      request.fields['vehicleType'] = formData['vehicle_type'] ?? '';
      request.fields['vehicleColor'] = formData['truck_color'] ?? '';
      request.fields['vehicleModelYear'] = formData['model_year'] ?? '';
      request.fields['numberOfCompartments'] =
          formData['compartments']?.length.toString() ?? '';
      request.fields['compartmentCapacities'] = jsonEncode(
        formData['compartments']
            ?.map((compartment) => compartment['capacity'])
            .toList() ??
            [],
      );
      request.fields['tankCapacity'] = formData['tank_capacity'] ?? '';
      //request.fields['plateNumber'] = formData['trailer_plate_number'] ?? '';
      //request.fields['fuelType'] = formData['fuel_type'] ?? '';
      //request.fields['owner'] = userId ?? '';
      //request.fields['plateNumber[headPlate]'] =
          //formData['head_plate_number'] ?? '';
      request.fields['plateNumber[trailerPlate]'] =
          formData['trailer_plate_number'] ?? '';
      //request.fields['plateNumber[specialPlate]'] =
          //formData['special_plate_number'] ?? '';

      // final vehicleRegister = {
      //   'fullname': formData['full_name']?.toString() ?? '',
      //   'phoneNumber': formData['phone']?.toString() ?? '',
      //   'email': formData['email']?.toString() ?? '',
      //   'address': formData['address']?.toString() ?? '',
      // };

      //request.fields['vehicleRegister'] = json.encode(vehicleRegister);

      // Attach documents
      for (int i = 0; i < attachments.length; i++) {
        if (attachments[i] != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'documents',
            attachments[i]!.path,
          ));
        }
      }

      // ✅ DEBUG LOGS: PRINT ALL DATA BEFORE SENDING
      print("=========== 🚛 START VEHICLE SUBMISSION ===========");
      request.fields.forEach((key, value) {
        print("📦 FIELD - $key: $value");
      });

      for (var file in request.files) {
        print("📎 FILE - ${file.filename} (${file.length})");
      }
      print("=========== ✅ END VEHICLE SUBMISSION ===========");

      // ✅ Send request and log response
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("📥 Response Code: ${response.statusCode}");
      print("📥 Response Body: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = json.decode(responseBody);
        if (responseData['message'] != null) {
           Get.snackbar(
             "Success",
             responseData['message'],
             snackPosition: SnackPosition.BOTTOM,
             backgroundColor: Colors.green,
             colorText: Colors.white,
           );
        }
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Handle authentication errors
        Get.snackbar(
          "Session Expired",
          "Your session has expired. Please login again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        
        // Clear stored data and redirect to logi
        await SharedPrefsUtil().clearData();
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAll(() => const LoginScreen());
        });
        return false;
      } else {
        Get.snackbar(
          "Error",
          "Failed to register truck. Status code: ${response.statusCode}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "An unexpected error occurred: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }

    return false;
  }

  Future<void> getAllVehicles() async {
    isLoading.value = true;
    try {
      final fetchedVehicles = await _vehicleService.getAllVehicles();
      if (fetchedVehicles != null) {
        vehicles.value = fetchedVehicles;
      } else {
        Get.snackbar("Error", "Failed to fetch vehicles.");
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
