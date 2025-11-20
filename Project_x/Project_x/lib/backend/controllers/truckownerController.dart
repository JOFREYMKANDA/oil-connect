import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:oil_connect/backend/models/order_model.dart';
import 'package:oil_connect/utils/api_constants.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';

class TruckOwnerController extends GetxController {
  var orders = <Order>[].obs;
  var isLoading = false.obs;
  var availableDrivers = [].obs;
  var isLoadingDrivers = false.obs;
  var isLoadingAssignDriver = false.obs;
  var assigningDriverId = ''.obs;
  var acceptedOrders = <Order>[].obs;
  var filteredOrders = <Order>[].obs;
  var isLoadingAcceptedOrders = false.obs;
  var selectedFilter = "All".obs;
  final List<String> statusFilters = ["All", "New requests", "Pending", "On delivery", "Completed"];
  var truckCount = 0.obs;
  var isLoadingTruckCount = false.obs;
  var driverCount = 0.obs;
  var isLoadingDriverCount = false.obs;

  @override
  void onInit()async {
    super.onInit();
    await SharedPrefsUtil().init();
    fetchOrders();
    fetchAvailableDrivers();
    fetchAcceptedOrders();
    startListeningForNewOrders();
  }

  void selectFilterAndUpdate(String status) {
    // Update the selected filter
    selectedFilter.value = status;
    
    // Immediately filter the orders without additional reactive calls
    _filterOrdersInternal();
  }

  void filterOrders() {
    _filterOrdersInternal();
  }

  void _filterOrdersInternal() {
    try {
      // Combine both pending/requested (orders) and accepted/assigned/... (acceptedOrders)
      final List<Order> combined = [
        ...orders,
        ...acceptedOrders,
      ];

      if (selectedFilter.value == "All") {
        filteredOrders.assignAll(combined);
        return;
      }

      // Map display names to actual status values
      final String selected = selectedFilter.value;
      if (selected == "New requests") {
        // Include both Pending and Requested from the requests list
        filteredOrders.assignAll(
          combined.where((o) {
            final s = o.status.toLowerCase();
            return s == "pending" || s == "requested";
          }).toList(),
        );
        return;
      }

      String statusToFilter;
      switch (selected) {
        case "Pending":
          statusToFilter = "pending";
          break;
        case "On delivery":
          statusToFilter = "ondelivery";
          break;
        case "Completed":
          statusToFilter = "completed";
          break;
        default:
          statusToFilter = selected.toLowerCase();
      }

      filteredOrders.assignAll(
        combined.where((order) => order.status.toLowerCase() == statusToFilter).toList(),
      );
    } catch (e) {
      print("Error in filterOrders: $e");
      // Fallback to showing all orders
      filteredOrders.assignAll([...orders, ...acceptedOrders]);
    }
  }

