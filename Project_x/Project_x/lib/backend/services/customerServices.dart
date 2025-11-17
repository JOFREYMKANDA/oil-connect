import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_constants.dart';
import '../../utils/shared_pref_utils.dart';
import '../models/depot_model.dart';
import '../models/station_model.dart';

class CustomerService {
  Future<List<Depot>> fetchDepots() async {
    final url = ApiConstants.allDepotsUrl;
    final token = SharedPrefsUtil().getToken(); // Ensure token retrieval is awaited

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final depots = (data['depots'] as List)
            .map((depot) => Depot.fromJson(depot as Map<String, dynamic>))
            .toList();
        return depots;
      } else {
        print("Failed to fetch depots: ${response.body}");
        throw Exception("Failed to fetch depots. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching depots: $e");
      throw Exception("An error occurred while fetching depots: $e");
    }
  }

  Future<List<Station>> fetchCustomerStations() async {
    final url = ApiConstants.allStationsUrl;
    final token = SharedPrefsUtil().getToken();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stations = (data['stations'] as List)
            .map((station) => Station.fromJson(station as Map<String, dynamic>))
            .toList();
        return stations;
      } else if (response.statusCode == 404) {
        // Customer has no registered stations - return empty list instead of throwing error
        print("No stations found for customer - returning empty list");
        return [];
      } else {
        print("Failed to fetch customer stations: ${response.body}");
        throw Exception("Failed to fetch customer stations. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching customer stations: $e");
      throw Exception("An error occurred while fetching customer stations: $e");
    }
  }
}
