import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GpsController extends GetxController {
  final LatLng initialPosition = const LatLng(-6.7924, 39.2083);
  LatLng? currentPosition;

  final Set<Marker> markers = {};
  IO.Socket? socket;
  BitmapDescriptor? blueDotIcon;

  Map<String, dynamic>? latestData;
  String? locationName;

  Function(LatLng)? onNewPosition;

  @override
  void onInit() {
    super.onInit();
    loadBlueDotIcon();
    connectToSocket();
  }

  Future<void> loadBlueDotIcon() async {
    try {
      blueDotIcon = await loadImageMarker('assets/marker.png', 64);
      update();
    } catch (e) {
      debugPrint('Failed to load marker icon: $e');
      blueDotIcon = null;
    }
  }

  Future<BitmapDescriptor> loadImageMarker(String path, int targetWidth) async {
    final ByteData data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: targetWidth);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> connectToSocket() async {
    await SharedPrefsUtil().init();
    final role = SharedPrefsUtil().getRole();
    final userId = SharedPrefsUtil().getUserId();

    if (role == null || userId == null || userId.isEmpty){
      debugPrint('Socket not initialized: missing role or userId');
     return;
    }
    String headerKey, event;
    switch (role.toLowerCase()) {
      case 'truckowner':
        headerKey = 'x-truckowner-id';
        event = 'truckowner-gps';
        break;
      case 'driver':
        headerKey = 'x-driver-id';
        event = 'driver-gps';
        break;
      case 'customer':
        headerKey = 'x-customer-id';
        event = 'customer-gps';
        break;
      default:
        debugPrint('Unrecognized role: $role');
        return;
    }

    // create socket and assign to nullable field
    socket = IO.io(
      'ws://161.35.225.205:7000',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'extraHeaders': {headerKey: userId},
      },
    );

    // register handlers safely, socket is non-null here
    socket?.onConnect((_) {
      debugPrint("✅ Connected to GPS WebSocket");
    });

    socket?.on(event, (data) async {
      if (data == null) return;

      double lat = (data['latitude'] is num) ? (data['latitude'] as num).toDouble() : initialPosition.latitude;
      double lng = (data['longitude'] is num) ? (data['longitude'] as num).toDouble() : initialPosition.longitude;

      currentPosition = LatLng(lat, lng);
      latestData = Map<String, dynamic>.from(data);

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          locationName = placemarks.first.locality ?? placemarks.first.name ?? 'Unknown';
        } else {
          locationName = 'Unknown';
        }
      } catch (e) {
        debugPrint('Geocoding failed: $e');
        locationName = 'Unknown';
      }

      // use fallback icon if blueDotIcon is not ready
      final iconToUse = blueDotIcon ?? BitmapDescriptor.defaultMarker;

      markers
        ..clear()
        ..add(Marker(
          markerId: const MarkerId('vehicle'),
          position: currentPosition!,
          icon: iconToUse,
          anchor: const Offset(0.5, 0.5),
        ));

      if (onNewPosition != null) {
        onNewPosition!(currentPosition!);
      }

      update();
    });

    socket?.onDisconnect((_) => debugPrint("❌ GPS WebSocket disconnected"));
    socket?.onError((e) => debugPrint("❌ Socket error: $e"));
    socket?.onConnectError((err) => debugPrint("❌ Connect error: $err"));
  }

  @override
  void onClose() {
    // guard socket disposal — only call if it exists
    try{
      socket?.disconnect();
      socket?.dispose();
      socket = null;
      super.onClose();
    } catch (e) {
      debugPrint('Error while disposing socket: $e');
    }
    super.onClose();
  }
}
