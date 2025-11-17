import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/services/customerServices.dart';
import '../models/depot_model.dart';
import '../models/station_model.dart';

class CustomerController extends GetxController {
  final CustomerService _customerService = CustomerService();

  var depots = <Depot>[].obs;
  var customerStations = <Station>[].obs;
  var isLoading = false.obs;
  var isStationsLoading = false.obs;


  /// **Fetch Depots from API**
  Future<void> fetchDepots() async {
    try {
      isLoading.value = true;
      final depotList = await _customerService.fetchDepots();
      depots.value = depotList;
    } finally {
      isLoading.value = false;
    }
  }

  /// **Fetch Customer Stations from API**
  Future<void> fetchCustomerStations() async {
    try {
      isStationsLoading.value = true;
      final stationList = await _customerService.fetchCustomerStations();
      customerStations.value = stationList;

      // If no stations found, don't show error - this is normal for new customers
      if (stationList.isEmpty) {
        print("No stations found for customer - this is normal for new customers");
      }
    } catch (e) {
      print("Error fetching customer stations: $e");
      // Only show error for actual errors, not for empty results
      if (!e.toString().contains("404") && !e.toString().contains("No stations found")) {
        Get.snackbar(
          "Error",
          "Failed to fetch stations: $e",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isStationsLoading.value = false;
    }
  }
}
