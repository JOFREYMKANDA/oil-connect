import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_constants.dart';
import '../../utils/shared_pref_utils.dart';
import '../models/order_model.dart';

class OrderService {
  Future<Map<String, dynamic>> placeOrder(Order order) async {
    final url = ApiConstants.placeOrderUrl;
    final token = await SharedPrefsUtil().getToken();

    try {
      final body = json.encode(order.toJson());

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          "success": true,
          "message": "Order placed successfully",
          "suggestion": null, // explicitly add for success
        };
      } else {
        return {
          "success": false,
          "message": jsonResponse["message"] ?? "Failed to place order",
          "suggestion": jsonResponse["suggestion"] ?? null, // 🔥 added line
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Something went wrong: $e",
        "suggestion": null, // safe fallback
      };
    }
  }
}
