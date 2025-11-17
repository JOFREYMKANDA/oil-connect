import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oil_connect/utils/colors.dart';

class TestMarkerScreen extends StatefulWidget {
  const TestMarkerScreen({super.key});

  @override
  State<TestMarkerScreen> createState() => _TestMarkerScreenState();
}

class _TestMarkerScreenState extends State<TestMarkerScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(-6.7924, 39.2083);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Marker'),
        backgroundColor: AppColors.rectangleColor,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 14),
            onMapCreated: (controller) => mapController = controller,
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
          const Center(
            child: ExpandableMarker(),
          ),
        ],
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
    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState:
        _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: _buildCompactView(),
        secondChild: _buildExpandedView(),
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
                child: Image.asset(
                  'assets/steering.jpg',
                  width: 16,
                  height: 16,
                ),
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
        Image.asset('assets/marker.png', width: 64, height: 64),
      ],
    );
  }


  Widget _buildExpandedView() {
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'AI Tech - Not reporting Issue',
                          style: TextStyle(
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
              _infoRow("Direction", "E"),
              _infoRow("Speed", "0 km/h"),
              _infoRow("State duration", "35 days 20 h 47 min"),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -8),
          child: Icon(Icons.arrow_drop_down, size: 24, color: Colors.green[700]),
        ),
        const SizedBox(height: 0),
        Image.asset('assets/marker.png', width: 64, height: 64), // 🔽 marker below arrow
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
