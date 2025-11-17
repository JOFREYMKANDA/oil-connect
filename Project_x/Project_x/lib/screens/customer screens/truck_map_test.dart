import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oil_connect/backend/controllers/truckLocationController.dart';
import 'package:oil_connect/backend/models/truck_location_model.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/truck_info_widget.dart';

class TruckMapTestScreen extends StatefulWidget {
  const TruckMapTestScreen({super.key});

  @override
  State<TruckMapTestScreen> createState() => _TruckMapTestScreenState();
}

class _TruckMapTestScreenState extends State<TruckMapTestScreen> {
  final TruckLocationController truckController = Get.put(TruckLocationController());
  
  TruckLocation? selectedTruck;

  @override
  void initState() {
    super.initState();
    truckController.fetchAvailableTrucks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.rectangleColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.shapeColor),
        centerTitle: true,
        title: const Text(
          "Truck Locations",
          style: TextStyle(color: AppColors.shapeColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.shapeColor),
            onPressed: () => truckController.refreshTrucks(),
          ),
        ],
      ),
      body: Obx(() {
        if (truckController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (truckController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${truckController.errorMessage.value}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => truckController.fetchAvailableTrucks(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) {},
              initialCameraPosition: const CameraPosition(
                target: LatLng(-6.7924, 39.2083), // Dar es Salaam
                zoom: 10,
              ),
              markers: truckController.truckMarkers,
              onTap: (position) {
                setState(() {
                  selectedTruck = null;
                });
              },
            ),
            
            // Truck info panel
            if (selectedTruck != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: TruckInfoWidget(truck: selectedTruck!),
              ),
            
            // Truck count panel
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Truck Status Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...truckController.getTruckCountByStatus().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: entry.key == 'Available' 
                                    ? Colors.green 
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
