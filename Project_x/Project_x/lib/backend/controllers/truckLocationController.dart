import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:oil_connect/backend/models/truck_location_model.dart';
import 'package:oil_connect/utils/api_constants.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TruckLocationController extends GetxController {
  var availableTrucks = <TruckLocation>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  
  // Map markers for trucks
  final Set<Marker> truckMarkers = <Marker>{}.obs;
  
  // Socket for real-time updates
  IO.Socket? socket;
  Timer? _refreshTimer;
  
  @override
  void onInit() {
    super.onInit();
    fetchAvailableTrucks();
    _startPeriodicRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    socket?.disconnect();
    socket?.dispose();
    super.onClose();
  }

  /// Fetch all available trucks with their locations
  Future<void> fetchAvailableTrucks() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await SharedPrefsUtil().init();
      final token = SharedPrefsUtil().getToken();
      
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Get latest GPS data first
      final gpsResponse = await http.get(
        Uri.parse(ApiConstants.allGpsDataUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (gpsResponse.statusCode == 200) {
        final gpsData = jsonDecode(gpsResponse.body) as List<dynamic>;
        
        // Filter GPS data for installed devices with vehicleIdentity
        final installedGpsData = gpsData.where((gps) => 
          gps['status'] == 'INSTALLED' && 
          gps['vehicleIdentity'] != null &&
          gps['latitude'] != null &&
          gps['longitude'] != null
        ).toList();

        // Convert GPS data to truck locations
        final trucksList = <TruckLocation>[];
        for (final gps in installedGpsData) {
          trucksList.add(TruckLocation(
            id: gps['id'] ?? '',
            vehicleType: 'Oil Tanker', // Default type since GPS data doesn't have this
            plateNumber: gps['vehicleIdentity'] ?? 'Unknown',
            vehicleColor: 'Unknown',
            status: 'Available', // Default status
            vehicleIdentity: gps['vehicleIdentity'] ?? '',
            latitude: (gps['latitude'] ?? 0.0).toDouble(),
            longitude: (gps['longitude'] ?? 0.0).toDouble(),
            speed: gps['speed']?.toDouble(),
            lastUpdated: DateTime.tryParse(gps['timestamp']?.toString() ?? ''),
            isOnline: true,
          ));
        }
        
        availableTrucks.value = trucksList;
        _updateTruckMarkers();
        
      } else {
        throw Exception('Failed to fetch GPS data: ${gpsResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching trucks: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }


  /// Update map markers for trucks
  void _updateTruckMarkers() {
    truckMarkers.clear();
    
    for (final truck in availableTrucks) {
      if (truck.latitude != 0.0 && truck.longitude != 0.0) {
        truckMarkers.add(
          Marker(
            markerId: MarkerId('truck_${truck.id}'),
            position: LatLng(truck.latitude, truck.longitude),
            infoWindow: InfoWindow(
              title: truck.displayName,
              snippet: '${truck.statusDisplay} • ${truck.vehicleColor}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              truck.status.toLowerCase() == 'busy' 
                ? BitmapDescriptor.hueRed 
                : BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    }
  }

  /// Start periodic refresh of truck locations
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchAvailableTrucks();
    });
  }

  /// Get trucks near a specific location
  List<TruckLocation> getTrucksNearLocation(double latitude, double longitude, {double radiusKm = 50.0}) {
    return availableTrucks.where((truck) {
      final distance = _calculateDistance(
        latitude, longitude,
        truck.latitude, truck.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Refresh truck data manually
  Future<void> refreshTrucks() async {
    await fetchAvailableTrucks();
  }

  /// Get truck count by status
  Map<String, int> getTruckCountByStatus() {
    final counts = <String, int>{};
    for (final truck in availableTrucks) {
      counts[truck.statusDisplay] = (counts[truck.statusDisplay] ?? 0) + 1;
    }
    return counts;
  }
}