  /// ✅ Fetch all accepted orders from API
  Future<void> fetchAcceptedOrders() async {
    try {
      isLoadingAcceptedOrders.value = true;

      String? token = SharedPrefsUtil().getToken();
      if (token == null) return;

      var response = await http.get(
        Uri.parse(ApiConstants.seeAcceptedOrderUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<Order> tempOrders = [];

        /// ✅ Helper function for shared orders
        void parseAndMergeSharedOrders(List<dynamic> sharedList) {
          Map<String, List<dynamic>> grouped = {};

          for (var order in sharedList) {
            final groupId = order["sharedGroupId"] ?? "ungrouped";
            grouped.putIfAbsent(groupId, () => []).add(order);
          }

          grouped.forEach((groupId, groupOrders) {
            if (groupOrders.isEmpty) return; // Skip empty groups
            final base = groupOrders.first;

            List<Customer> mergedCustomers = groupOrders.map((o) {
              final customerId = o["customerId"];
              return Customer(
                id: customerId?["_id"] ?? '',
                firstname: customerId?["firstname"] ?? '',
                lastname: customerId?["lastname"] ?? '',
                phoneNumber: customerId?["phoneNumber"]?.toString() ?? '',
                capacity: o["capacity"] ?? 0,
                price: (o["price"] ?? 0).toDouble(),
                orderId: o["orderId"] ?? '',
                stationDetails: (o["stations"] as List<dynamic>?)
                    ?.map((s) => StationDetail.fromJson(s))
                    .toList() ??
                    [],
              );
            }).toList();

            tempOrders.add(Order(
              orderId: base["_id"] ?? "UNKNOWN_ID",
              orderIdGenerated: base["orderId"] ?? "N/A",
              sharedGroupId: groupId,
              createdDate: groupOrders.length > 1 && groupOrders[1]["createdAt"] != null
                  ? DateTime.tryParse(groupOrders[1]["createdAt"])
                  : DateTime.tryParse(base["createdAt"] ?? ""),
              fuelType: base["fuelType"] ?? "Unknown Fuel",
              routeWay: "shared",
              capacity: groupOrders.fold<int>(0, (sum, o) => sum + ((o["capacity"] ?? 0) as int)),
              deliveryTime: base["formattedDeliveryTime"] ?? "",
              source: base["source"] ?? "",
              depot: base["depot"] ?? "",
              price: groupOrders.fold<double>(0.0, (sum, o) => sum + ((o["price"] ?? 0) as num).toDouble()),
              companyName: (base["companies"] != null && base["companies"].isNotEmpty)
                  ? base["companies"][0]["name"] ?? "Unknown Company"
                  : "Unknown Company",
              distance: (base["distance"] ?? 0).toDouble(),
              status: base["status"] ?? "Assigned",
              driverId: base["driverId"]?["_id"] ?? '',
              driverName:
              "${base["driverId"]?["firstname"] ?? ''} ${base["driverId"]?["lastname"] ?? ''}".trim(),
              driverPhone: base["driverId"]?["phoneNumber"]?.toString() ?? "",
              driverStatus: base["driverId"]?["status"] ?? "",
              vehicleId: base["vehicleId"]?["vehicleIdentity"] ?? "",
              stationName: '',
              region: '',
              district: '',
              assignedOrder: '',
              customerFirstName: '',
              customerLastName: '',
              customerPhone: '',
              depotLat: double.tryParse(base["companies"]?[0]?["latitude"]?.toString() ?? ""),
              depotLng: double.tryParse(base["companies"]?[0]?["longitude"]?.toString() ?? ""),
              stationLat: null,
              stationLng: null,
              customers: mergedCustomers,
              companyNames: (base["companyNames"] as List?)
                  ?.map((c) => c.toString())
                  .toList() ??
                  [],
              matchingVehicles: [],
            ));
          });
        }

        /// ✅ Private orders
        if (data["privateOrders"] != null) {
          for (var o in data["privateOrders"]) {
            final customer = o["customerId"];
            final station = (o["stations"] != null && o["stations"].isNotEmpty) ? o["stations"][0] : null;
            final company = (o["companies"] != null && o["companies"].isNotEmpty) ? o["companies"][0] : null;
            final driver = o["driverId"];
            final vehicle = o["vehicleId"];

            tempOrders.add(Order(
              orderId: o["_id"] ?? "UNKNOWN_ID",
              orderIdGenerated: o["orderId"] ?? "N/A",
              sharedGroupId: "",
              createdDate: DateTime.tryParse(o["createdAt"] ?? "") ?? DateTime.now(),
              fuelType: o["fuelType"] ?? "Unknown",
              routeWay: "private",
              capacity: o["capacity"] ?? 0,
              deliveryTime: o["formattedDeliveryTime"] ?? "",
              source: o["source"] ?? "",
              depot: o["depot"] ?? "",
              price: (o["price"] ?? 0).toDouble(),
              companyName: company?["name"] ?? "Unknown Company",
              depotLat: double.tryParse(company?["latitude"]?.toString() ?? ""),
              depotLng: double.tryParse(company?["longitude"]?.toString() ?? ""),
              stationName: station?["stationName"] ?? "",
              region: station?["region"] ?? "",
              district: station?["district"] ?? "",
              stationLat: double.tryParse(station?["latitude"]?.toString() ?? ""),
              stationLng: double.tryParse(station?["longitude"]?.toString() ?? ""),
              driverId: driver?["_id"] ?? "",
              driverName: "${driver?["firstname"] ?? ""} ${driver?["lastname"] ?? ""}".trim(),
              driverPhone: driver?["phoneNumber"]?.toString() ?? "",
              driverStatus: driver?["status"] ?? "",
              vehicleId: vehicle?["vehicleIdentity"] ?? "",
              customerFirstName: customer?["firstname"] ?? "",
              customerLastName: customer?["lastname"] ?? "",
              customerPhone: customer?["phoneNumber"]?.toString() ?? "",
              assignedOrder: "",
              status: o["status"] ?? "Accepted",
              distance: (o["distance"] ?? 0).toDouble(),
              matchingVehicles: [], // You can add this if needed
              customers: [], // Empty because it's a private order
              companyNames: [],
            ));
          }

        }

        /// ✅ Shared orders
        if (data["sharedOrders"] != null) {
          parseAndMergeSharedOrders(data["sharedOrders"]);
        }

        acceptedOrders.assignAll(tempOrders);
        // Recompute filters based on current selection
        _filterOrdersInternal();
      }
    } catch (e) {
      print("❌ fetchAcceptedOrders error: $e");
    } finally {
      isLoadingAcceptedOrders.value = false;
    }
  }

  /// ✅ Assign a driver to an order
  Future<bool> assignDriver(String driverId, String orderId) async {
    try {
      isLoadingAssignDriver.value = true;

      String? token = SharedPrefsUtil().getToken();
      if (token == null) {
        _showSafeSnackbar("Error", "Authentication required. Please login again.");
        return false;
      }

      // ✅ Use query parameters if API follows this format
      String url = ApiConstants.assignDriverUrl
          .replaceFirst(":orderId", orderId)
          .replaceFirst(":driverId", driverId);

      var response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSafeSnackbar("Success", "Driver assigned successfully!");
        return true;
      } else {
        _showSafeSnackbar("Error", "Failed to assign driver!");
        return false;
      }
    } catch (e) {
      _showSafeSnackbar("Error", "Something went wrong!");
      return false;
    } finally {
      isLoadingAssignDriver.value = false;
    }
  }

