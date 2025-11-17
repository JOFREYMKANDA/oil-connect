import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oil_connect/backend/controllers/gpsController.dart';

class GpsTrackingScreen extends StatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  final GpsController gpsController = Get.put(GpsController());
  late GoogleMapController mapController;

  Offset? gpsMarkerOffset;

  @override
  void initState() {
    super.initState();

    gpsController.onNewPosition = (LatLng pos) async {
      if (mapController != null) {
        final screenPoint = await mapController.getScreenCoordinate(pos);
        setState(() {
          gpsMarkerOffset = Offset(screenPoint.x.toDouble(), screenPoint.y.toDouble());
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live GPS Tracking'),
        backgroundColor: Colors.green.shade800,
        centerTitle: true,
      ),
      body: GetBuilder<GpsController>(
        builder: (controller) {
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: controller.currentPosition ?? controller.initialPosition,
                  zoom: 15,
                ),
                markers: controller.markers,
                myLocationEnabled: false,
                onMapCreated: (c) async {
                  mapController = c;
                  if (gpsController.currentPosition != null) {
                    final screenPoint = await c.getScreenCoordinate(gpsController.currentPosition!);
                    setState(() {
                      gpsMarkerOffset = Offset(screenPoint.x.toDouble(), screenPoint.y.toDouble());
                    });
                  }
                },
                onCameraMove: (position) async {
                  if (gpsController.currentPosition != null) {
                    final screenPoint = await mapController.getScreenCoordinate(gpsController.currentPosition!);
                    setState(() {
                      gpsMarkerOffset = Offset(screenPoint.x.toDouble(), screenPoint.y.toDouble());
                    });
                  }
                },
              ),

              if (gpsMarkerOffset != null)
                Positioned(
                  left: gpsMarkerOffset!.dx - 130,
                  top: gpsMarkerOffset!.dy - 110,
                  child: const ExpandableMarker(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ExpandableMarker extends StatefulWidget {
  const ExpandableMarker({super.key});

  @override
  State<ExpandableMarker> createState() => _ExpandableMarkerState();
}

class _ExpandableMarkerState extends State<ExpandableMarker> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
  }

  static const double _containerHeight = 32;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GpsController>();
    final data = controller.latestData;
    final speed = data?['speed']?.toStringAsFixed(0) ?? '0';
    final direction = data?['direction'] ?? 'N';
    final vehicleId = data?['vehicleIdentity'] ?? 'Unknown';
    final position = controller.currentPosition;
    final location = controller.locationName ?? 'Loading...';

    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState:
        _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: _buildCompactView(),
        secondChild: _buildExpandedView(vehicleId, direction, speed, position, location),
      ),
    );
  }

  Widget _buildCompactView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: _containerHeight,
                width: _containerHeight,
                color: Colors.green[800],
                alignment: Alignment.center,
                child: Image.asset('assets/steering.jpg', width: 16, height: 16),
              ),
              Container(
                height: _containerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                color: Colors.green[700],
                child: const Text(
                  'Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -8),
          child: Icon(Icons.arrow_drop_down, size: 24, color: Colors.green[700]),
        ),
      ],
    );
  }

  Widget _buildExpandedView(String vehicleId, String direction, String speed, LatLng? pos, String location) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[800],
                    radius: 16,
                    child: Image.asset('assets/steering.jpg', width: 16, height: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'ID: $vehicleId',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white38, height: 1),
              const SizedBox(height: 8),
              _infoRow("Direction", direction),
              _infoRow("Speed", "$speed km/h"),
              _infoRow(
                "Coordinates",
                pos != null
                    ? "Lat: ${pos.latitude.toStringAsFixed(5)}, Lng: ${pos.longitude.toStringAsFixed(5)}"
                    : "Unknown",
              ),
              _infoRow("Location", location),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -8),
          child: Icon(Icons.arrow_drop_down, size: 24, color: Colors.green[700]),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
