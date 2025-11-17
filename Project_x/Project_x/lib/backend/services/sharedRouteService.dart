import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_constants.dart';
import '../../utils/shared_pref_utils.dart';
import '../models/order_model.dart';

class SharedOrderService {
  /// 🔍 Search for Matching Shared Order
  Future<bool> searchForSharedMatch(Order order) async {
    final url = ApiConstants.searchSharedUrl;
    final token = SharedPrefsUtil().getToken();

    if (token == null) {
      print("⛔ Token is null. Cannot search for shared match.");
      return false;
    }

    try {
      final body = json.encode(order.toSearchJson());

      print("🔍 API Endpoint: $url");
      print("🔐 Auth Token: $token");
      print("📤 Request Body: $body");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print("📥 Response Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      final data = json.decode(response.body);

      if (data['orders'] != null &&
          data['orders'] is List &&
          data['orders'].isNotEmpty) {
        print("✅ Match found with ${data['orders'].length} orders.");
        return true;
      } else {
        print("❌ No matching orders found.");
        return false;
      }
    } catch (e) {
      print("⚠️ Error during match search: $e");
      return false;
    }
  }

  /// 🛒 Place a Shared Order (returns Map for consistent handling)
  Future<Map<String, dynamic>> placeSharedOrder(Order order) async {
    final url = ApiConstants.sharedOrderUrl;
    final token = SharedPrefsUtil().getToken();

    if (token == null) {
      print("⛔ User is not authenticated. Cannot place shared order.");
      return {'success': false, 'message': 'User not authenticated'};
    }

    try {
      final body = json.encode(order.toJson());
      print("🔴 Sending Shared Order Request: $body");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print("🟢 Shared Order API Response: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Shared order placed successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to place shared order',
          'suggestion': response.body
        };
      }
    } catch (e) {
      print("⚠️ Error placing shared order: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  /// 🔎 Find shared orders by criteria (e.g., region), returns list
  Future<List<Order>> findSharedOrders({
    required String region,
    String? fuelType,
    String? depot,
    String? source,
    String? company,
  }) async {
    final url = ApiConstants.searchSharedUrl;
    final token = SharedPrefsUtil().getToken();
    if (token == null) return [];

    final payload = <String, dynamic>{
      'region': region,
      if (fuelType != null && fuelType.isNotEmpty) 'fuelType': fuelType,
      if (depot != null && depot.isNotEmpty) 'depot': depot,
      if (source != null && source.isNotEmpty) 'source': source,
      if (company != null && company.isNotEmpty) 'company': company,
    };

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = (data['orders'] as List<dynamic>?) ?? [];
      return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
