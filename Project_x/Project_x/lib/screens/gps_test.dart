import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class FullMapScreen extends StatefulWidget {
  const FullMapScreen({super.key});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  late GoogleMapController _mapController;
  final LatLng _initialPosition = const LatLng(-6.7924, 39.2083);
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  final List<LatLng> _polylineCoordinates = [];
  final Set<Polyline> _polylines = {};
  late IO.Socket socket;
  bool showDetailsPanel = false;
  String _locationName = "Unknown Location";
  Map<String, dynamic>? _latestData;
  final String googleApiKey = 'AIzaSyCnP_z4vJmcEiJtx-TsPFknXU7G5HRCiE0';

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  void _connectToSocket() {
    socket = IO.io('ws://161.35.225.205:6000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      debugPrint('✅ Connected to GPS WebSocket');
    });

    socket.on('gps-data', (data) async {
      debugPrint("📡 Incoming GPS data: $data");

      double lat = data['latitude'] ?? _initialPosition.latitude;
      double lng = data['longitude'] ?? _initialPosition.longitude;
      double speed = data['speed']?.toDouble() ?? 0.0;

      _latestData = data;
      LatLng newPoint = LatLng(lat, lng);

      // Reverse geocode
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          _locationName = "${place.street ?? ''}, ${place.locality ?? ''}".trim();
        }
      } catch (_) {
        _locationName = "Unknown Location";
      }

      // Draw polyline only if moving and position changed
      if (speed > 0 && _currentPosition != null && hasMoved(_currentPosition!, newPoint)) {
        List<LatLng> routePoints = await _getRouteFromAPI(_currentPosition!, newPoint);

        if (routePoints.isNotEmpty) {
          _polylineCoordinates.addAll(routePoints);
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _polylineCoordinates,
              color: Colors.blue,
              width: 4,
            ),
          );
        }
      }

      _currentPosition = newPoint;

      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('vehicle'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Tap for details'),
          onTap: () {
            setState(() {
              showDetailsPanel = true;
            });
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      setState(() {});
      _mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    });

    socket.onDisconnect((_) => debugPrint('❌ Disconnected from GPS WebSocket'));
  }

  bool hasMoved(LatLng a, LatLng b, {double threshold = 0.0001}) {
    return (a.latitude - b.latitude).abs() > threshold ||
        (a.longitude - b.longitude).abs() > threshold;
  }

  Future<List<LatLng>> _getRouteFromAPI(LatLng from, LatLng to) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${from.latitude},${from.longitude}&destination=${to.latitude},${to.longitude}&key=$googleApiKey&mode=driving';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final points = decoded['routes'][0]['overview_polyline']['points'];

      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> result = polylinePoints.decodePolyline(points);

      return result.map((point) => LatLng(point.latitude, point.longitude)).toList();
    } else {
      return [];
    }
  }

  String _formatLocalTime(String? utcTime) {
    if (utcTime == null || utcTime.isEmpty || utcTime.startsWith('0000')) {
      return 'Invalid Time';
    }
    try {
      final dateTimeUtc = DateTime.parse(utcTime);
      final localTime = dateTimeUtc.toLocal();
      if (localTime.year < 2010) return 'Invalid Time';
      return DateFormat('dd MMM yyyy, hh:mm a').format(localTime);
    } catch (e) {
      return 'Invalid Time';
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildLivePanel() {
    if (!showDetailsPanel || _latestData == null || _currentPosition == null) {
      return const SizedBox.shrink();
    }

    String imei = _latestData!['imei'] ?? 'Unknown';
    String ignition = _latestData!['ignition'] ?? 'Unknown';
    double speed = _latestData!['speed']?.toDouble() ?? 0.0;
    String timestamp = _formatLocalTime(_latestData!['timestamp']);
    String coords = "${_currentPosition!.latitude.toStringAsFixed(7)}, ${_currentPosition!.longitude.toStringAsFixed(7)}";

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 30, color: Colors.green),
            Text(
              _locationName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.confirmation_number, 'IMEI', imei),
            _infoRow(Icons.speed, 'Speed', '$speed km/h'),
            _infoRow(Icons.power_settings_new, 'Ignition', ignition),
            _infoRow(Icons.access_time, 'Timestamp', timestamp),
            _infoRow(Icons.pin_drop, 'Coordinates', coords),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => setState(() => showDetailsPanel = false),
              icon: const Icon(Icons.keyboard_arrow_down),
              label: const Text('Hide Details'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade900),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS View'),
        backgroundColor: Colors.green.shade900,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14.0),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),
          _buildLivePanel(),
        ],
      ),
    );
  }
}
