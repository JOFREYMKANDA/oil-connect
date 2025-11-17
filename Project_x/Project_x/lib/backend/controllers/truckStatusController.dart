import 'package:get/get.dart';
import 'package:oil_connect/backend/services/truckStatusService.dart';
import 'package:oil_connect/backend/models/message_model.dart';

class MessageController extends GetxController {
  final MessageService _messageService = MessageService();

  var unreadCount = 0.obs;
  var isLoading = false.obs;
  var messages = <Message>[].obs;
  var isFetchingMessages = false.obs;


  Future<void> markAndRefresh(String messageId) async {
    await _messageService.markMessageAsRead(messageId);
    await fetchAllMessages();
    await fetchUnreadCount();
  }

  Future<void> fetchUnreadCount() async {
    isLoading.value = true;
    try {
      final count = await _messageService.fetchUnreadCount();
      unreadCount.value = count;
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch unread messages.");
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Fetch full message list
  Future<void> fetchAllMessages() async {
    isFetchingMessages.value = true;
    try {
      final allMessages = await _messageService.fetchAllMessages();
      messages.value = allMessages;
    } catch (_) {
      Get.snackbar("Error", "Failed to fetch messages.");
    } finally {
      isFetchingMessages.value = false;
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    await _messageService.markMessageAsRead(messageId);
  }
}
