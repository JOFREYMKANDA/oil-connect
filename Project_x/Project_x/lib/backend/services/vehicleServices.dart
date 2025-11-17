import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:oil_connect/backend/models/vehicle_model.dart';
import 'package:oil_connect/utils/api_constants.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';


class VehicleService {
  Future<Map<String, dynamic>> submitRegistration(
      Map<String, dynamic> formData, List<File?> attachments) async {
    try {
      String? token = await SharedPrefsUtil().getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.vehicleRegisterUrl),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      formData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value is List
              ? jsonEncode(value)
              : value.toString();
        }
      });

      for (int i = 0; i < attachments.length; i++) {
        if (attachments[i] != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'documents', 
            attachments[i]!.path,
          ));
        }
      }

      var response = await request.send();

      // Parse response
      var responseBody = await response.stream.bytesToString();
      var decodedResponse = json.decode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': decodedResponse};
      } else {
        return {
          'success': false,
          'message': decodedResponse['message'] ?? 'Registration failed',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

//Fetch all vehicle
  Future<List<Vehicle>?> getAllVehicles() async {
    final url = ApiConstants.allVehiclesUrl;
    final token = SharedPrefsUtil().getToken();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List vehicles = data['vehicles'] ?? [];
        return vehicles.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        print("Failed to fetch vehicles: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching vehicles: $e");
      return null;
    }
  }
}
