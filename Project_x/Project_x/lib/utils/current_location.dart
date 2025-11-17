import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  /// Check and request location permissions
  Future<bool> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            "Location permission denied. Please allow location access.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          "Location permissions are permanently denied. Please enable them in settings.");
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Fetches the user's current location
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            "Location services are disabled. Please enable them.");
      }

      // Request location permission
      bool permissionGranted = await _requestPermission();
      if (!permissionGranted) {
        throw Exception(
            "Location permission not granted. Please allow location access.");
      }

      // Fetch current location
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception("Failed to get current location: $e");
    }
  }
}
