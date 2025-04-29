import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../utils/janatonese.dart';
import '../utils/error_handler.dart';
import '../services/chat_status_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/file_attachment.dart';

/// Enhanced chat provider that handles all chat-related operations
/// including typing indicators and read receipts
class EnhancedChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ChatStatusService _statusService = ChatStatusService();
  final Uuid _uuid = const Uuid();
  
  // Current chat state
  String? _currentChatId;
  String? _currentContactId;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _isSending = false;
  List<AttachmentData> _selectedAttachments = [];
  
  // Typing and read receipt state
  bool _isTyping = false;
  bool _isContactTyping = false;
  Map<String, bool> _chatTypingStatus = {};
  
  // Streams
  StreamSubscription? _messagesSubscription;
  
  // Getters
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentChatId => _currentChatId;
  String? get currentContactId => _currentContactId;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSending => _isSending;
  List<AttachmentData> get selectedAttachments => _selectedAttachments;
  bool get isTyping => _isTyping;
  bool get isContactTyping => _isContactTyping;
  Map<String, bool> get chatTypingStatus => _chatTypingStatus;
  
  // Constructor
  EnhancedChatProvider() {
    // Set up callbacks for chat status service
    _statusService.onTypingStatusChanged = _handleTypingStatusChanged;
    _statusService.onMessageRead = _handleMessageRead;
    
    // Set user online when provider is initialized
    _statusService.setUserOnlineStatus(true);
  }
  
  @override
  void dispose() {
    _cleanupSubscriptions();
    // Set user offline when provider is disposed
    _statusService.setUserOnlineStatus(false);
    super.dispose();
  }
  
  // Load a specific chat
  Future<void> loadChat(String chatId, String contactId) async {
    // Clean up previous chat if different
    if (_currentChatId != null && _currentChatId != chatId) {
      _cleanupChat();
    }
    
    _currentChatId = chatId;
    _currentContactId = contactId;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Subscribe to messages
      _subscribeToMessages();
      
      // Mark messages as read
      await _statusService.markMessagesAsRead(chatId);
      
      // Start listening to typing status
      _statusService.listenToTypingStatus(chatId, contactId);
      
      // Listen to read receipts
      _statusService.listenToReadReceipts(chatId);
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Subscribe to messages
  void _subscribeToMessages() {
    if (_currentChatId == null) return;
    
    // Cancel previous subscription if any
    _messagesSubscription?.cancel();
    
    _messagesSubscription = _firestore
        .collection('chats')
        .doc(_currentChatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      final updatedMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Parse attachments if any
        List<AttachmentData> attachments = [];
        if (data['attachments'] != null) {
          for (final attachment in data['attachments']) {
            attachments.add(AttachmentData(
              id: attachment['id'],
              name: attachment['name'],
              path: '',  // Local path will be empty for received messages
              size: attachment['size'],
              type: attachment['type'],
              timestamp: attachment['timestamp'].toDate(),
              url: attachment['url'],
            ));
          }
        }
        
        // Get plain text by decrypting janatonese if needed
        String plainText = '';
        if (data['text'] != null && data['text'].isNotEmpty) {
          try {
            plainText = JanatoneseEncryption.decrypt(data['text']);
          } catch (e) {
            // If decryption fails, show the encrypted text
            plainText = 'Message could not be decrypted: ${data['text'].substring(0, 20)}...';
          }
        }
        
        // Create message object
        return Message(
          id: doc.id,
          text: plainText,
          senderId: data['senderId'],
          timestamp: data['timestamp'].toDate(),
          attachments: attachments,
          status: _getMessageStatus(data),
          readAt: data['readAt'] != null ? data['readAt'].toDate() : null,
        );
      }).toList();
      
      setState(() {
        _messages = updatedMessages;
      });
    }, onError: (e) {
      setState(() {
        _error = e.toString();
      });
    });
  }
  
  // Send a message
  Future<void> sendMessage(String text) async {
    if ((text.trim().isEmpty && _selectedAttachments.isEmpty) || 
        _currentChatId == null || currentUserId == null) {
      return;
    }
    
    final messageId = _uuid.v4();
    final timestamp = DateTime.now();
    
    setState(() {
      _isSending = true;
    });
    
    try {
      // First, upload any attachments
      List<Map<String, dynamic>> attachmentData = [];
      
      if (_selectedAttachments.isNotEmpty) {
        for (var attachment in _selectedAttachments) {
          // Upload file to Firebase Storage
          final fileRef = _storage
              .ref()
              .child('chats/${_currentChatId}/${attachment.id}_${attachment.name}');
          
          await fileRef.putFile(File(attachment.path));
          final downloadUrl = await fileRef.getDownloadURL();
          
          // Add to attachment data
          attachment.url = downloadUrl;
          attachmentData.add({
            'id': attachment.id,
            'name': attachment.name,
            'size': attachment.size,
            'type': attachment.type,
            'timestamp': timestamp,
            'url': downloadUrl,
          });
        }
      }
      
      // Encrypt the message text using Janatonese
      final encryptedText = text.isNotEmpty 
          ? JanatoneseEncryption.encrypt(text)
          : '';
      
      // Create the message document in Firestore
      await _firestore
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .doc(messageId)
          .set({
            'text': encryptedText,
            'senderId': currentUserId,
            'timestamp': timestamp,
            'attachments': attachmentData,
            'sentAt': timestamp,
          });
      
      // Update the last message in the chat document
      await _firestore
          .collection('chats')
          .doc(_currentChatId)
          .update({
            'lastMessageText': text.isNotEmpty ? (text.length > 30 ? '${text.substring(0, 30)}...' : text) : 
                               _selectedAttachments.isNotEmpty ? 'Sent an attachment' : '',
            'lastMessageSenderId': currentUserId,
            'lastMessageTimestamp': timestamp,
            // Increment unread count for the other user
            'unreadCount': FieldValue.increment(1),
          });
      
      // Add the message to the local list 
      setState(() {
        _messages.insert(
          0,
          Message(
            id: messageId,
            text: text,
            senderId: currentUserId!,
            timestamp: timestamp,
            attachments: _selectedAttachments,
            status: MessageStatus.sent,
          ),
        );
        
        // Clear input and attachments
        _selectedAttachments = [];
        _isSending = false;
      });
      
      // Stop typing indicator
      updateTypingStatus(false);
      
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isSending = false;
      });
      
      // Add with error status to local list so user knows sending failed
      _messages.insert(
        0,
        Message(
          id: messageId,
          text: text,
          senderId: currentUserId!,
          timestamp: timestamp,
          attachments: _selectedAttachments,
          status: MessageStatus.failed,
        ),
      );
      
      notifyListeners();
    }
  }
  
  // Update typing status
  Future<void> updateTypingStatus(bool isTyping) async {
    if (_currentChatId == null || _isTyping == isTyping) return;
    
    _isTyping = isTyping;
    await _statusService.updateTypingStatus(_currentChatId!, isTyping);
  }
  
  // Handle typing status changes from other users
  void _handleTypingStatusChanged(String chatId, bool isTyping) {
    if (chatId == _currentChatId) {
      setState(() {
        _isContactTyping = isTyping;
      });
    }
    
    // Update typing status map for chat list
    setState(() {
      _chatTypingStatus[chatId] = isTyping;
    });
  }
  
  // Handle message read receipts
  void _handleMessageRead(String chatId, String messageId) {
    // Find the message and update its status
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      setState(() {
        final updatedMessage = Message(
          id: _messages[index].id,
          text: _messages[index].text,
          senderId: _messages[index].senderId,
          timestamp: _messages[index].timestamp,
          attachments: _messages[index].attachments,
          status: MessageStatus.read,
          readAt: DateTime.now(),
        );
        _messages[index] = updatedMessage;
      });
    }
  }
  
  // Get message status from Firestore data
  MessageStatus _getMessageStatus(Map<String, dynamic> data) {
    if (data['error'] != null) {
      return MessageStatus.failed;
    }
    
    if (data['readAt'] != null) {
      return MessageStatus.read;
    }
    
    if (data['deliveredAt'] != null) {
      return MessageStatus.delivered;
    }
    
    return MessageStatus.sent;
  }
  
  // Set selected attachments
  void setSelectedAttachments(List<AttachmentData> attachments) {
    setState(() {
      _selectedAttachments = attachments;
    });
    notifyListeners();
  }
  
  // Retry sending a failed message
  Future<void> retryMessage(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;
    
    final message = _messages[index];
    
    // Remove the failed message
    setState(() {
      _messages.removeAt(index);
    });
    
    // Resend the message
    await sendMessage(message.text);
  }
  
  // Clean up current chat
  void _cleanupChat() {
    if (_currentChatId != null) {
      _statusService.disposeChat(_currentChatId!);
      _messagesSubscription?.cancel();
      _messagesSubscription = null;
    }
    
    setState(() {
      _messages = [];
      _isTyping = false;
      _isContactTyping = false;
      _selectedAttachments = [];
    });
  }
  
  // Clean up all subscriptions
  void _cleanupSubscriptions() {
    _messagesSubscription?.cancel();
    _statusService.dispose();
  }
  
  // Helper to update state and notify listeners
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}