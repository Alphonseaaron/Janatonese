import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Initialize chat provider with current user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.firebaseUser != null) {
        Provider.of<ChatProvider>(context, listen: false)
            .initialize(authProvider.firebaseUser!.uid);
      }
    });
  }
  
  // Navigate between tabs
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List of screens for bottom navigation
    final List<Widget> screens = [
      const ContactsScreen(),
      const Text('Add Contact Screen'), // Placeholder for Add Contact screen
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Janatonese'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Show search dialog
              showSearch(
                context: context,
                delegate: ChatSearchDelegate(),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Add Contact',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.teal,
              onPressed: () {
                // Navigate to new chat screen
                Navigator.pushNamed(context, '/new-chat');
              },
              child: const Icon(Icons.chat, color: Colors.white),
            )
          : null,
    );
  }
}

// Search delegate for searching chats
class ChatSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    
    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search contacts or chats'),
      );
    }

    // Filter contacts based on query
    final filteredContacts = chatProvider.contacts.where((contact) {
      final user = chatProvider.contactUsers[contact.contactId];
      if (user == null) return false;
      
      final displayName = user.displayName.toLowerCase();
      final email = user.email.toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return displayName.contains(searchQuery) || email.contains(searchQuery);
    }).toList();

    if (filteredContacts.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        final user = chatProvider.contactUsers[contact.contactId];
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.teal,
            child: Text(
              user?.displayName.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(user?.displayName ?? 'Unknown'),
          subtitle: Text(user?.email ?? ''),
          onTap: () {
            // Navigate to chat screen
            if (contact.chatId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: contact.chatId!,
                    contactId: contact.contactId,
                  ),
                ),
              );
            }
            close(context, null);
          },
        );
      },
    );
  }
}