import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:oil_connect/backend/controllers/settingController.dart';
import 'package:oil_connect/backend/controllers/stationController.dart';
import 'package:oil_connect/backend/models/station_model.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/utils/constants.dart';
import 'package:oil_connect/widget/AppBar.dart';

class StationRegistration extends StatefulWidget {
  const StationRegistration({super.key});

  @override
  State<StationRegistration> createState() => _StationRegistrationState();
}

class _StationRegistrationState extends State<StationRegistration> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final StationController controllers = Get.put(StationController());
  final SettingsController settingsController = Get.put(SettingsController());

  // ✅ Rx variables for custom message container
  final RxBool _showMessage = false.obs;
  final RxBool _isSuccess = false.obs;
  final RxString _messageText = "".obs;

  List<dynamic> _suggestions = [];
  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;

  final String _apiKey = AppConstants.kGoogleApiKey;
  String? _stationName;
  String? _region;
  String? _district;
  double? _latitude;
  double? _longitude;

  final RxBool _showRegisterButton = false.obs;
  final RxBool _isProcessing = false.obs;

  @override
  void initState() {
    super.initState();

    // Hide suggestions when typing in label
    _labelController.addListener(() {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions.clear());
      }
      _updateRegisterButtonVisibility();
    });

    // Update register button when search field changes
    _searchController.addListener(() {
      _updateRegisterButtonVisibility();
    });
  }

  void _updateRegisterButtonVisibility() {
    // Show register button only if both fields have values
    if (_stationName != null &&
        _stationName!.isNotEmpty &&
        _labelController.text.trim().isNotEmpty) {
      _showRegisterButton.value = true;
    } else {
      _showRegisterButton.value = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  // 🔍 Search for stations
  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      _suggestions.clear();
      _updateRegisterButtonVisibility();
      setState(() {});
      return;
    }

    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_apiKey&types=establishment&components=country:tz&radius=50000&keyword=oil|gas";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = data['predictions'];
          });
        }
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
    }
  }

  // 🔍 Get station details
  void _onSuggestionTap(String placeId) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['result']['geometry']['location'];
        final name = data['result']['name'];
        final addressComponents = data['result']['address_components'];

        String? region;
        String? district;

        for (var component in addressComponents) {
          if (component['types'].contains('administrative_area_level_1')) {
            region = component['long_name'];
          } else if (component['types'].contains('administrative_area_level_2') ||
              component['types'].contains('locality') ||
              component['types'].contains('sublocality_level_1')) {
            district = component['long_name'];
          }
        }

        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: LatLng(location['lat'], location['lng']),
            infoWindow: InfoWindow(title: name),
          ),
        );

        _stationName = name;
        _region = region;
        _district = district;
        _latitude = location['lat'];
        _longitude = location['lng'];
        _searchController.text = name;
        _suggestions.clear();

        _updateRegisterButtonVisibility();

        // Zoom to marker
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(location['lat'], location['lng']),
              zoom: 16.0,
            ),
          ),
        );
      }
    } catch (e) {
      _isSuccess.value = false;
      _messageText.value = "Failed to fetch place details.";
      _showMessage.value = true;
    }
  }

  // ✅ Register station
  void _onRegisterButtonPressed() async {
    // Hide suggestions
    if (_suggestions.isNotEmpty) _suggestions.clear();

    if (_labelController.text.isEmpty) {
      _isSuccess.value = false;
      _messageText.value = "Please enter a station label.";
      _showMessage.value = true;
      return;
    }

    if (_region != null &&
        _district != null &&
        _latitude != null &&
        _longitude != null) {
      _isProcessing.value = true;
      _showMessage.value = false;

      final station = Station(
        stationName: _stationName!,
        region: _region!,
        district: _district!,
        latitude: _latitude!,
        longitude: _longitude!,
        label: _labelController.text.trim(),
      );

      // Pass Rx variables to controller
      await controllers.registerStation(
        station,
        _showMessage,
        _isSuccess,
        _messageText,
      );

      _isProcessing.value = false;
    } else {
      _isSuccess.value = false;
      _messageText.value =
          "Please complete all station details before registering.";
      _showMessage.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackAppBar(title: 'Station Registration'),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition:
                const CameraPosition(target: LatLng(-6.7924, 39.2083), zoom: 14.0),
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            onTap: (_) => setState(() => _suggestions.clear()),
          ),

          // Inputs and message
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildInputField(
                    controller: _searchController,
                    hintText: AppConstants.searchStation,
                    icon: Icons.search,
                    onChanged: _onSearchChanged),
                const SizedBox(height: 8),
                _buildInputField(
                    controller: _labelController,
                    hintText: "Station Name (e.g. Total Njiro)",
                    icon: Icons.label),
                const SizedBox(height: 8),
                _suggestions.isNotEmpty ? _buildSuggestionsList() : const SizedBox.shrink(),
                const SizedBox(height: 8),
                Obx(() =>
                    _showMessage.value ? _buildMessageContainer() : const SizedBox.shrink()),
              ],
            ),
          ),

          // Register button
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Obx(() {
              if (_isProcessing.value) {
                return Center(
                  child: CircularProgressIndicator(color: Colors.green.shade900),
                );
              }
              return _showRegisterButton.value
                  ? ElevatedButton(
                      onPressed: _onRegisterButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rectangleColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Register Station",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : const SizedBox.shrink();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xfffafafa),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xfff5f5f5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xfff5f5f5), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xfff5f5f5)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            title: Text(suggestion['description']),
            onTap: () => _onSuggestionTap(suggestion['place_id']),
          );
        },
      ),
    );
  }

  Widget _buildMessageContainer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isSuccess.value ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSuccess.value ? Colors.green.shade700 : Colors.red.shade700,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isSuccess.value ? Icons.check_circle : Icons.error,
            color: _isSuccess.value ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _messageText.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            onPressed: () {
              _showMessage.value = false;
            },
          ),
        ],
      ),
    );
  }
}
