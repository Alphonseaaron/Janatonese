import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../utils/app_theme.dart';
import '../utils/janatonese.dart';
import '../utils/error_handler.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_status.dart';
import '../widgets/file_attachment.dart';

class EnhancedChatScreen extends StatefulWidget {
  final String chatId;
  final String contactId;
  final String contactName;
  final String? contactPhotoUrl;

  const EnhancedChatScreen({
    Key? key,
    required this.chatId,
    required this.contactId,
    required this.contactName,
    this.contactPhotoUrl,
  }) : super(key: key);

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasTypingStarted = false;
  bool _isContactTyping = false;
  String? _typingError;
  String? _replyToMessageId;
  String? _replyToMessageText;
  
  List<Message> _messages = [];
  List<AttachmentData> _selectedAttachments = [];
  
  // For reaction menu
  String? _longPressedMessageId;
  
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final _uuid = const Uuid();
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupTypingListener();
    
    // Set messages as read when screen opens
    _markMessagesAsRead();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    
    // Stop typing indicator when leaving the chat
    _sendTypingStatus(false);
    
    super.dispose();
  }
  
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get messages from Firestore
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      // Parse messages
      final messages = messagesSnapshot.docs.map((doc) {
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
        
        // Create message object
        return Message(
          id: doc.id,
          text: data['text'] ?? '',
          senderId: data['senderId'],
          timestamp: data['timestamp'].toDate(),
          attachments: attachments,
          status: _getMessageStatus(data),
          readAt: data['readAt'] != null ? data['readAt'].toDate() : null,
        );
      }).toList();
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
    } catch (error) {
      ErrorHandler.showError(context, 'Error loading messages', error);
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Determine message status based on Firestore data
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
  
  void _setupTypingListener() {
    try {
      // Listen to typing status from the other user
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) return;
        
        final data = snapshot.data()!;
        final isContactTyping = data['${widget.contactId}_typing'] ?? false;
        final typingTimestamp = data['${widget.contactId}_typingTimestamp'];
        
        // Only show typing indicator if timestamp is recent (within 10 seconds)
        bool shouldShowTyping = false;
        if (isContactTyping && typingTimestamp != null) {
          final typingTime = typingTimestamp.toDate();
          final now = DateTime.now();
          shouldShowTyping = now.difference(typingTime).inSeconds < 10;
        }
        
        setState(() {
          _isContactTyping = shouldShowTyping;
        });
      });
    } catch (e) {
      // Just log the error but don't show to user as it's not critical
      print('Error setting up typing listener: $e');
    }
  }
  
  Future<void> _markMessagesAsRead() async {
    try {
      // Get all unread messages from the other user
      final batch = FirebaseFirestore.instance.batch();
      final unreadQuery = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isEqualTo: widget.contactId)
          .where('readAt', isNull: true)
          .get();
      
      // Mark all as read in a batch update
      final now = DateTime.now();
      for (final doc in unreadQuery.docs) {
        batch.update(doc.reference, {
          'readAt': now,
        });
      }
      
      // Commit the batch
      await batch.commit();
      
    } catch (e) {
      // Just log the error but don't show to user as it's not critical
      print('Error marking messages as read: $e');
    }
  }
  
  Future<void> _sendTypingStatus(bool isTyping) async {
    try {
      // Only send updates if status changed
      if (_hasTypingStarted == isTyping) return;
      
      _hasTypingStarted = isTyping;
      
      // Update typing status in Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
            '${_currentUserId}_typing': isTyping,
            '${_currentUserId}_typingTimestamp': FieldValue.serverTimestamp(),
          });
          
    } catch (e) {
      // Just log typing errors but don't show to user
      setState(() {
        _typingError = e.toString();
      });
      print('Error updating typing status: $e');
    }
  }
  
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty && _selectedAttachments.isEmpty) return;
    
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
          final fileRef = FirebaseStorage.instance
              .ref()
              .child('chats/${widget.chatId}/${attachment.id}_${attachment.name}');
          
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
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .set({
            'text': encryptedText,
            'senderId': _currentUserId,
            'timestamp': timestamp,
            'attachments': attachmentData,
            'sentAt': timestamp,
            'replyToMessageId': _replyToMessageId,
          });
      
      // Update the last message in the chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
            'lastMessageText': text.isNotEmpty ? (text.length > 30 ? '${text.substring(0, 30)}...' : text) : 
                               _selectedAttachments.isNotEmpty ? 'Sent an attachment' : '',
            'lastMessageSenderId': _currentUserId,
            'lastMessageTimestamp': timestamp,
            'unreadCount': FieldValue.increment(1),
          });
      
      // Add the message to the local list 
      setState(() {
        _messages.insert(
          0,
          Message(
            id: messageId,
            text: text,
            senderId: _currentUserId!,
            timestamp: timestamp,
            attachments: _selectedAttachments,
            status: MessageStatus.sent,
          ),
        );
        
        // Clear input and attachments
        _selectedAttachments = [];
        _replyToMessageId = null;
        _replyToMessageText = null;
        _isSending = false;
      });
      
      // Stop typing indicator
      _sendTypingStatus(false);
      
    } catch (error) {
      ErrorHandler.showError(context, 'Error sending message', error);
      
      // Add with error status to local list so user knows sending failed
      setState(() {
        _messages.insert(
          0,
          Message(
            id: messageId,
            text: text,
            senderId: _currentUserId!,
            timestamp: timestamp,
            attachments: _selectedAttachments,
            status: MessageStatus.failed,
          ),
        );
        
        _isSending = false;
      });
    }
  }
  
  void _handleAttachmentsSelected(List<AttachmentData> attachments) {
    setState(() {
      _selectedAttachments = attachments;
    });
  }
  
  void _handleTypingStatusChanged(bool isTyping) {
    _sendTypingStatus(isTyping);
  }
  
  void _handleReactionSelected(String emoji, String messageId) {
    // Here you would store the reaction in Firestore
    // For now, just show a toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added reaction: $emoji')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.contactPhotoUrl != null
                  ? NetworkImage(widget.contactPhotoUrl!)
                  : null,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: widget.contactPhotoUrl == null
                  ? Text(
                      widget.contactName.isNotEmpty 
                          ? widget.contactName[0].toUpperCase() 
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isContactTyping)
                  const Text(
                    'typing...',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  const Text(
                    'tap for info',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Video call functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Voice call functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected attachments preview
          if (_selectedAttachments.isNotEmpty)
            Container(
              height: 150,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _selectedAttachments.length,
                itemBuilder: (context, index) {
                  return FileAttachmentPreview(
                    attachment: _selectedAttachments[index],
                    onRemove: () {
                      setState(() {
                        _selectedAttachments.removeAt(index);
                      });
                    },
                  );
                },
              ),
            ),
            
          // Reply preview
          if (_replyToMessageId != null && _replyToMessageText != null)
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.reply,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _replyToMessageText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _replyToMessageId = null;
                        _replyToMessageText = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Messages list
          Expanded(
            child: _isLoading
                ? const ChatMessageShimmer()
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hi!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == _currentUserId;
                          
                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            onTap: () {
                              // Message tapped action
                            },
                            onLongPress: () {
                              setState(() {
                                _longPressedMessageId = message.id;
                              });
                            },
                            onReactionSelected: (emoji) => _handleReactionSelected(emoji, message.id),
                          );
                        },
                      ),
          ),
          
          // Typing indicator
          if (_isContactTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypingIndicator(
                  showText: false,
                ),
              ),
            ),
          
          // Chat input
          ChatInputField(
            controller: _messageController,
            focusNode: _messageFocusNode,
            onSendMessage: _sendMessage,
            onAttachmentsSelected: _handleAttachmentsSelected,
            isTyping: _hasTypingStarted,
            onTypingStatusChanged: _handleTypingStatusChanged,
          ),
        ],
      ),
    );
  }
  
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search'),
              onTap: () {
                Navigator.pop(context);
                // Show search UI
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Mute notifications'),
              onTap: () {
                Navigator.pop(context);
                // Mute notifications logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Encryption details'),
              onTap: () {
                Navigator.pop(context);
                _showEncryptionDetails(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper),
              title: const Text('Wallpaper'),
              onTap: () {
                Navigator.pop(context);
                // Change wallpaper logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Clear chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showClearChatConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEncryptionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Janatonese Encryption'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'All messages are encrypted using the Janatonese three-number encryption system.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Each character in your message is converted to a set of three numbers before sending, and can only be decrypted by the recipient\'s device.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEncryptionExplainer(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Learn More'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showEncryptionExplainer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Janatonese Encryption'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 550,
                  child: EncryptionExplainer(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showClearChatConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will delete all messages in this chat for you. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear chat logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}