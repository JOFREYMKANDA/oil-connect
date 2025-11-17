import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:oil_connect/backend/controllers/sharedOrderController.dart';
import 'package:oil_connect/screens/customer%20screens/registered_station.dart';
import 'package:oil_connect/screens/customer%20screens/route_selection.dart';
import 'package:oil_connect/screens/customer%20screens/place_order_screen.dart';
import 'package:oil_connect/widget/bottom_navigation.dart';
import 'package:oil_connect/backend/controllers/gpsController.dart';
import 'package:oil_connect/backend/controllers/truckLocationController.dart';
import 'package:oil_connect/widget/cost_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/backend/controllers/orderController.dart';
import 'package:oil_connect/backend/controllers/settingController.dart';
import 'package:oil_connect/backend/controllers/stationController.dart';
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/backend/models/station_model.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/drawer_widget.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  late GoogleMapController _mapController;
  LatLng _currentPosition = const LatLng(-6.7924, 39.2083);
  String _currentAddress = "Fetching location...";
  final RegisterController userController = Get.put(RegisterController());
  final OrderController orderController = Get.put(OrderController());
  final SettingsController settingsController = Get.put(SettingsController());
  final StationController stationController = Get.put(StationController());
  final GpsController gpsController = Get.put(GpsController());
  final SharedOrderController sharedController =
      Get.put(SharedOrderController());
  final TruckLocationController truckLocationController =
      Get.put(TruckLocationController());

  Order? pendingOrder;
  Station? selectedStation;
  bool isProcessing = false;
  bool _isMapReady = false;

  Future<bool> _ensureLocationPermission() async {
    LocationPermission status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    if (status == LocationPermission.deniedForever) {
      setState(() {
        _currentAddress = "Location permission denied - open Settings";
      });
      await openAppSettings();
      return false;
    }
    if (status == LocationPermission.denied) {
      setState(() {
        _currentAddress = "Location permission denied";
      });
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    orderController.fetchOrders();
    stationController.getAllStations();
    truckLocationController.fetchAvailableTrucks();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final granted = await _ensureLocationPermission();
      if (!granted) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = "Enable Location Services";
        });
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        setState(() {
          _currentAddress = "No location available";
        });
        return;
      }

      String displayAddress = "";
      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          displayAddress = "${p.street ?? ''}, ${p.locality ?? ''}"
              .trim()
              .replaceAll(RegExp(r'^,\s*'), '');
        }
      } catch (_) {}

      final target = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = target;
        _currentAddress =
            displayAddress.isNotEmpty ? displayAddress : "Location updated";
      });

      if (_isMapReady) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15.0),
        ));
      }
    } catch (_) {
      setState(() {
        _currentAddress = "Unable to fetch location";
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    final granted = await _ensureLocationPermission();
    if (!granted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final target = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = target;
      });
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15.0),
      ));
    } catch (_) {}
  }

  Widget _buildDashboardPanel() {
    return Obx(() {
      final totalOrders = orderController.orders.length;
      final totalStations = stationController.stations.length;
      
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                children: [
                  // Left side title
                  const Text(
                    "Current location",
                    style: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w500
                      ),
                  ),

                  // Right side value, flexible so it can wrap or shrink
                  Flexible(
                    child: Text(
                      _currentAddress,
                      textAlign: TextAlign.right,
                      softWrap: true, // wrap text if it's too long
                      overflow: TextOverflow.ellipsis,
                      style:const TextStyle(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w600
                        ) // optional, truncate if needed
                    ),
                  ),
                ],
              ),
             
            const SizedBox(height: 10),
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                children: [
                  // Left side title
                  const Text(
                    "Total orders",
                    style: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w500
                      ),
                  ),

                  // Right side value, flexible so it can wrap or shrink
                  Flexible(
                    child: Text(
                      totalOrders.toString(),
                      textAlign: TextAlign.right,
                      softWrap: true, // wrap text if it's too long
                      overflow: TextOverflow.ellipsis,
                      style:const TextStyle(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w600
                        ) // optional, truncate if needed
                    ),
                  ),
                ],
              ),
             
            const SizedBox(height: 10),
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // top-align text
                children: [
                  // Left side title
                  const Text(
                    "Total stations",
                    style: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w500
                      ),
                  ),

                  // Right side value, flexible so it can wrap or shrink
                  Flexible(
                    child: Text(
                      totalStations.toString(),
                      textAlign: TextAlign.right,
                      softWrap: true, // wrap text if it's too long
                      overflow: TextOverflow.ellipsis,
                      style:const TextStyle(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w600
                        ) // optional, truncate if needed
                    ),
                  ),
                ],
              ),
             
            const SizedBox(height: 14),
             _buildActionButton(
                onPressed: () {
                  Get.to(() => const PlaceOrderScreen());
                },
                icon: Icons.add,
                label: "Add New Order",
                backgroundColor: AppColors.primaryColor,
                textColor: Colors.white,
              ),
              
            const SizedBox(height: 8),
            _buildActionButton(
                onPressed: () {
                  // Navigate to stations page
                  Get.to(() => RegisteredStationsScreen());
                },
                icon: Icons.explore,
                label: "Explore Stations",
                backgroundColor: Colors.grey[100]!,
                textColor: Colors.black87,
              ),
            
          ],
        ),
      );
    });
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Obx(() => GoogleMap(
                mapType: settingsController.mapType.value,
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 15.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _isMapReady = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _getCurrentLocation();
                  });
                },
                myLocationEnabled: true,
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                markers: {
                  ...gpsController.markers,
                  ...truckLocationController.truckMarkers
                },
              )),

                        // Custom My Location button
          Positioned(
            right: 16,
            bottom: 200, // Adjusted to be above the dashboard panel
            child: SafeArea(
              child: Material(
                color: Colors.white,
                elevation: 8,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _goToCurrentLocation,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration:const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child:const Icon(
                      Icons.my_location,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Dashboard Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildDashboardPanel(),
          ),


        ],
      ),
    );
  }
}