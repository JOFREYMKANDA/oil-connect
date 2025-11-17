import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/controllers/stationController.dart';
import 'package:oil_connect/backend/models/station_model.dart';
import 'package:oil_connect/screens/customer%20screens/station_registration.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/AppBar.dart';

class RegisteredStationsScreen extends StatelessWidget {
  final StationController stationController = Get.put(StationController());
  final RxString searchQuery = ''.obs;

  RegisteredStationsScreen({super.key});

  List<Station> get filteredStations {
    if (searchQuery.isEmpty) {
      return stationController.stations;
    }
    
    final query = searchQuery.toLowerCase();
    return stationController.stations.where((station) {
      return station.stationName.toLowerCase().contains(query) ||
          station.label.toLowerCase().contains(query) ||
          station.region.toLowerCase().contains(query) ||
          station.district.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BackAppBar(
        title: 'Stations',
        actions: [
          TextButton(
            onPressed: _navigateToRegistration,
            child:const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add, // or any other icon you prefer
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: 8), // spacing between icon and text
                Text(
                  'Add New Station',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ]
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: Obx(() {
                // Debug print
                if (stationController.stations.isNotEmpty) {
                  print("Fetched Stations (JSON Format):");
                  for (var s in stationController.stations) {
                    print(s.toJson());
                  }
                } else {
                  print("No stations found.");
                }
        
                if (stationController.stations.isEmpty) {
                  return _buildEmptyState();
                }
                
                if (filteredStations.isEmpty) {
                  return _buildNoResultsState();
                }
                
                return _buildStationsList();
              }),
            ),
          ],
        ),
      ),
      // floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => TextField(
        onChanged: (value) => searchQuery.value = value,
        decoration: InputDecoration(
          hintText: "Search by name, label, region, or district...",
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          fillColor:const Color(0XFFFAFAFA),
          filled: true,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade500,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () {
                    searchQuery.value = '';
                  },
                )
              : null,
          
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      )),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_gas_station_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              "No Stations Added",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Get started by adding your first fuel station to manage its operations",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _navigateToRegistration(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Add First Station",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              "No Stations Found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Try searching with different keywords",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => Text(
              "Search query: \"${searchQuery.value}\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStationsList() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Obx(() => Row(
              children: [
                Text(
                  "${filteredStations.length} ${filteredStations.length == 1 ? 'Station' : 'Stations'}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            )),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filteredStations.length,
              itemBuilder: (context, index) {
                final station = filteredStations[index];
                return _buildStationCard(station, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(Station station, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 0,
        color:const Color(0xfffafafa),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:const Color(0xfff5f5f5)
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  '${station.label} - ${station.stationName} ',
                  style:const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600
                  ),
                ),
            
                const SizedBox(height: 10),

                Text(
                  '${station.region}, ${station.district} ',
                  style:const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black38
                  ),
                )
            
              
              ],
            ),
          ),
        ),
      ),
    );
  }

 
  void _navigateToRegistration() async {
    final newStation = await Get.to(() => const StationRegistration());
    if (newStation != null && newStation is Station) {
      stationController.stations.add(newStation);
    }
  }
}