import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/app_theme.dart';
import '../utils/error_handler.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/privacy_wrapper.dart';
import 'enhanced_chat_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _chats = [];
  List<dynamic> _contacts = [];
  String? _error;
  
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await Future.wait([
        _loadChats(),
        _loadContacts(),
      ]);
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
  
  Future<void> _loadChats() async {
    try {
      // Get all chats where the current user is a participant
      final chatsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: _currentUserId)
          .orderBy('lastMessageTimestamp', descending: true)
          .get();
      
      final chats = await Future.wait(
        chatsSnapshot.docs.map((doc) async {
          final data = doc.data();
          
          // Determine the other participant
          final String otherUserId = data['participant1'] == _currentUserId
              ? data['participant2']
              : data['participant1'];
          
          // Get the other user's details
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();
          
          final userData = userDoc.data() ?? {};
          
          // Return chat with user details
          return {
            'id': doc.id,
            'lastMessage': data['lastMessageText'] ?? '',
            'lastMessageTime': data['lastMessageTimestamp']?.toDate(),
            'unreadCount': data['unreadCount'] ?? 0,
            'userId': otherUserId,
            'displayName': userData['displayName'] ?? 'Unknown',
            'photoUrl': userData['photoUrl'],
            'isOnline': userData['isOnline'] ?? false,
            'lastSeen': userData['lastSeen']?.toDate(),
          };
        }),
      );
      
      setState(() {
        _chats = chats;
      });
    } catch (e) {
      ErrorHandler.showError(context, 'Error loading chats', e);
      rethrow;
    }
  }
  
  Future<void> _loadContacts() async {
    try {
      // Get the current user's contacts
      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('contacts')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('displayName')
          .get();
      
      final contacts = await Future.wait(
        contactsSnapshot.docs.map((doc) async {
          final data = doc.data();
          final contactId = data['contactId'];
          
          // Get the contact's user details
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(contactId)
              .get();
          
          final userData = userDoc.data() ?? {};
          
          // Return contact with user details
          return {
            'id': doc.id,
            'userId': contactId,
            'displayName': data['displayName'] ?? 'Unknown',
            'photoUrl': userData['photoUrl'],
            'isOnline': userData['isOnline'] ?? false,
            'lastSeen': userData['lastSeen']?.toDate(),
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
          };
        }),
      );
      
      setState(() {
        _contacts = contacts;
      });
    } catch (e) {
      ErrorHandler.showError(context, 'Error loading contacts', e);
      rethrow;
    }
  }
  
  void _navigateToChat(BuildContext context, String contactId, String contactName, String? photoUrl) {
    // First check if a chat exists with this contact
    _findOrCreateChat(contactId, contactName).then((chatId) {
      if (chatId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedChatScreen(
              chatId: chatId,
              contactId: contactId,
              contactName: contactName,
              contactPhotoUrl: photoUrl,
            ),
          ),
        ).then((_) {
          // Refresh chats when returning from chat screen
          _loadChats();
        });
      }
    });
  }
  
  Future<String?> _findOrCreateChat(String contactId, String contactName) async {
    try {
      // Check if chat already exists between the users
      final existingChatsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: _currentUserId)
          .get();
      
      for (final doc in existingChatsSnapshot.docs) {
        final data = doc.data();
        final participants = data['participants'] as List<dynamic>;
        
        if (participants.contains(contactId)) {
          return doc.id;
        }
      }
      
      // If no chat exists, create a new one
      final newChatRef = FirebaseFirestore.instance.collection('chats').doc();
      
      final now = DateTime.now();
      await newChatRef.set({
        'participant1': _currentUserId,
        'participant2': contactId,
        'participants': [_currentUserId, contactId],
        'createdAt': now,
        'lastMessageTimestamp': now,
        'lastMessageText': '',
        'lastMessageSenderId': '',
      });
      
      return newChatRef.id;
    } catch (e) {
      ErrorHandler.showError(context, 'Error creating chat', e);
      return null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PrivacyWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Janatonese',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          elevation: 1,
          actions: [
            // Add privacy toggle button
            PrivacyToggleButton(mini: true),
            
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Show search UI
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showOptionsMenu(context);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: 'Chats'),
              Tab(text: 'Contacts'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Chats Tab
            _buildChatsTab(),
            
            // Contacts Tab
            _buildContactsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Dynamic FAB action based on current tab
            if (_tabController.index == 0) {
              // New chat
              Navigator.pushNamed(context, '/add-contact');
            } else {
              // New contact
              Navigator.pushNamed(context, '/add-contact');
            }
          },
          backgroundColor: AppTheme.primaryColor,
          child: Icon(
            _tabController.index == 0 ? Icons.chat : Icons.person_add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  Widget _buildChatsTab() {
    if (_isLoading) {
      return const ChatListShimmer();
    }
    
    if (_error != null) {
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
              'Error loading chats',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadData,
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
    
    if (_chats.isEmpty) {
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
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with your contacts',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/add-contact');
              },
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadChats,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final isUnread = chat['unreadCount'] > 0;
          
          return _buildChatTile(chat, isUnread);
        },
      ),
    );
  }
  
  Widget _buildChatTile(Map<String, dynamic> chat, bool isUnread) {
    return Animate(
      effects: [
        FadeEffect(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: 50 * (_chats.indexOf(chat))),
        ),
      ],
      child: InkWell(
        onTap: () {
          _navigateToChat(
            context,
            chat['userId'],
            chat['displayName'],
            chat['photoUrl'],
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Profile picture
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: chat['photoUrl'] != null
                        ? NetworkImage(chat['photoUrl'])
                        : null,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: chat['photoUrl'] == null
                        ? Text(
                            chat['displayName'].isNotEmpty
                                ? chat['displayName'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  
                  // Online status indicator
                  if (chat['isOnline'] == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chat name
                    Text(
                      chat['displayName'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Last message
                    Text(
                      chat['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnread ? Colors.black87 : Colors.grey.shade600,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Timestamp and unread count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Timestamp
                  Text(
                    chat['lastMessageTime'] != null
                        ? _formatChatTime(chat['lastMessageTime'])
                        : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnread ? AppTheme.primaryColor : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Unread count
                  if (isUnread)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chat['unreadCount'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactsTab() {
    if (_isLoading) {
      return const ContactListShimmer();
    }
    
    if (_error != null) {
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
              'Error loading contacts',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadData,
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
    
    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add contacts to start chatting',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/add-contact');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadContacts,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          
          return _buildContactTile(contact);
        },
      ),
    );
  }
  
  Widget _buildContactTile(Map<String, dynamic> contact) {
    return Animate(
      effects: [
        FadeEffect(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: 50 * (_contacts.indexOf(contact))),
        ),
      ],
      child: InkWell(
        onTap: () {
          _navigateToChat(
            context,
            contact['userId'],
            contact['displayName'],
            contact['photoUrl'],
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Profile picture
              CircleAvatar(
                radius: 24,
                backgroundImage: contact['photoUrl'] != null
                    ? NetworkImage(contact['photoUrl'])
                    : null,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: contact['photoUrl'] == null
                    ? Text(
                        contact['displayName'].isNotEmpty
                            ? contact['displayName'][0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Contact info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact name
                    Text(
                      contact['displayName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (contact['email'] != null && contact['email'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          contact['email'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Actions
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                color: AppTheme.primaryColor,
                onPressed: () {
                  _navigateToChat(
                    context,
                    contact['userId'],
                    contact['displayName'],
                    contact['photoUrl'],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                color: Colors.blue,
                onPressed: () {
                  // Video call functionality would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video call coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
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
              leading: const Icon(Icons.group),
              title: const Text('New group'),
              onTap: () {
                Navigator.pop(context);
                // Create group chat logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Open settings screen
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
              leading: const Icon(Icons.lock),
              title: const Text('Encryption Details'),
              onTap: () {
                Navigator.pop(context);
                _showEncryptionExplainer(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text('Starred messages'),
              onTap: () {
                Navigator.pop(context);
                // Show starred messages
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
          ],
        ),
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
  
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await FirebaseAuth.instance.signOut();
                // Navigate to login screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              } catch (e) {
                ErrorHandler.showError(context, 'Error logging out', e);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  String _formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Format as time only for today
      return _formatTimeOnly(dateTime);
    } else if (messageDate == yesterday) {
      // Format as "Yesterday"
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      // Format as weekday for messages within a week
      final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdayNames[dateTime.weekday - 1];
    } else {
      // Format as short date for older messages
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatTimeOnly(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}