class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String encryptedContent;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.encryptedContent,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  // Create a Message from Firestore data
  factory Message.fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      encryptedContent: data['encryptedContent'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as DateTime)
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'encryptedContent': encryptedContent,
      'timestamp': timestamp,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  // Mark message as read
  Message markAsRead() {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      encryptedContent: encryptedContent,
      timestamp: timestamp,
      isRead: true,
      metadata: metadata,
    );
  }
}