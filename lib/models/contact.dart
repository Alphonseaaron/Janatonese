class Contact {
  final String id;
  final String userId;
  final String contactId;
  final String? nickName;
  final String? chatId;
  final String? sharedSecret;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.userId,
    required this.contactId,
    this.nickName,
    this.chatId,
    this.sharedSecret,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a Contact from Firestore data
  factory Contact.fromFirestore(Map<String, dynamic> data, String id) {
    return Contact(
      id: id,
      userId: data['userId'] ?? '',
      contactId: data['contactId'] ?? '',
      nickName: data['nickName'],
      chatId: data['chatId'],
      sharedSecret: data['sharedSecret'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as DateTime)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as DateTime)
          : DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'contactId': contactId,
      'nickName': nickName,
      'chatId': chatId,
      'sharedSecret': sharedSecret,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  // Update contact with chat ID
  Contact withChatId(String newChatId) {
    return Contact(
      id: id,
      userId: userId,
      contactId: contactId,
      nickName: nickName,
      chatId: newChatId,
      sharedSecret: sharedSecret,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Update contact nickname
  Contact withNickname(String newNickname) {
    return Contact(
      id: id,
      userId: userId,
      contactId: contactId,
      nickName: newNickname,
      chatId: chatId,
      sharedSecret: sharedSecret,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Update shared secret
  Contact withSharedSecret(String newSharedSecret) {
    return Contact(
      id: id,
      userId: userId,
      contactId: contactId,
      nickName: nickName,
      chatId: chatId,
      sharedSecret: newSharedSecret,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}