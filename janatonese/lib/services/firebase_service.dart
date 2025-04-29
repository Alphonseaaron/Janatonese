import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_models;
import '../models/message.dart';
import '../models/chat.dart';
import '../models/contact.dart';

class FirebaseService {
  // Singleton instance
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth methods
  Future<firebase_auth.UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<firebase_auth.UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User methods
  Future<void> createUserProfile(String uid, app_models.User user) async {
    await _firestore.collection('users').doc(uid).set(user.toMap());
  }

  Future<app_models.User?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return app_models.User.fromFirebase(doc.data()!, uid);
    }
    return null;
  }

  Future<app_models.User?> getUserByEmail(String email) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return app_models.User.fromFirebase(doc.data(), doc.id);
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Contacts methods
  Future<String> addContact(Contact contact) async {
    final docRef = await _firestore.collection('contacts').add(contact.toMap());
    return docRef.id;
  }

  Future<List<Contact>> getUserContacts(String userId) async {
    final querySnapshot = await _firestore
        .collection('contacts')
        .where('userId', isEqualTo: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => Contact.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateContact(String id, Map<String, dynamic> data) async {
    await _firestore.collection('contacts').doc(id).update(data);
  }

  Future<void> deleteContact(String id) async {
    await _firestore.collection('contacts').doc(id).delete();
  }

  // Chats methods
  Future<String> createChat(Chat chat) async {
    final docRef = await _firestore.collection('chats').add(chat.toMap());
    return docRef.id;
  }

  Future<List<Chat>> getUserChats(String userId) async {
    final querySnapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    List<Chat> chats = [];
    for (var doc in querySnapshot.docs) {
      // Get the last message for this chat
      Message? lastMessage;
      final messagesQuery = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: doc.id)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messagesQuery.docs.isNotEmpty) {
        lastMessage = Message.fromFirestore(
          messagesQuery.docs.first.data(),
          messagesQuery.docs.first.id,
        );
      }

      chats.add(Chat.fromFirestore(doc.data(), doc.id, lastMessage: lastMessage));
    }

    return chats;
  }

  Future<void> updateChat(String id, Map<String, dynamic> data) async {
    await _firestore.collection('chats').doc(id).update(data);
  }

  Future<void> deleteChat(String id) async {
    // Delete all messages in the chat
    final messagesQuery = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: id)
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete the chat
    batch.delete(_firestore.collection('chats').doc(id));
    await batch.commit();
  }

  // Messages methods
  Future<String> sendMessage(Message message) async {
    final docRef = await _firestore.collection('messages').add(message.toMap());
    
    // Update the chat's updatedAt time
    await _firestore.collection('chats').doc(message.chatId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }

  Future<List<Message>> getChatMessages(String chatId, {int limit = 50}) async {
    final querySnapshot = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs
        .map((doc) => Message.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Message>> getChatMessagesStream(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> markMessageAsRead(String id) async {
    await _firestore.collection('messages').doc(id).update({
      'isRead': true,
    });
  }

  Future<void> deleteMessage(String id) async {
    await _firestore.collection('messages').doc(id).delete();
  }
}