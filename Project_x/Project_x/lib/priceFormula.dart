import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oil_connect/utils/constants.dart';

class PriceCalculator {
  static String googleApiKey = AppConstants.kGoogleApiKey; // Replace with your actual API key

  /// Calculate road distance between two coordinates using Google Maps Directions API.
  /// Returns the distance in kilometers, or `null` if the calculation fails.
  static Future<double?> getDistanceFromGoogleMaps(
      double stationLat, double stationLng, double companyLat, double companyLng) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$stationLat,$stationLng&destination=$companyLat,$companyLng&key=$googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if ((data['routes'] as List).isNotEmpty) {
          final distanceMeters =
              data['routes'][0]['legs'][0]['distance']['value'] ?? 0; // Distance in meters
          return distanceMeters / 1000; // Convert to kilometers
        }
      }
    } catch (e) {
      print("Error fetching distance: $e");
    }
    return null;
  }

  /// Calculate price using the given distance and capacity.
  /// Formula: `price = ((distance - 21.8) / 6.3944) * capacity`
  static double calculatePrice(double distance, double capacity) {
    double price = ((distance - 21.8) / 6.3944) * capacity;
    return (price / 1000).round() * 1000; // Rounds to the nearest thousand
  }
}
