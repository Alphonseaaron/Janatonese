import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/contact.dart';
import 'chat_screen.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final contacts = chatProvider.contacts;

    return Scaffold(
      body: chatProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : contacts.isEmpty
              ? _buildEmptyState(context)
              : _buildContactsList(context, contacts, chatProvider),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No contacts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add contacts to start messaging securely',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddContactScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(
      BuildContext context, List<Contact> contacts, ChatProvider chatProvider) {
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final contactUser = chatProvider.contactUsers[contact.contactId];
        
        // Find associated chat if exists
        final chat = chatProvider.chats.firstWhere(
          (chat) => chat.id == contact.chatId,
          orElse: () => null,
        );
        
        // Get last message info
        final lastMessageContent = chat?.lastMessage?.content ?? '';
        final lastMessageTime = chat?.lastMessage?.timestamp ?? DateTime.now();
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.teal,
            child: Text(
              contactUser?.displayName.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            contactUser?.displayName ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: chat?.lastMessage != null
              ? Text(
                  lastMessageContent.length > 30
                      ? '${lastMessageContent.substring(0, 30)}...'
                      : lastMessageContent,
                  overflow: TextOverflow.ellipsis,
                )
              : const Text('Tap to start chatting'),
          trailing: chat?.lastMessage != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(lastMessageTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Unread message indicator (placeholder)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          onTap: () {
            if (contact.chatId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: contact.chatId!,
                    contactId: contact.contactId,
                  ),
                ),
              );
            } else {
              // Create new chat
              _createChat(context, contact.contactId);
            }
          },
          onLongPress: () {
            // Show contact options
            _showContactOptions(context, contact, contactUser?.displayName ?? 'Unknown');
          },
        );
      },
    );
  }

  // Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      // Today, show time only
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.year == now.year) {
      // This year, show month and day
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${monthNames[date.month - 1]} ${date.day}';
    } else {
      // Older, show date with year
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Create a new chat with contact
  void _createChat(BuildContext context, String contactId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get current user ID
      final currentUserId = authProvider.firebaseUser!.uid;
      
      // Create a chat in Firebase
      final chatId = await Provider.of<ChatProvider>(context, listen: false)
          .createChat(currentUserId, contactId);
      
      // Update contact with chat ID
      await Provider.of<ChatProvider>(context, listen: false)
          .updateContactWithChatId(contactId, chatId);
      
      // Dismiss loading
      Navigator.pop(context);
      
      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            contactId: contactId,
          ),
        ),
      );
    } catch (e) {
      // Dismiss loading
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show contact options dialog
  void _showContactOptions(BuildContext context, Contact contact, String contactName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('View Contact Info'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to contact details screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Contact', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteContact(context, contact, contactName);
            },
          ),
        ],
      ),
    );
  }

  // Confirm contact deletion
  void _confirmDeleteContact(BuildContext context, Contact contact, String contactName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete "$contactName" from your contacts? This will also delete your chat history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete contact
              // Provider.of<ChatProvider>(context, listen: false).deleteContact(contact.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}