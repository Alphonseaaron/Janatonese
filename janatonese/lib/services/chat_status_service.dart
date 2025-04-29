import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Service that handles real-time chat status updates such as:
/// - Typing indicators
/// - Read receipts
/// - Online status
class ChatStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache to avoid unnecessary Firestore updates
  final Map<String, bool> _typingStatusCache = {};
  final Map<String, DateTime> _lastTypingUpdate = {};
  
  // Minimum time (in milliseconds) between typing status updates to reduce Firestore writes
  final int _typingThrottleMs = 2000;
  
  // Stream subscriptions
  final Map<String, StreamSubscription> _chatSubscriptions = {};
  
  // Callbacks
  Function(String chatId, bool isTyping)? onTypingStatusChanged;
  Function(String chatId, String messageId)? onMessageRead;
  Function(String userId, bool isOnline)? onUserOnlineStatusChanged;
  
  // Singleton pattern
  static final ChatStatusService _instance = ChatStatusService._internal();
  factory ChatStatusService() => _instance;
  ChatStatusService._internal();
  
  /// Get the current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Set user online status
  Future<void> setUserOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;
    
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }
  
  /// Listen to the online status of a user
  StreamSubscription listenToUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final isOnline = data['isOnline'] as bool? ?? false;
      
      if (onUserOnlineStatusChanged != null) {
        onUserOnlineStatusChanged!(userId, isOnline);
      }
    });
  }
  
  /// Update typing status for a chat
  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    if (currentUserId == null) return;
    
    // Check if status is different from cached status or enough time has passed
    final now = DateTime.now();
    final lastUpdate = _lastTypingUpdate[chatId];
    
    if (_typingStatusCache[chatId] == isTyping &&
        lastUpdate != null &&
        now.difference(lastUpdate).inMilliseconds < _typingThrottleMs) {
      return; // Skip update to reduce Firestore writes
    }
    
    try {
      await _firestore.collection('chats').doc(chatId).update({
        '${currentUserId}_typing': isTyping,
        '${currentUserId}_typingTimestamp': FieldValue.serverTimestamp(),
      });
      
      // Update cache
      _typingStatusCache[chatId] = isTyping;
      _lastTypingUpdate[chatId] = now;
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }
  
  /// Listen to typing status changes in a chat
  StreamSubscription listenToTypingStatus(String chatId, String otherUserId) {
    if (_chatSubscriptions.containsKey('typing_$chatId')) {
      // Already listening to this chat
      return _chatSubscriptions['typing_$chatId']!;
    }
    
    final subscription = _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final isTyping = data['${otherUserId}_typing'] as bool? ?? false;
      final typingTimestamp = data['${otherUserId}_typingTimestamp'];
      
      // Only show typing indicator if timestamp is recent (within 10 seconds)
      bool shouldShowTyping = false;
      if (isTyping && typingTimestamp != null) {
        final typingTime = typingTimestamp.toDate();
        final now = DateTime.now();
        shouldShowTyping = now.difference(typingTime).inSeconds < 10;
      }
      
      if (onTypingStatusChanged != null) {
        onTypingStatusChanged!(chatId, shouldShowTyping);
      }
    });
    
    _chatSubscriptions['typing_$chatId'] = subscription;
    return subscription;
  }
  
  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    if (currentUserId == null) return;
    
    try {
      // Get all unread messages from the other user
      final batch = _firestore.batch();
      final unreadQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('readAt', isNull: true)
          .get();
      
      // Mark all as read in a batch update
      final now = DateTime.now();
      for (final doc in unreadQuery.docs) {
        batch.update(doc.reference, {
          'readAt': now,
        });
        
        // Notify about read messages
        if (onMessageRead != null) {
          onMessageRead!(chatId, doc.id);
        }
      }
      
      // Update chat document to clear unread count
      batch.update(_firestore.collection('chats').doc(chatId), {
        'unreadCount': 0,
      });
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
  
  /// Listen to read receipts for sent messages
  StreamSubscription listenToReadReceipts(String chatId) {
    if (_chatSubscriptions.containsKey('read_$chatId')) {
      // Already listening to this chat
      return _chatSubscriptions['read_$chatId']!;
    }
    
    final subscription = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: currentUserId)
        .where('readAt', isNull: false)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final messageId = change.doc.id;
          
          if (onMessageRead != null) {
            onMessageRead!(chatId, messageId);
          }
        }
      }
    });
    
    _chatSubscriptions['read_$chatId'] = subscription;
    return subscription;
  }
  
  /// Clean up all subscriptions
  void dispose() {
    _chatSubscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    _chatSubscriptions.clear();
  }
  
  /// Clean up subscriptions for a specific chat
  void disposeChat(String chatId) {
    final subscriptionKeys = _chatSubscriptions.keys
        .where((key) => key.endsWith('_$chatId'))
        .toList();
    
    for (final key in subscriptionKeys) {
      _chatSubscriptions[key]?.cancel();
      _chatSubscriptions.remove(key);
    }
  }
}