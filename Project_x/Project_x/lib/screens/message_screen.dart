import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = []; // Stores chat messages

  void _sendMessage() {
    String message = _messageController.text.trim();

    if (message.isNotEmpty) {
      setState(() {
        _messages.add(message);
      });

      _messageController.clear(); // Clear input field
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.rectangleColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.shapeColor),
        title: const Text("Messages",
          style: TextStyle(
            color: AppColors.shapeColor,
            fontWeight: FontWeight.bold,
          ),),
      ),
      body: Column(
        children: [
          // Chat Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.rectangleColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _messages[index],
                      style: const TextStyle(color: AppColors.messageTextColor),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Field & Send Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: AppColors.textFieldBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: AppColors.sendButtonColor),
                  color: AppColors.rectangleColor,
                  iconSize: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
