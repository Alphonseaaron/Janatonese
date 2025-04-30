import 'message.dart';

class Chat {
  final String id;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? lastMessage;

  Chat({
    required this.id,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
  });

  // Create a Chat from Firestore data
  factory Chat.fromFirestore(Map<String, dynamic> data, String id, {Message? lastMessage}) {
    return Chat(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as DateTime)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as DateTime)
          : DateTime.now(),
      lastMessage: lastMessage,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  // Update chat with the last message
  Chat withLastMessage(Message message) {
    return Chat(
      id: id,
      participants: participants,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessage: message,
    );
  }
}