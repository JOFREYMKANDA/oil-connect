import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_constants.dart';
import '../../utils/shared_pref_utils.dart';
import '../models/station_model.dart';

class StationService {
  Future<bool> registerStation(Station station) async {
    final url = ApiConstants.stationRegisterUrl;
    final token = SharedPrefsUtil().getToken();
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(station.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        try {
          final body = jsonDecode(response.body);
          final message = body['message'] ?? 'Unknown error';
          print("Station registration failed: $message");
          
          // Handle specific error cases based on status code and message
          if (response.statusCode == 400) {
            if (message.toLowerCase().contains('already registered') || 
                message.toLowerCase().contains('already exists')) {
              print("Station already exists: $message");
            } else if (message.toLowerCase().contains('all fields are required') || 
                       message.toLowerCase().contains('required fields')) {
              print("Missing required fields: $message");
            } else {
              print("Invalid information: $message");
            }
          } else if (response.statusCode == 500) {
            print("Server error during station registration: $message");
          } else {
            print("Station registration error: $message");
          }
        } catch (e) {
          print("Error parsing station registration response: $e");
        }
        return false;
      }
    } catch (e) {
      print("Error in StationService.registerStation: $e");
      return false;
    }
  }

  Future<List<Station>> fetchStations() async {
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
        List stations = data['stations'];
        return stations.map((e) => Station.fromJson(e)).toList();
      } else {
        //print("Failed to fetch stations: ${response.body}");
        return [];
      }
    } catch (e) {
      //print("Error fetching stations: $e");
      return [];
    }
  }

}
