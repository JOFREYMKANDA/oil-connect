class Message {
  final String id;
  final String content;
  final String timestamp;
  bool isRead;

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id']?.toString() ?? 'N/A',
      content: json['message']?.toString() ?? 'No content',
      timestamp: json['createdAt']?.toString() ?? '',
      isRead: (json['status']?.toString().toLowerCase() ?? 'unread') == 'read',
    );
  }
}

