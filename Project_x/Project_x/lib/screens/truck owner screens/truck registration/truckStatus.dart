import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oil_connect/backend/controllers/truckStatusController.dart';
import 'package:oil_connect/utils/colors.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}
class _MessageListScreenState extends State<MessageListScreen> {
  final MessageController messageController = Get.put(MessageController());

  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    messageController.fetchAllMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Truck Status Notification"),
        centerTitle: true,
        backgroundColor: Colors.green.shade900,
      ),
      body: Obx(() {
        if (messageController.isFetchingMessages.value) {
          return const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(color: AppColors.blueColor),
          );
        }

        if (messageController.messages.isEmpty) {
          return const Center(child: Text("No messages available."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: messageController.messages.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final msg = messageController.messages[index];
            final isExpanded = index == expandedIndex;

            final time = DateFormat('dd MMM yyyy, hh:mm a')
                .format(DateTime.parse(msg.timestamp));

            return GestureDetector(
              onTap: () async {
                setState(() {
                  expandedIndex = isExpanded ? null : index;
                });

                // ✅ Call API to mark message as read
                await messageController.markMessageAsRead(msg.id);

                // ✅ Refresh messages & unread count
                await messageController.fetchAllMessages();
                await messageController.fetchUnreadCount();
                await messageController.markAndRefresh(msg.id);
              },


              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              msg.content,
                              maxLines: isExpanded ? null : 1,
                              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: msg.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            msg.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                            color: msg.isRead ? Colors.grey : Colors.green.shade900,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
