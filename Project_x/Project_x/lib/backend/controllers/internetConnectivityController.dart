import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/controllers/driverController.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oil_connect/backend/controllers/orderController.dart';
import 'package:oil_connect/backend/controllers/stationController.dart';
import '../controllers/authController.dart';

class ConnectivityController extends GetxController {
  final RegisterController userController = Get.find();
  final Connectivity _connectivity = Connectivity();
  final OrderController orderController = Get.find();
  final StationController stationController = Get.find();
  final DriverOrderController driverOrderController = Get.find();

  RxBool isOffline = false.obs;
  StreamSubscription<ConnectivityResult>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _loadOfflineState();
    _checkConnectivity(); // Initial check on launch
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _loadOfflineState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool wasOffline = prefs.getBool("isOffline") ?? false;

    if (wasOffline) {
      isOffline.value = true;
      Future.delayed(const Duration(seconds: 1), _showOfflineMessage);
    }
  }

  Future<void> _checkConnectivity() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();

    if (result != ConnectivityResult.none) {
      try {
        // Ping Google to test actual internet access
        final lookupResult = await InternetAddress.lookup('google.com');
        if (lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty) {
          _updateConnectionStatus(result);
          return;
        }
      } catch (_) {
        _updateConnectionStatus(ConnectivityResult.none);
        return;
      }
    }

    // If connectivity is none or DNS lookup fails
    _updateConnectionStatus(ConnectivityResult.none);
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) async {
    final bool hasInternet = await _hasInternetAccess();

    if (!hasInternet) {
      if (!isOffline.value) {
        isOffline.value = true;
        _showOfflineMessage(); // Show snackbar
      }
      return; // 🔒 Do not proceed if no internet
    }

    // ✅ At this point, real internet is available
    if (isOffline.value) {
      isOffline.value = false;
      Get.closeAllSnackbars(); // Hide offline message
    }

    // ✅ Refresh app data only if internet is back
    // Use addPostFrameCallback to ensure this runs after the current build cycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        userController.fetchUserDetails();
        orderController.fetchOrders();
        stationController.getAllStations();
        driverOrderController.fetchAssignedOrders();
        Get.forceAppUpdate();
      });
    });
  }

  void _showOfflineMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.context != null && !Get.isSnackbarOpen) {
        Get.snackbar(
          "No Internet Connection",
          "Check your internet connection",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(10),
          isDismissible: false,
          duration: const Duration(days: 365),
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          borderRadius: 8,
        );
      }
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
