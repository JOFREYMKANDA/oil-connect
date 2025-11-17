import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:oil_connect/utils/api_constants.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';
import '../models/order_model.dart';
import '../services/orderServices.dart';

class OrderController extends GetxController {
  final OrderService _orderService = OrderService();
  var isLoading = false.obs;
  RxList<Order> orders = <Order>[].obs;
  RxList<Order> filteredOrders = <Order>[].obs;
  RxString selectedFilter = "All".obs;
  RxString searchQuery = "".obs;
  RxInt newOrderCount = 0.obs;


  /// ✅ Define Status Filters
  final List<String> statusFilters = [
    "All",
    "Pending",
    "OnDelivery",
    "Completed",
  ];

  @override
  void onInit() {
    super.onInit();
    fetchOrders(); // ✅ Fetch orders on initialization
  }

  /// ✅ Place Order
  Future<bool> placeOrder(Order order) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading.value = true;
    });

    try {
      final result = await _orderService.placeOrder(order);
      bool success = result["success"];
      String message = result["message"];

      if (success) {
        fetchOrders();
        return true;
      } else {
        Get.snackbar("Order Failed", message);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e");
      return false;
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
      });
    }
  }

  Future<Map<String, dynamic>> placeOrderWithMessage(Order order) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading.value = true;
    });
    try {
      final result = await _orderService.placeOrder(order);
      if (result["success"]) {
        fetchOrders();
      }
      return result;
    } catch (e) {
      return {
        "success": false,
        "message": "Something went wrong: $e",
        "suggestion": null,
      };
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
      });
    }
  }


  /// ✅ Fetch Orders from API
  Future<void> fetchOrders() async {
    try {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = true;
      });

      String? token = SharedPrefsUtil().getToken();
      if (token == null) {
        Get.snackbar("Error", "User not authenticated.");
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.seeOrderUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse["orders"] != null) {
          List<dynamic> jsonOrders = jsonResponse["orders"];
          List<Order> fetchedOrders =
          jsonOrders.map((order) => Order.fromJson(order)).toList();

          // ✅ Sort orders safely, treating null values as the oldest
          fetchedOrders.sort((a, b) {
            DateTime dateA = a.createdDate ?? DateTime(2000, 1, 1); // Default to old date
            DateTime dateB = b.createdDate ?? DateTime(2000, 1, 1); // Default to old date
            return dateB.compareTo(dateA); // Sort descending (newest first)
          });

          // Use addPostFrameCallback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            orders.assignAll(fetchedOrders);
            filterOrders();

            // Update badge count based on desired status types
            int count = fetchedOrders.where((o) =>
            o.status.toLowerCase() == "pending" ||
                o.status.toLowerCase() == "assigned").length;
            newOrderCount.value = count;
          });

          
        // ✅ Convert fetched orders to JSON list
        final ordersJson = fetchedOrders.map((order) => order.toJson()).toList();

        // ✅ Pretty print the JSON
        const encoder = JsonEncoder.withIndent('  ');
        print(encoder.convert(ordersJson));



        } else {
          // Use addPostFrameCallback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            orders.clear();
            filteredOrders.clear();
          });
        }
      } else {
        print("Error fetching orders: ${response.body}");
      }
    } catch (e) {
      print("Error fetching orders: $e");
    } finally {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
      });
    }
  }

  /// ✅ Filter Orders Based on Selected Status and Search Query
  void filterOrders() {
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start from a fresh copy to avoid accidental linkage to the reactive list
      List<Order> filtered = List<Order>.from(orders);
      
      // Apply status filter
      if (selectedFilter.value != "All") {
        filtered = filtered
            .where((order) => order.status.toLowerCase() == selectedFilter.value.toLowerCase())
            .toList();
      }
      
      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        filtered = filtered.where((order) {
          final query = searchQuery.value.toLowerCase();
          return (order.orderIdGenerated?.toLowerCase().contains(query) ?? false) ||
                 order.fuelType.toLowerCase().contains(query) ||
                 order.depot.toLowerCase().contains(query) ||
                 order.stationName.toLowerCase().contains(query) ||
                 order.district.toLowerCase().contains(query) ||
                 order.region.toLowerCase().contains(query) ||
                 order.companyName.toLowerCase().contains(query);
        }).toList();
      }
      
      filteredOrders.assignAll(filtered);
    });
  }


    /// ✅ Fetch Single Order by OrderId
  Future<Order?> fetchOrderById(String orderId) async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = true;
      });

      String? token = SharedPrefsUtil().getToken();
      if (token == null) {
        Get.snackbar("Error", "User not authenticated.");
        return null;
      }

      final response = await http.get(
        Uri.parse("${ApiConstants.getOrderByIdUrl}/$orderId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        if (jsonResponse["order"] != null) {
          Order fetchedOrder = Order.fromJson(jsonResponse["order"]);

          // ✅ Pretty print the JSON order in terminal
          const encoder = JsonEncoder.withIndent('  ');
          print("Fetched Order:");
          print(encoder.convert(fetchedOrder.toJson()));

          return fetchedOrder;
        } else {
          print("No order found in response.");
          return null;
        }
      } else {
        print("Error fetching order by id: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching order by id: $e");
      return null;
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading.value = false;
      });
    }
  }


  /// ✅ Update Search Query and Filter Orders
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    filterOrders();
  }

  /// ✅ Clear Search Query
  void clearSearch() {
    searchQuery.value = "";
    filterOrders();
  }
}
