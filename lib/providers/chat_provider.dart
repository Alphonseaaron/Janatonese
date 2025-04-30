import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/contact.dart';
import '../utils/janatonese.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  // State variables
  bool _loading = false;
  List<Chat> _chats = [];
  List<Contact> _contacts = [];
  Map<String, User> _contactUsers = {};
  List<Message> _currentChatMessages = [];
  String? _currentChatId;
  String? _currentUserId;
  Map<String, String> _sharedSecrets = {}; // contactId -> sharedSecret

  // Getters
  bool get loading => _loading;
  List<Chat> get chats => List.unmodifiable(_chats);
  List<Contact> get contacts => List.unmodifiable(_contacts);
  Map<String, User> get contactUsers => Map.unmodifiable(_contactUsers);
  List<Message> get currentChatMessages => List.unmodifiable(_currentChatMessages);
  
  // Initialize with user ID
  Future<void> initialize(String userId) async {
    _loading = true;
    _currentUserId = userId;
    notifyListeners();
    
    try {
      await _loadContacts(userId);
      await _loadChats(userId);
      
      // Load shared secrets from contacts
      for (final contact in _contacts) {
        if (contact.sharedSecret != null) {
          _sharedSecrets[contact.contactId] = contact.sharedSecret!;
        }
      }
    } catch (e) {
      print('Error initializing ChatProvider: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Load user contacts
  Future<void> _loadContacts(String userId) async {
    try {
      _contacts = await _firebaseService.getUserContacts(userId);
      
      // Load contact user profiles
      for (final contact in _contacts) {
        try {
          final user = await _firebaseService.getUserProfile(contact.contactId);
          if (user != null) {
            _contactUsers[contact.contactId] = user;
          }
        } catch (e) {
          print('Error loading contact user: $e');
        }
      }
    } catch (e) {
      print('Error loading contacts: $e');
      rethrow;
    }
  }

  // Load user chats
  Future<void> _loadChats(String userId) async {
    try {
      _chats = await _firebaseService.getUserChats(userId);
    } catch (e) {
      print('Error loading chats: $e');
      rethrow;
    }
  }

  // Set current chat and load messages
  Future<void> setCurrentChat(String chatId, String userId) async {
    if (_currentChatId == chatId) return;
    
    _currentChatId = chatId;
    _currentUserId = userId;
    _currentChatMessages = [];
    notifyListeners();
    
    try {
      // Load messages for the chat
      _currentChatMessages = await _firebaseService.getChatMessages(chatId);
      notifyListeners();
      
      // Mark unread messages as read
      _markMessagesAsRead(chatId, userId);
      
      // Subscribe to messages updates
      _subscribeToMessages(chatId);
    } catch (e) {
      print('Error setting current chat: $e');
    }
  }

  // Subscribe to message updates
  void _subscribeToMessages(String chatId) {
    _firebaseService.getChatMessagesStream(chatId).listen((messages) {
      _currentChatMessages = messages;
      notifyListeners();
      
      // Mark unread messages as read if user is the recipient
      if (_currentUserId != null) {
        _markMessagesAsRead(chatId, _currentUserId!);
      }
    });
  }

  // Mark messages as read
  Future<void> _markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = _currentChatMessages
          .where((msg) => !msg.isRead && msg.senderId != userId)
          .toList();
      
      for (final message in unreadMessages) {
        await _firebaseService.markMessageAsRead(message.id);
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Add a new contact
  Future<void> addContact(String userId, String contactEmail, {String? nickName, String? sharedSecret}) async {
    _loading = true;
    notifyListeners();
    
    try {
      // Find the user by email
      final user = await _firebaseService.getUserByEmail(contactEmail);
      if (user == null) {
        throw Exception('User not found with email: $contactEmail');
      }
      
      // Check if contact already exists
      final existingContact = _contacts.firstWhereOrNull(
        (c) => c.contactId == user.id && c.userId == userId
      );
      
      if (existingContact != null) {
        throw Exception('Contact already exists');
      }
      
      // Generate shared secret if not provided
      final secret = sharedSecret ?? JanatoneseEncryption.generateSharedSecret();
      
      // Create contact
      final newContact = Contact(
        id: '', // Will be set by Firestore
        userId: userId,
        contactId: user.id,
        nickName: nickName,
        sharedSecret: secret,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final contactId = await _firebaseService.addContact(newContact);
      
      // Update local state
      final contact = Contact(
        id: contactId,
        userId: userId,
        contactId: user.id,
        nickName: nickName,
        sharedSecret: secret,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _contacts.add(contact);
      _contactUsers[user.id] = user;
      _sharedSecrets[user.id] = secret;
      
      notifyListeners();
    } catch (e) {
      print('Error adding contact: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Create a new chat
  Future<String> createChat(String userId, String contactId) async {
    try {
      // Create chat
      final newChat = Chat(
        id: '', // Will be set by Firestore
        participants: [userId, contactId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final chatId = await _firebaseService.createChat(newChat);
      
      // Update local state
      _chats.add(Chat(
        id: chatId,
        participants: [userId, contactId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      
      notifyListeners();
      
      return chatId;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  // Update contact with chat ID
  Future<void> updateContactWithChatId(String contactId, String chatId) async {
    try {
      // Find contact
      final contact = _contacts.firstWhereOrNull((c) => c.contactId == contactId);
      if (contact == null) return;
      
      // Update in Firestore
      await _firebaseService.updateContact(contact.id, {'chatId': chatId});
      
      // Update local state
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _contacts[index] = contact.withChatId(chatId);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating contact with chat ID: $e');
    }
  }

  // Send a message
  Future<void> sendMessage(String content, String senderId, String recipientId) async {
    try {
      // Find chat between sender and recipient
      Chat? chat = _chats.firstWhereOrNull(
        (c) => c.participants.contains(senderId) && c.participants.contains(recipientId)
      );
      
      // If no chat exists, create one
      if (chat == null) {
        final chatId = await createChat(senderId, recipientId);
        
        // Also update the contact with the chat ID
        await updateContactWithChatId(recipientId, chatId);
        
        // Refresh chats list
        chat = _chats.firstWhereOrNull((c) => c.id == chatId);
        if (chat == null) return;
      }
      
      // Get shared secret for encryption
      final sharedSecret = _sharedSecrets[recipientId];
      if (sharedSecret == null) {
        throw Exception('Shared secret not found for recipient');
      }
      
      // Encrypt message
      final encryptedContent = JanatoneseEncryption.encrypt(content, sharedSecret);
      
      // Create message
      final message = Message(
        id: '', // Will be set by Firestore
        chatId: chat.id,
        senderId: senderId,
        encryptedContent: encryptedContent,
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      // Send message to Firestore
      await _firebaseService.sendMessage(message);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Decrypt a message
  String decryptMessage(Message message, String userId, String contactId) {
    try {
      // Find the shared secret
      final sharedSecret = _sharedSecrets[contactId];
      if (sharedSecret == null) {
        return '[Unable to decrypt - no shared secret]';
      }
      
      // Decrypt message
      return JanatoneseEncryption.decrypt(message.encryptedContent, sharedSecret);
    } catch (e) {
      print('Error decrypting message: $e');
      return '[Decryption error]';
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firebaseService.deleteMessage(messageId);
      
      // Update local state
      _currentChatMessages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Delete a contact
  Future<void> deleteContact(String contactId) async {
    try {
      final contact = _contacts.firstWhereOrNull((c) => c.id == contactId);
      if (contact == null) return;
      
      // If contact has a chat, delete it too
      if (contact.chatId != null) {
        await _firebaseService.deleteChat(contact.chatId!);
        _chats.removeWhere((c) => c.id == contact.chatId);
      }
      
      // Delete contact
      await _firebaseService.deleteContact(contactId);
      
      // Update local state
      _contacts.removeWhere((c) => c.id == contactId);
      notifyListeners();
    } catch (e) {
      print('Error deleting contact: $e');
      rethrow;
    }
  }
}