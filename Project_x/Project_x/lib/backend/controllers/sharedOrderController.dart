import 'package:get/get.dart';// fixed import
import 'package:oil_connect/backend/services/sharedRouteService.dart';
import '../models/order_model.dart';

class SharedOrderController extends GetxController {
  final SharedOrderService _sharedOrderService = SharedOrderService();
  var isLoading = false.obs;
  RxList<Order> sharedOrders = <Order>[].obs;
  RxList<Order> searchResults = <Order>[].obs;

  /// ✅ Search for matching shared orders (does not place)
  Future<bool> searchForMatch(Order order) async {
    try {
      return await _sharedOrderService.searchForSharedMatch(order);
    } catch (e) {
      print("❌ Error in controller during match search: $e");
      return false;
    }
  }

  /// ✅ Place a Shared Order
  Future<bool> placeSharedOrder(Order order) async {
    isLoading.value = true;

    try {
      print("Placing shared order:");
      print("Fuel Type: ${order.fuelType}");
      print("Volume: ${order.capacity}");
      print("Source: ${order.source}");
      print("Station Name: ${order.stationName}");
      print("Depot: ${order.depot}");
      print("Company Name: ${order.companyName}");
      print("Price: ${order.price}");

      final result = await _sharedOrderService.placeSharedOrder(order);

      if (result['success'] == true) {
        print("Shared order placed successfully!");
        // Get.snackbar("Success", "Shared order placed successfully!");
        return true;
      } else {
        String errorMessage = result['message'] ?? "Failed to place shared order";
        if (result['suggestion'] != null) {
          errorMessage += "\nSuggestion: ${result['suggestion']}";
        }
        print("❌ $errorMessage");
        Get.snackbar("Error", errorMessage);
        return false;
      }
    } catch (e) {
      print("Error placing shared order: $e");
      Get.snackbar("Error", "An error occurred: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔎 Find shared orders (waiting customers) near a region
  Future<void> searchSharedByRegion(String region) async {
    isLoading.value = true;
    try {
      final results = await _sharedOrderService.findSharedOrders(region: region);
      searchResults.assignAll(results);
    } catch (e) {
      searchResults.clear();
      print("Error fetching shared orders: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
