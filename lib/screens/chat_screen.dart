import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';
import '../utils/janatonese.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String contactId;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.contactId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEncryptedView = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize current chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.firebaseUser != null) {
        Provider.of<ChatProvider>(context, listen: false)
            .setCurrentChat(widget.chatId, authProvider.firebaseUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Send message
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    final message = _messageController.text.trim();
    _messageController.clear();

    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Send message
    try {
      await chatProvider.sendMessage(
        message,
        authProvider.firebaseUser!.uid,
        widget.contactId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Toggle between encrypted and decrypted view
  void _toggleEncryptionView() {
    setState(() {
      _showEncryptedView = !_showEncryptedView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    
    // Get the contact user info
    final contactUser = chatProvider.contactUsers[widget.contactId];
    final currentUserId = authProvider.firebaseUser?.uid;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                contactUser?.displayName.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contactUser?.displayName ?? 'Unknown',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  contactUser?.email ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Toggle encrypted/decrypted view
          IconButton(
            icon: Icon(_showEncryptedView ? Icons.lock_open : Icons.lock),
            onPressed: _toggleEncryptionView,
            tooltip: _showEncryptedView
                ? 'Show Decrypted Messages'
                : 'Show Encrypted Messages',
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'viewContact') {
                // View contact details
              } else if (value == 'clearChat') {
                // Clear chat history
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'viewContact',
                child: Text('View Contact'),
              ),
              const PopupMenuItem<String>(
                value: 'clearChat',
                child: Text('Clear Chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatProvider.currentChatMessages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: chatProvider.currentChatMessages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.currentChatMessages[index];
                      final isMe = message.senderId == currentUserId;
                      
                      return _buildMessageBubble(message, isMe, chatProvider);
                    },
                  ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Emoji button (placeholder)
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {
                      // Show emoji picker
                    },
                  ),
                  // Message input field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  // Attachment button (placeholder)
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      // Show attachment options
                    },
                  ),
                  // Send button
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.teal,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build message bubble
  Widget _buildMessageBubble(Message message, bool isMe, ChatProvider chatProvider) {
    final decryptedMessage = _showEncryptedView
        ? message.encryptedContent
        : chatProvider.decryptMessage(
            message,
            Provider.of<AuthProvider>(context, listen: false).firebaseUser!.uid,
            widget.contactId,
          );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.teal.shade100
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              decryptedMessage,
              style: TextStyle(
                color: isMe ? Colors.teal.shade800 : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatTime(message.timestamp)} ${message.isRead && isMe ? '✓✓' : '✓'}',
              style: TextStyle(
                color: isMe ? Colors.teal.shade600 : Colors.grey.shade600,
                fontSize: 10,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  // Format timestamp to readable time
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}