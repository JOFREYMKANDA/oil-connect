import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oil_connect/backend/controllers/gpsController.dart';
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/AppBar.dart';

class LiveLocationScreen extends StatefulWidget {
  final Order order;

  const LiveLocationScreen({super.key, required this.order});

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  final GpsController gpsController = Get.put(GpsController());
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();

    gpsController.onNewPosition = (LatLng newPos) {
      _mapController.animateCamera(CameraUpdate.newLatLng(newPos));
    };
  }

  @override
  void dispose() {
    gpsController.onNewPosition = null; // Clear callback
    super.dispose();
  }

  Future<List<LatLng>> getRouteCoordinates(
      LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=AIzaSyCkV7CBL4IbYTvQaabyX--La9GFQLUHGpE',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final points = data['routes'][0]['overview_polyline']['points'];
      return decodePolyline(points);
    } else {
      throw Exception('Failed to load directions: ${data['status']}');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackAppBar(title: "Live Location"),
      // AppBar(
      //   backgroundColor: AppColors.rectangleColor,
      //   elevation: 0,
      //   iconTheme: const IconThemeData(color: AppColors.shapeColor),
      //   centerTitle: true,
      //   title: const Text(
      //     "Live Location",
      //     style: TextStyle(color: AppColors.shapeColor, fontWeight: FontWeight.bold),
      //   ),
      // ),
      body: GetBuilder<GpsController>(
        builder: (_) {
          return Stack(
            children: [
              /// 🗺 Google Map
              GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: gpsController.currentPosition ??
                      gpsController.initialPosition,
                  zoom: 14,
                ),
                markers: gpsController.markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
              ),

              /// 📦 Order Info Overlay
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Tracking live location for Order ID: ${widget.order.orderId}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
