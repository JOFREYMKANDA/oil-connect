import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/services/registerDriverService.dart';
import '../../utils/shared_pref_utils.dart';
import '../models/driver_model.dart';
import '../models/user_model.dart';

class DriverRegistrationController extends GetxController {
  final DriverRegistrationService _service = DriverRegistrationService();
  var isLoading = false.obs;
  var drivers = <Driver>[].obs;
  var searchText = ''.obs; // Observable for search functionality

  Future<bool> registerDriver(User user) async {
    isLoading.value = true;
    try {
      final token = SharedPrefsUtil().getToken();
      if (token == null) {
        Get.snackbar('', 'Token not found. Please log in again.');
        return false;
      }

      bool isRegistered = await _service.registerDriver(user, token);
      if (isRegistered) {
        // Defer fetchDrivers to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          fetchDrivers();
        });
        return true;
      }
      return false;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.toLowerCase().contains("already registered")) {
        Get.snackbar('User Exists', errorMessage, backgroundColor: Colors.orange, colorText: Colors.white);
      } else {
        //Get.snackbar('Error', errorMessage);
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDrivers() async {
    isLoading.value = true;
    try {
      final token = SharedPrefsUtil().getToken();
      if (token != null) {
        final fetchedDrivers = await _service.fetchDrivers(token);

        if (fetchedDrivers.isNotEmpty) {
          drivers.assignAll(fetchedDrivers);
        } else {
          Get.snackbar('Notice', 'No drivers found.');
        }
      } else {
        throw Exception('Token not found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch drivers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateDriver(String driverId, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final token = SharedPrefsUtil().getToken();
      if (token != null) {
        final isUpdated =
        await DriverRegistrationService.updateDriver(token, driverId, data);
        if (isUpdated) {
          // Defer fetchDrivers to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            fetchDrivers();
          });
          //Get.snackbar('', 'Driver updated successfully.');
          return true;
        } else {
          //Get.snackbar('', 'Failed to update the driver. Please try again.');
          return false;
        }
      } else {
        Get.snackbar('Error', 'Token not found. Please log in again.');
        return false;
      }
    } catch (e) {
      //Get.snackbar('Error', 'An error occurred while updating the driver: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDriver(String driverId) async {
    final token = SharedPrefsUtil().getToken();

    if (token == null) {
      Get.snackbar('', 'Token not found. Please log in again.');
      return;
    }

    try {
      final isDeleted =
      await DriverRegistrationService.deleteDriver(driverId, token);
      if (isDeleted) {
        Get.snackbar('', 'Driver deleted successfully.');
        // Defer fetchDrivers to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          fetchDrivers();
        });
        Get.back();
      } else {
        Get.snackbar('', 'Failed to delete driver.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // Filtered drivers based on the search text
  List<Driver> get filteredDrivers {
    if (searchText.value.isEmpty) {
      return drivers;
    } else {
      return drivers
          .where((driver) =>
      driver.firstname.toLowerCase().contains(searchText.value.toLowerCase()) ||
          driver.lastname.toLowerCase().contains(searchText.value.toLowerCase()))
          .toList();
    }
  }
}
