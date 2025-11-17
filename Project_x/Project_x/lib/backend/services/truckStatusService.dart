import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oil_connect/backend/models/message_model.dart';
import 'package:oil_connect/utils/api_constants.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';

class MessageService {
  /// Fetch unread message count (userId is now taken from token)
  Future<int> fetchUnreadCount() async {
    try {
      final token = await SharedPrefsUtil().getToken();
      if (token == null || token.isEmpty) {
        return 0;
      }

      final url = Uri.parse(ApiConstants.messageCountUrl);
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['totalMessages'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// ✅ Fetch all read & unread messages
  Future<List<Message>> fetchAllMessages() async {
    try {
      final token = await SharedPrefsUtil().getToken();
      if (token == null || token.isEmpty) return [];

      final url = Uri.parse(ApiConstants.messageUrl); // '/messages/history'
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List messages = decoded['messageHistory'];
        return messages.map((m) => Message.fromJson(m)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("❌ Error fetching all messages: $e");
      return [];
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      final token = await SharedPrefsUtil().getToken();
      if (token == null || token.isEmpty) return;

      final url = Uri.parse(ApiConstants.readMessageUrl(messageId));

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print("✅ Message $messageId marked as read");
      } else {
        print("❌ Failed to mark message as read: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error marking message as read: $e");
    }
  }
}
