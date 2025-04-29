import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/enhanced_chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_status.dart';
import '../widgets/file_attachment.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/encryption_explainer.dart';
import '../widgets/privacy_wrapper.dart';
import '../utils/app_theme.dart';
import '../services/privacy_service.dart';

class RealTimeChatScreen extends StatefulWidget {
  final String chatId;
  final String contactId;
  final String contactName;
  final String? contactPhotoUrl;

  const RealTimeChatScreen({
    Key? key,
    required this.chatId,
    required this.contactId,
    required this.contactName,
    this.contactPhotoUrl,
  }) : super(key: key);

  @override
  State<RealTimeChatScreen> createState() => _RealTimeChatScreenState();
}

class _RealTimeChatScreenState extends State<RealTimeChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  late EnhancedChatProvider _chatProvider;
  
  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<EnhancedChatProvider>(context, listen: false);
    _loadChat();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadChat() async {
    await _chatProvider.loadChat(widget.chatId, widget.contactId);
  }
  
  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty || _chatProvider.selectedAttachments.isNotEmpty) {
      _chatProvider.sendMessage(text);
      _messageController.clear();
    }
  }
  
  void _handleAttachmentsSelected(List<AttachmentData> attachments) {
    _chatProvider.setSelectedAttachments(attachments);
  }
  
  void _handleTypingStatusChanged(bool isTyping) {
    _chatProvider.updateTypingStatus(isTyping);
  }
  
  void _handleReactionSelected(String emoji, String messageId) {
    // Implement reaction functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added reaction: $emoji')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Build the main chat scaffold first
    final chatScaffold = Scaffold(
      appBar: AppBar(
        title: Consumer<EnhancedChatProvider>(
          builder: (context, provider, child) {
            return Row(
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
                    if (provider.isContactTyping)
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
            );
          },
        ),
        actions: [
          // Add privacy toggle in app bar
          PrivacyToggleButton(mini: true),
          
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
          Consumer<EnhancedChatProvider>(
            builder: (context, provider, child) {
              if (provider.selectedAttachments.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Container(
                height: 150,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: provider.selectedAttachments.length,
                  itemBuilder: (context, index) {
                    return FileAttachmentPreview(
                      attachment: provider.selectedAttachments[index],
                      onRemove: () {
                        final attachments = List<AttachmentData>.from(provider.selectedAttachments);
                        attachments.removeAt(index);
                        provider.setSelectedAttachments(attachments);
                      },
                    );
                  },
                ),
              );
            },
          ),
          
          // Messages list
          Expanded(
            child: Consumer<EnhancedChatProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const ChatMessageShimmer();
                }
                
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadChat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (provider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 72,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say hi to start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
                    
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      onTap: () {
                        // Message tapped action
                      },
                      onLongPress: () {
                        // Long press action
                      },
                      onReactionSelected: (emoji) => _handleReactionSelected(emoji, message.id),
                    );
                  },
                );
              },
            ),
          ),
          
          // Typing indicator
          Consumer<EnhancedChatProvider>(
            builder: (context, provider, child) {
              if (!provider.isContactTyping) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TypingIndicator(
                    showText: false,
                  ),
                ),
              );
            },
          ),
          
          // Chat input
          ChatInputField(
            controller: _messageController,
            focusNode: _messageFocusNode,
            onSendMessage: (text) => _handleSendMessage(),
            onAttachmentsSelected: _handleAttachmentsSelected,
            isTyping: _chatProvider.isTyping,
            onTypingStatusChanged: _handleTypingStatusChanged,
          ),
        ],
      ),
    );

    // Wrap the scaffold with our privacy wrapper and add a quick toggle button
    return Stack(
      children: [
        // Wrap with privacy mode
        PrivacyWrapper(
          customMessage: 'Tap to unlock your chat with ${widget.contactName}',
          child: chatScaffold,
        ),
        
        // Add a quick privacy toggle button
        Positioned(
          right: 16,
          bottom: 100,
          child: PrivacyToggleFAB(),
        ),
      ],
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
            Consumer<PrivacyProvider>(
              builder: (context, privacyProvider, _) {
                final isPrivacyModeActive = privacyProvider.isPrivacyModeEnabled;
                return ListTile(
                  leading: Icon(
                    isPrivacyModeActive ? Icons.lock : Icons.lock_open,
                    color: isPrivacyModeActive ? Colors.red : Colors.green,
                  ),
                  title: Text(
                    'Privacy Mode ${isPrivacyModeActive ? 'On' : 'Off'}',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    privacyProvider.togglePrivacyMode();
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield),
              title: const Text('Privacy Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/privacy-settings');
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
                'Each character in your message is converted to a unique combination of three numbers, making your conversations highly secure.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: EncryptionExplainer(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/encryption-explainer');
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }
  
  void _showClearChatConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear all messages in this chat? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
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