  /// ✅ Safe snackbar method that checks if the widget is still mounted
  void _showSafeSnackbar(String title, String message) {
    try {
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: title == "Success" ? Colors.green : Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      }
    } catch (e) {
      // Silently handle snackbar errors to prevent app crashes
      print("Snackbar error: $e");
    }
  }

  /// ✅ Fetch all available drivers from API
  Future<void> fetchAvailableDrivers() async {

    try {
      isLoadingDrivers.value = true; // Show loading indicator

      String? token = SharedPrefsUtil().getToken();
      if (token == null) {

        return;
      }

      // ✅ Print URL before sending request
      String url = ApiConstants.seeAvailableDriverUrl;


      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data is Map<String, dynamic>) {

          if (data.containsKey("drivers")) {
            availableDrivers.value = data["drivers"];
          }
        }
      }
    } finally {
      isLoadingDrivers.value = false;
    }
  }

  Future<void> acceptOrder(Order order) async {
    try {
      print("\n🔍 ========== ORDER ACCEPT TROUBLESHOOTING ==========");
      
      // 1. Check token and decode it
      String? token = SharedPrefsUtil().getToken();
      if (token == null) {
        print("❌ No token found.");
        return;
      }
      
      // Decode JWT token to see user info
      _decodeAndLogJWT(token);
      
      // 2. Check stored user info
      String? storedUserId = SharedPrefsUtil().getUserId();
      String? storedRole = SharedPrefsUtil().getRole();
      print("📱 Stored User ID: $storedUserId");
      print("📱 Stored Role: $storedRole");
      
      // 3. Log order details
      print("\n📋 ORDER DETAILS:");
      print("   Order ID: ${order.orderId}");
      print("   Order Generated ID: ${order.orderIdGenerated}");
      print("   Shared Group ID: ${order.sharedGroupId}");
      print("   Route Way: ${order.routeWay}");
      print("   Status: ${order.status}");
      print("   Fuel Type: ${order.fuelType}");
      print("   Capacity: ${order.capacity}");
      print("   Depot: ${order.depot}");
      print("   Source: ${order.source}");
      print("   Company: ${order.companyName}");
      
      // 4. Check if order has matching vehicles (ownership clue)
      if (order.matchingVehicles.isNotEmpty) {
        print("\n🚛 MATCHING VEHICLES (Ownership Clue):");
        for (var vehicle in order.matchingVehicles) {
          print("   Vehicle ID: ${vehicle.vehicleIdentity}");
          print("   Fuel Type: ${vehicle.fuelType}");
          print("   Tank Capacity: ${vehicle.tankCapacity}");
        }
        
        // Verify if these vehicles belong to this truck owner
        await _verifyVehicleOwnership(order.matchingVehicles);
      } else {
        print("⚠️ No matching vehicles found - this might indicate ownership issue");
      }
      
      // 5. Always pass the actual order document ID expected by backend
      final String passedId = order.orderId;
      print("\n🆔 ID TO PASS TO BACKEND: $passedId");
      
      // ❌ Validate the ID
      if (passedId.isEmpty || passedId == "UNKNOWN_ID") {
        print("❌ Invalid ID to pass to accept API.");
        return;
      }
      
      // 6. Build and log the URL
      final url = ApiConstants.acceptOrderUrl.replaceFirst(":orderId", passedId);
      print("\n📤 REQUEST DETAILS:");
      print("   URL: $url");
      print("   Method: PATCH");
      print("   Headers: Authorization, Content-Type, Accept");
      
      // 7. Make the request
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print("\n📥 RESPONSE DETAILS:");
      print("   Status Code: ${response.statusCode}");
      print("   Response Body: ${response.body}");
      
      if (response.statusCode == 200) {
        print("✅ Order accepted successfully.");
        orders.removeWhere((o) => o.orderId == order.orderId);
        Get.snackbar("Success", "Order accepted successfully", snackPosition: SnackPosition.BOTTOM);
      } else {
        print("\n❌ FAILURE ANALYSIS:");
        
        // Analyze the failure
        if (response.statusCode == 401) {
          print("   🔐 401 Unauthorized - Token might be invalid or expired");
        } else if (response.statusCode == 403) {
          print("   🚫 403 Forbidden - User not authorized for this specific order");
          print("   💡 This suggests the order doesn't belong to this truck owner");
        } else if (response.statusCode == 404) {
          print("   🔍 404 Not Found - Order ID might not exist");
        } else if (response.statusCode == 400) {
          print("   ⚠️ 400 Bad Request - Invalid request format or data");
        }
        
        try {
          final body = json.decode(response.body);
          final message = body is Map<String, dynamic> && body['message'] != null
              ? body['message'].toString()
              : 'Failed to accept order.';
          print("   📝 Error Message: $message");
          
          // Additional debugging info from response
          if (body is Map<String, dynamic>) {
            print("   📊 Full Response Body:");
            body.forEach((key, value) {
              print("      $key: $value");
            });
          }
          
          Get.snackbar("Error", message, snackPosition: SnackPosition.BOTTOM);
          
          // Try refreshing orders to see if assignment gets updated
          print("   🔄 Attempting to refresh order list...");
          await fetchOrders();
        } catch (_) {
          print("   ❌ Failed to parse response body");
          Get.snackbar("Error", "Failed to accept order.", snackPosition: SnackPosition.BOTTOM);
        }
      }
      
      print("\n🔍 ========== END TROUBLESHOOTING ==========\n");
    } catch (e) {
      print("❌ Exception during acceptOrder: $e");
      print("❌ Exception type: ${e.runtimeType}");
      Get.snackbar("Error", "Something went wrong while accepting order.", snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Fetch truck count for the current truck owner
  Future<void> fetchTruckCount() async {
    try {
      isLoadingTruckCount.value = true;
      String? token = SharedPrefsUtil().getToken();
      if (token == null) {
        print("❌ No token found for fetching truck count");
        return;
      }
      
      var response = await http.get(
        Uri.parse(ApiConstants.allVehiclesUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<dynamic> vehicles = data['vehicles'] ?? [];
        truckCount.value = vehicles.length;
        print("✅ Truck count fetched successfully: ${truckCount.value}");
      } else {
        print("❌ Failed to fetch truck count: ${response.statusCode} - ${response.body}");
        truckCount.value = 0;
      }
    } catch (e) {
      print("❌ Error fetching truck count: $e");
      truckCount.value = 0;
    } finally {
      isLoadingTruckCount.value = false;
    }
  }

  /// Fetch driver count for the current truck owner
  Future<void> fetchDriverCount() async {
    try {
      isLoadingDriverCount.value = true;
      String? token = SharedPrefsUtil().getToken();
      if (token == null) {
        print("❌ No token found for fetching driver count");
        return;
      }
      
      var response = await http.get(
        Uri.parse(ApiConstants.driverDetailsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<dynamic> drivers = data['drivers'] ?? [];
        // Count only verified drivers (exclude those with status "unverified")
        final int verifiedCount = drivers.where((d) {
          final status = (d['status'] ?? '').toString().toLowerCase();
          return status == 'available' || status == 'busy' || status == 'completed';
        }).length;
        driverCount.value = verifiedCount;
        print("✅ Driver count fetched successfully: ${driverCount.value}");
      } else {
        print("❌ Failed to fetch driver count: ${response.statusCode} - ${response.body}");
        driverCount.value = 0;
      }
    } catch (e) {
      print("❌ Error fetching driver count: $e");
      driverCount.value = 0;
    } finally {
      isLoadingDriverCount.value = false;
    }
  }
  
  /// Helper method to verify vehicle ownership
  Future<void> _verifyVehicleOwnership(List<MatchingVehicle> matchingVehicles) async {
    try {
      String? token = SharedPrefsUtil().getToken();
      if (token == null) return;
      
      print("\n🔍 VEHICLE OWNERSHIP VERIFICATION:");
      
      // Fetch all vehicles for this truck owner
      var response = await http.get(
        Uri.parse(ApiConstants.allVehiclesUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<dynamic> ownerVehicles = data['vehicles'] ?? [];
        
        print("   📊 Total vehicles owned by this truck owner: ${ownerVehicles.length}");
        
        // Check if any matching vehicles belong to this truck owner
        for (var matchingVehicle in matchingVehicles) {
          bool found = false;
          for (var ownerVehicle in ownerVehicles) {
            if (ownerVehicle['vehicleIdentity'] == matchingVehicle.vehicleIdentity) {
              found = true;
              print("   ✅ Vehicle ${matchingVehicle.vehicleIdentity} BELONGS to this truck owner");
              print("      Status: ${ownerVehicle['status'] ?? 'Unknown'}");
              print("      Fuel Type: ${ownerVehicle['fuelType'] ?? 'Unknown'}");
              break;
            }
          }
          
          if (!found) {
            print("   ❌ Vehicle ${matchingVehicle.vehicleIdentity} does NOT belong to this truck owner!");
            print("      This explains the authorization failure!");
          }
        }
      } else {
        print("   ❌ Failed to fetch vehicle list: ${response.statusCode}");
      }
    } catch (e) {
      print("   ❌ Error verifying vehicle ownership: $e");
    }
  }
  
  /// Helper method to decode and log JWT token details
  void _decodeAndLogJWT(String token) {
    try {
      print("\n🔐 JWT TOKEN ANALYSIS:");
      print("   Token: ${token.substring(0, 20)}...");
      
      // Split JWT token into parts
      final parts = token.split('.');
      if (parts.length == 3) {
        // Decode payload (second part)
        String payload = parts[1];
        
        // Add padding if needed
        while (payload.length % 4 != 0) {
          payload += '=';
        }
        
        // Decode base64
        final bytes = base64Url.decode(payload);
        final payloadString = String.fromCharCodes(bytes);
        final payloadJson = json.decode(payloadString);
        
        print("   JWT Payload:");
        payloadJson.forEach((key, value) {
          print("     $key: $value");
        });
        
        // Check if token is expired
        if (payloadJson['exp'] != null) {
          final exp = DateTime.fromMillisecondsSinceEpoch(payloadJson['exp'] * 1000);
          final now = DateTime.now();
          if (now.isAfter(exp)) {
            print("   ⚠️ TOKEN EXPIRED! Expiry: $exp, Current: $now");
          } else {
            print("   ✅ Token is valid until: $exp");
          }
        }
      } else {
        print("   ❌ Invalid JWT format");
      }
    } catch (e) {
      print("   ❌ Failed to decode JWT: $e");
    }
  }

  /// ✅ Fetch orders from API
  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;

      String? token = SharedPrefsUtil().getToken();
      if (token == null) return;

      var response = await http.get(
        Uri.parse(ApiConstants.getOrderUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<Order> fetchedOrders = [];

        void parseOrders(List<dynamic> ordersList, String routeWay) {
          for (var order in ordersList) {
            // 🔁 Parse matching vehicles
            List<MatchingVehicle> matchingVehicles = [];
            if (order["matchingVehicles"] != null) {
              matchingVehicles = (order["matchingVehicles"] as List)
                  .map((v) => MatchingVehicle.fromJson(v))
                  .toList();
            }

            fetchedOrders.add(Order(
              orderId: order["_id"] ?? "UNKNOWN_ID",
              orderIdGenerated: order["orderId"] ?? "N/A",
              sharedGroupId: routeWay == 'shared' && order["sharedGroupId"] != null
                  ? order["sharedGroupId"].toString()
                  : '',
              createdDate: DateTime.now(), // or parse(order["createdAt"])
              fuelType: order["fuelType"] ?? "Unknown Fuel",
              routeWay: routeWay,
              capacity: order["capacity"] ?? 0,
              deliveryTime: "", // Not provided in your response
              source: order["source"] ?? "Unknown Source",
              stationName: (order["stationDetails"] != null &&
                  order["stationDetails"] is List &&
                  order["stationDetails"].isNotEmpty &&
                  order["stationDetails"][0]["stationName"] != null)
                  ? order["stationDetails"][0]["stationName"]
                  : "Unknown Station",
              depot: order["depot"] ?? "Unknown Depot",
              companyName: order["companyNames"] != null &&
                  order["companyNames"] is List &&
                  order["companyNames"].isNotEmpty
                  ? order["companyNames"][0]
                  : "Unknown Company",
              price: (order["price"] ?? 0).toDouble(),
              distance: (order["distance"] ?? 0).toDouble(),
              status: order["status"] ?? "Pending",
              driverId: "",
              driverName: "",
              driverPhone: "",
              driverStatus: "",
              region: order["stationDetails"]?[0]?["region"] ?? "",
              district: order["stationDetails"]?[0]?["district"] ?? "",
              assignedOrder: "",
              vehicleId: order["vehicleId"]?["vehicleIdentity"] ?? "",
              customerFirstName: '',
              customerLastName: '',
              customerPhone: '',
              depotLat: null,
              depotLng: null,
              stationLat: null,
              stationLng: null,
              customers: (order['customers'] as List<dynamic>?)
                  ?.map((e) => Customer.fromJson(e))
                  .toList() ?? [],
              companyNames: [],
              matchingVehicles: matchingVehicles, // ✅ Important line
            ));
          }
        }

        if (data["privateOrders"] != null) {
          parseOrders(data["privateOrders"], "private");
        }

        if (data["sharedOrders"] != null) {
          parseOrders(data["sharedOrders"], "shared");
        }

        orders.assignAll(fetchedOrders);
        // Recompute filters to include new request data
        _filterOrdersInternal();
      }
    } catch (e) {
      print("❌ fetchOrders error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Start listening for new orders
  void startListeningForNewOrders() {
    Timer.periodic(const Duration(minutes: 10), (timer) async {
      await fetchOrders();
    });
  }

}