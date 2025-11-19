import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/utils/api_constants.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';
import '../api/api_config.dart';

class DriverOrderController extends GetxController {
  var allRawOrders = <Order>[];
  var isLoading = false.obs;
  var assignedOrders = <Order>[].obs;
  var filteredOrders = <Order>[].obs;
  var statusFilters = ["All", "Assigned", "OnDelivery", "Completed"];
  var selectedFilter = "All".obs; // Default: All
  var isStartingTrip = false.obs;
  var isCompletingDelivery = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    fetchAssignedOrders();
    _startAutoRefresh();
  }

  /// ✅ Start delivery request
  Future<void> startDelivery(String orderId) async {
    if (orderId.isEmpty) return;

    isStartingTrip(true);
    try {
      String? token = SharedPrefsUtil().getToken();
      if (token == null) return;

      final url = "${Config.baseUrl}/drivers/start-trip/$orderId";
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print("✅ Trip started for order $orderId");
          // Refresh orders to update status
          await fetchAssignedOrders();
        } else {
          print("⚠️ Trip start failed response: $data");
        }
      } else {
        print("❌ Failed to start delivery. Status Code: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
      }
    } catch (e) {
      print("❌ Exception in startDelivery: $e");
    } finally {
      isStartingTrip(false);
    }
  }

  /// ✅ Complete delivery request
  Future<bool> completeDelivery(String orderId) async {
    if (orderId.isEmpty) return false;

    isCompletingDelivery(true);
    try {
      String? token = SharedPrefsUtil().getToken();
      if (token == null) return false;

      final url = ApiConstants.completeDeliveryUrl.replaceFirst(":orderId", orderId);
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("🌍 Complete Delivery Request: $url");
      print("📦 Response Code: ${response.statusCode}");
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns { message: "...", order: {...}, driver: {...} }
        // Check if the response contains a success message
        if (data['message'] != null && data['message'].toString().contains('successfully')) {
          print("✅ Delivery completed for order $orderId");
          // Refresh orders to update status
          await fetchAssignedOrders();
          return true;
        } else {
          print("⚠️ Delivery completion failed response: $data");
          return false;
        }
      } else {
        print("❌ Failed to complete delivery. Status Code: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception in completeDelivery: $e");
      return false;
    } finally {
      isCompletingDelivery(false);
    }
  }

  /// ✅ Finish delivery method (alias for completeDelivery)
  Future<bool> finishDelivery(String orderId) async {
    return await completeDelivery(orderId);
  }

  /// ✅ Fetch assigned and on-delivery orders
  Future<void> fetchAssignedOrders() async {
    isLoading(true);
    try {
      String? token = SharedPrefsUtil().getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.driverAssignedTask),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("🌍 Request: ${ApiConstants.driverAssignedTask}");
      print("📦 Response Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("📦 Raw Response: ${jsonEncode(data)}");

        if (data.containsKey("orders") && data["orders"] != null) {
          List<Order> rawOrders = (data["orders"] as List)
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
          allRawOrders = rawOrders; // ✅ Store all orders for group access

          print("🧾 Parsed Orders from Backend:");
          for (var o in rawOrders) {
            print("➡️ Order: ${o.orderIdGenerated ?? o.orderId} | "
                "Type: ${o.routeWay} | "
                "Group: ${o.sharedGroupId} | "
                "Customer: ${o.customerFirstName} | "
                "Station: ${o.stationName} | "
                "Status: ${o.status}");
          }

          final Map<String, List<Order>> sharedGroups = {};
          final List<Order> finalOrders = [];

          for (var order in rawOrders) {
            if ((order.status.toLowerCase() == "assigned" || order.status.toLowerCase() == "ondelivery")) {
              if (order.routeWay == "shared" && order.sharedGroupId.isNotEmpty) {
                // Group shared orders by groupId
                if (!sharedGroups.containsKey(order.sharedGroupId)) {
                  sharedGroups[order.sharedGroupId] = [];
                }
                sharedGroups[order.sharedGroupId]!.add(order);
              } else {
                // Private order — add directly
                finalOrders.add(order);
              }
            }
          }

          // Add one representative from each shared group
          for (var group in sharedGroups.values) {
            finalOrders.add(group.first); // Show one entry per group
          }

          assignedOrders.assignAll(finalOrders);
        } else {
          assignedOrders.clear();
        }
      } else {
        print("❌ Failed to fetch orders. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception in fetchAssignedOrders: $e");
    } finally {
      isLoading(false);
      filterOrders();
    }
  }

  List<Order> getGroupOrders(String sharedGroupId) {
    return allRawOrders
        .where((o) => o.sharedGroupId == sharedGroupId && o.routeWay == "shared")
        .toList();
  }

  /// ✅ Start periodic refresh
  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchAssignedOrders();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// ✅ Filter based on selected status
  void filterOrders() {
    if (selectedFilter.value == "All") {
      filteredOrders.assignAll(assignedOrders);
    }
    else if (selectedFilter.value.isNotEmpty) {} 

   else {
      filteredOrders.assignAll(
        assignedOrders.where((order) =>
        order.status.toLowerCase() ==
            selectedFilter.value.toLowerCase()).toList(),
      );
    }
  }
}
