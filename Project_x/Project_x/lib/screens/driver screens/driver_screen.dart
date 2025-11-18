import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:oil_connect/backend/controllers/driverController.dart';
import 'package:oil_connect/backend/controllers/gpsController.dart';
import 'package:oil_connect/utils/constants.dart';
import 'package:oil_connect/widget/drawer_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../backend/controllers/authController.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final RegisterController userController = Get.put(RegisterController());
  final DriverOrderController orderController =
      Get.put(DriverOrderController());
  final GpsController gpsController = Get.put(GpsController());

  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  String? _lastDrawnOrderId;
  bool _isMapReady = false;
  bool _isDetailsExpanded = false;
  bool isCompleting = false; // controls loading state

  double _getContainerHeight() {
    return _isDetailsExpanded ? MediaQuery.of(context).size.height * 0.6 : 120;
  }

  @override
  void initState() {
    super.initState();

    ever(orderController.assignedOrders, (_) async {
      print("🚀 Assigned orders changed — checking map update");

      if (orderController.assignedOrders.isEmpty) return;

      final currentOrder = orderController.assignedOrders.first;

      // ✅ Avoid redrawing same order again
      if (currentOrder.status.toLowerCase() == "completed") {
        print("✅ Order completed — clearing map and state");
        setState(() {
          _markers.clear();
          _polylines.clear();
          _lastDrawnOrderId = null;
        });
        return;
      }

      if (_lastDrawnOrderId == currentOrder.orderId) {
        print("⏭️ Same order as last drawn — skipping redraw");
        return;
      }

      _lastDrawnOrderId = currentOrder.orderId; // ✅ Cache latest drawn orderId

      try {
        // ⏬ Redraw logic as before
        final depotLat = currentOrder.depotLat;
        final depotLng = currentOrder.depotLng;

        LatLng? depotPoint;
        if (depotLat != null && depotLng != null) {
          depotPoint = LatLng(depotLat, depotLng);
        } else {
          final depotName = currentOrder.depot.toLowerCase();
          if (depotName.contains("mtwara")) {
            depotPoint = const LatLng(-10.2659, 40.1898);
          } else if (depotName.contains("dar")) {
            depotPoint = const LatLng(-6.7924, 39.2083);
          } else if (depotName.contains("kurasini")) {
            depotPoint = const LatLng(-6.8516, 39.2945);
          }
        }

        if (depotPoint == null) {
          print("❌ No depot coordinates available");
          return;
        }

        final orders = currentOrder.routeWay == "shared"
            ? orderController.getGroupOrders(currentOrder.sharedGroupId)
            : [currentOrder];

        orders.sort((a, b) => (a.createdDate ?? DateTime.now())
            .compareTo(b.createdDate ?? DateTime.now()));

        final List<LatLng> routePoints = [depotPoint];
        for (final o in orders) {
          if (o.stationLat != null && o.stationLng != null) {
            final dest = LatLng(o.stationLat!, o.stationLng!);
            routePoints.add(dest);
            print("🟡 Added destination: $dest");
          }
        }

        setState(() {
          _markers.clear();
          _polylines.clear();
        });

        _addDepotMarker(depotPoint);
        for (int i = 1; i < routePoints.length; i++) {
          _addStationMarker(routePoints[i], "Destination $i");
        }

        for (int i = 0; i < routePoints.length - 1; i++) {
          print(
              "📍 Drawing polyline from ${routePoints[i]} to ${routePoints[i + 1]}");
          await _drawPolyline(routePoints[i], routePoints[i + 1],
              label: "segment_$i");
        }
      } catch (e) {
        print("❌ Exception during route drawing: $e");
      }
    });

    gpsController.onNewPosition = (LatLng pos) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    };
  }

  void _addDepotMarker(LatLng pos) {
    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId("depot"),
        position: pos,
        infoWindow: const InfoWindow(title: "Depot"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    });
  }

  void _addStationMarker(LatLng pos, String label) {
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId("station_$label"),
        position: pos,
        infoWindow: InfoWindow(title: label),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    });
  }

  LatLngBounds _boundsFromLatLngs(LatLng origin, LatLng destination) {
    double south = origin.latitude < destination.latitude
        ? origin.latitude
        : destination.latitude;
    double west = origin.longitude < destination.longitude
        ? origin.longitude
        : destination.longitude;
    double north = origin.latitude > destination.latitude
        ? origin.latitude
        : destination.latitude;
    double east = origin.longitude > destination.longitude
        ? origin.longitude
        : destination.longitude;

    const buffer = 0.01; // Adds padding to the bounds for smooth zoom
    return LatLngBounds(
      southwest: LatLng(south - buffer, west - buffer),
      northeast: LatLng(north + buffer, east + buffer),
    );
  }

  Future<void> _drawPolyline(LatLng origin, LatLng destination,
      {String label = "route"}) async {
    const apiKey = AppConstants.kGoogleApiKey;
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey";

    print("📍 Drawing polyline from $origin to $destination");
    print("🌐 Requesting: $url");

    final response = await http.get(Uri.parse(url));
    print("📡 Directions API response: ${response.statusCode}");

    if (response.statusCode != 200) {
      print("❌ Failed to get directions: ${response.body}");
      return;
    }

    final data = jsonDecode(response.body);
    if (data['routes'] == null || (data['routes'] as List).isEmpty) {
      print("⚠️ No routes found in directions response");
      return;
    }

    final polylinePoints = data['routes'][0]['overview_polyline']['points'];
    final routeCoords = _decodePolyline(polylinePoints);
    print("✅ Decoded ${routeCoords.length} polyline points");

    final polyline = Polyline(
      polylineId: PolylineId(label),
      color: Colors.pinkAccent,
      width: 4,
      points: routeCoords,
    );

    setState(() {
      _polylines.add(polyline);
    });

    // Center camera on the route segment with optimal zoom
    if (_mapController != null) {
      // Calculate the center point between origin and destination
      final center = LatLng(
        (origin.latitude + destination.latitude) / 2,
        (origin.longitude + destination.longitude) / 2,
      );
      
      // Calculate the approximate zoom level based on distance
      final distance = _calculateDistance(origin.latitude, origin.longitude, 
                                        destination.latitude, destination.longitude);
      double zoomLevel = 12.0; // default
      
      if (distance > 100) zoomLevel = 8.0;
      else if (distance > 50) zoomLevel = 9.0;
      else if (distance > 20) zoomLevel = 10.0;
      else if (distance > 10) zoomLevel = 11.0;
      else if (distance > 5) zoomLevel = 12.0;
      else zoomLevel = 13.0;

      print("🎯 Centering camera at $center with zoom $zoomLevel (distance: ${distance.toStringAsFixed(2)} km)");
      
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: zoomLevel,
          ),
        ),
      );
    }
  }

  // Helper function to calculate distance between two points in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p)/2 + 
            cos(lat1 * p) * cos(lat2 * p) * 
            (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  void callPhoneNumber(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Get.snackbar('Error', 'Cannot place a call');
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFFAFAFA),
      body: SizedBox(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Full Screen Map
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-6.7924, 39.2083),
                    zoom: 14.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    setState(() {
                      _isMapReady = true;
                    });
                  },
                  markers: _markers.union(gpsController.markers),
                  polylines: _polylines,
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                ),
              ),

              // Draggable Order Details Container
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDetailsExpanded = !_isDetailsExpanded;
                    });
                  },
                  onVerticalDragUpdate: (details) {
                    // Optional: Add drag sensitivity if needed
                    if (details.delta.dy.abs() > 10) {
                      setState(() {
                        _isDetailsExpanded = details.delta.dy < 0;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _getContainerHeight(),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xCC1A1A1A) // Semi-transparent
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                          spreadRadius: -5,
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF0F0F0),
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: _isDetailsExpanded 
                          ? const AlwaysScrollableScrollPhysics() 
                          : const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with handle indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              children: [
                                // Drag indicator
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white30
                                          : Colors.black26,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Status header
                                Obx(() {
                                  final hasOrders =
                                      orderController.assignedOrders.isNotEmpty;
                                  final mainOrder = hasOrders
                                      ? orderController.assignedOrders.first
                                      : null;
                                  final isCompleted =
                                      mainOrder?.status.toLowerCase() ==
                                          "completed";

                                  return Row(
                                    children: [
                                      // Status text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isCompleted
                                                  ? "Delivery Completed"
                                                  : hasOrders
                                                      ? "Active Delivery"
                                                      : "No Active Orders",
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    Theme.of(context).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : const Color(0xFF1A1A1A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isCompleted
                                                  ? "Order delivered successfully"
                                                  : hasOrders
                                                      ? "ETA: ${mainOrder?.deliveryTime}"
                                                      : "Awaiting new orders",
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    Theme.of(context).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white70
                                                        : const Color(0xFF666666),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Expand/collapse icon
                                      Icon(
                                        _isDetailsExpanded
                                            ? Icons.keyboard_arrow_down_rounded
                                            : Icons.keyboard_arrow_up_rounded,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white70
                                            : const Color(0xFF666666),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),

                          // Content area (only shown when expanded)
                          if (_isDetailsExpanded)
                            Obx(() {
                              final hasOrders =
                                  orderController.assignedOrders.isNotEmpty;
                              final mainOrder = hasOrders
                                  ? orderController.assignedOrders.first
                                  : null;
                              final isCompleted =
                                  mainOrder?.status.toLowerCase() == "completed";
                              final groupOrders = (mainOrder != null &&
                                      mainOrder.routeWay == "shared")
                                  ? orderController
                                      .getGroupOrders(mainOrder.sharedGroupId)
                                  : (mainOrder != null ? [mainOrder] : []);

                              if (!hasOrders || isCompleted) {
                                return Container(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: Text(
                                    isCompleted 
                                        ? "Delivery completed successfully"
                                        : "No active orders available",
                                    style: GoogleFonts.inter(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white60
                                          : const Color(0xFF888888),
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Order route card
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF0F0F0F)
                                            : const Color(0xFFF8FAFD),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF2A2A2A)
                                              : const Color(0xFFE8ECF0),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Pick up location',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black38)),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          mainOrder != null
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('Depot',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight.bold)),
                                                        Text(mainOrder.depot),
                                                      ],
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('Source',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight.bold)),
                                                        Text(mainOrder.source),
                                                      ],
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('Company Name',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight.bold)),
                                                        Text(mainOrder.companyName),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox.shrink(),

                                          const SizedBox(
                                            height: 10,
                                          ),

                                          const Text('Delivery location(s)',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black38)),

                                          // Delivery locations
                                          ...groupOrders.asMap().entries.map((entry) {
                                            final index = entry.key;
                                            final order = entry.value;
                                            final isLast =
                                                index == groupOrders.length - 1;

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 8),
                                                Text(
                                                  "DELIVERY ${index + 1}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      "Station",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                          '${order!.populatedStations.isNotEmpty ? order!.populatedStations[0].label : 'No station'}(${order!.stationName})',
                                                          textAlign: TextAlign.right,
                                                          softWrap: true,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                              color: AppColors.textColor,
                                                              fontWeight: FontWeight
                                                                  .w600)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      "Region",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                          '${order!.populatedStations.isNotEmpty ? order!.populatedStations[0].region : 'No region'}',
                                                          textAlign: TextAlign.right,
                                                          softWrap: true,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                              color: AppColors.textColor,
                                                              fontWeight: FontWeight
                                                                  .w600)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      "District",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                          '${order!.populatedStations.isNotEmpty ? order!.populatedStations[0].district : 'No station'}',
                                                          textAlign: TextAlign.right,
                                                          softWrap: true,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                              color: AppColors.textColor,
                                                              fontWeight: FontWeight
                                                                  .w600)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                order.customerFirstName.isNotEmpty
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          const Text(
                                                            "Customer",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight.w400),
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                                '${order.customerFirstName.isNotEmpty ? order.customerFirstName : 'Customer'}',
                                                                textAlign: TextAlign.right,
                                                                softWrap: true,
                                                                overflow: TextOverflow
                                                                    .ellipsis,
                                                                style: const TextStyle(
                                                                    color: AppColors.textColor,
                                                                    fontWeight: FontWeight
                                                                        .w600)),
                                                          ),
                                                        ],
                                                      )
                                                    : const SizedBox.shrink(),
                                                if (!isLast)
                                                  Container(
                                                    margin: const EdgeInsets.only(
                                                        left: 20),
                                                    width: 2,
                                                    height: 20,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? const Color(0xFF2A2A2A)
                                                        : const Color(0xFFE8ECF0),
                                                  ),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Completed Delivery & Call Customer Buttons
                                    Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.rectangleColor,
                                            AppColors.rectangleColor.withOpacity(0.9),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: isCompleting
                                            ? null // disable while loading
                                            : () async {
                                                if (orderController.assignedOrders.isEmpty) return;
                                                final mainOrder = orderController.assignedOrders.first;

                                                setState(() => isCompleting = true);

                                                final status = mainOrder.status.toLowerCase();

                                                if (status == "assigned") {
                                                  await orderController.startDelivery(mainOrder.orderId);
                                                  // Update status locally for UI
                                                  setState(() => mainOrder.status = "ondelivery");
                                                } else if (status == "ondelivery") {
                                                  final success =
                                                      await orderController.finishDelivery(mainOrder.orderId);
                                                  if (success) {
                                                    Get.snackbar(
                                                      "Success",
                                                      "Order completed successfully!",
                                                      snackPosition: SnackPosition.BOTTOM,
                                                      backgroundColor: Colors.green,
                                                      colorText: Colors.white,
                                                      duration: const Duration(seconds: 3),
                                                    );
                                                    setState(() => mainOrder.status = "completed");
                                                  } else {
                                                    Get.snackbar(
                                                      "Error",
                                                      "Failed to complete order. Please try again.",
                                                      snackPosition: SnackPosition.BOTTOM,
                                                      backgroundColor: Colors.red,
                                                      colorText: Colors.white,
                                                      duration: const Duration(seconds: 3),
                                                    );
                                                  }
                                                }

                                                setState(() => isCompleting = false);
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: isCompleting
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    orderController.assignedOrders.isNotEmpty &&
                                                            orderController.assignedOrders.first.status.toLowerCase() == "assigned"
                                                        ? Icons.play_arrow_rounded
                                                        : Icons.check_circle_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    orderController.assignedOrders.isNotEmpty &&
                                                            orderController.assignedOrders.first.status.toLowerCase() == "assigned"
                                                        ? "Start Delivery"
                                                        : "Complete Delivery",
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Container(
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF252525)
                                              : const Color(0xFFF5F7FA),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF353535)
                                                : const Color(0xFFE8ECF0),
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _showBottomSheet(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.phone_rounded,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Call Customer(s)',
                                                style: GoogleFonts.inter(
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: const CustomerDrawer(role: ''),
    );
  }

  void _showBottomSheet(BuildContext context) {
    // Check if there are any orders
    if (orderController.assignedOrders.isEmpty) {
      Get.snackbar('No Orders', 'You have no assigned orders');
      return;
    }

    // Get the first order (assuming driver handles one order at a time)
    final order = orderController.assignedOrders.first;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
        ),
        builder: (context) {
          final isShared = order.routeWay == "shared";
          final relatedOrders = isShared
              ? orderController.getGroupOrders(order.sharedGroupId)
              : [order];

          final List<Widget> customerButtons = relatedOrders.map((o) {
            print('customers order list:${o.toJson()}');
            return _buildBottomSheetButton(
              text: "Call ${o.customerFirstName} ${o.customerLastName}",
              onTap: () {
                if (o.customerPhone.isEmpty) {
                  Get.snackbar('Error', 'Phone number not available');
                } else {
                  callPhoneNumber(o.customerPhone);
                }
              },
            );
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Reach Customer(s)",
                  style: TextStyle(fontSize:16,fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...customerButtons, // ✅ This shows all customer call buttons
              ],
            ),
          );
        });
  }

  Widget _buildBottomSheetButton(
      {required String text, required VoidCallback onTap}) {
    return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF252525)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF353535)
                : const Color(0xFFE8ECF0),
          ),
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phone_rounded,
                color: Colors.black,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ));

  }
}