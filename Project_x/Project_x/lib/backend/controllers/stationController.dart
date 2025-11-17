import 'dart:convert';
import 'package:get/get.dart';
import 'package:oil_connect/widget/bottom_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station_model.dart';
import '../services/stationService.dart';

class StationController extends GetxController {
  final StationService _service = StationService();
  var stations = <Station>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getAllStations(); // ✅ Load on controller init
  }

  Future<void> registerStation(
    Station station,
    RxBool showMessage,
    RxBool isSuccess,
    RxString messageText,
  ) async {
    isLoading.value = true;
    showMessage.value = false; // reset previous message

    try {
      final success = await _service.registerStation(station);

      if (success) {
        await getAllStations();

        // ✅ Success
        isSuccess.value = true;
        messageText.value = "${station.stationName} registered successfully!";
        showMessage.value = true;

        // ✅ Auto-hide after 4 seconds & redirect
        Future.delayed(const Duration(seconds: 4), () {
          showMessage.value = false;
          Get.offAll(() => const RoleBasedBottomNavScreen(role: 'Customer'));
        });
      } else {
        // ❌ Failed
        isSuccess.value = false;
        messageText.value =
            "Unable to register station. Please check your information and try again.";
        showMessage.value = true;
      }
    } catch (e) {
      // ❌ Connection error
      isSuccess.value = false;
      messageText.value =
          "Unable to connect to the server. Please check your internet connection.";
      showMessage.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  // Your getAllStations() function stays the same

  Future<void> getAllStations() async {
    isLoading.value = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // ✅ Load cached stations FIRST
      String? cachedStations = prefs.getString("saved_stations");
      if (cachedStations != null && cachedStations.isNotEmpty) {
        final cachedList = List<Station>.from(
            json.decode(cachedStations).map((x) => Station.fromJson(x)));
        stations
            .assignAll(cachedList); // This immediately shows cached stations
      }

      // ✅ THEN try fetching fresh data
      final fetchedStations = await _service.fetchStations();
      if (fetchedStations.isNotEmpty) {
        stations.value = fetchedStations;
        await prefs.setString("saved_stations", json.encode(fetchedStations));
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
