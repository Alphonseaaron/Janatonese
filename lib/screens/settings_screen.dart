import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/janatonese.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: ListView(
        children: [
          // User info section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              border: Border(
                bottom: BorderSide(
                  color: Colors.teal.shade100,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.teal,
                  child: Text(
                    user?.displayName.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // User name
                Text(
                  user?.displayName ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // User email
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                // Edit profile button
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to edit profile screen
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ),

          // Security section
          const ListTile(
            title: Text(
              'Security',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to change password screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Encryption Settings'),
            subtitle: const Text('Configure TOTP period and key length'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show encryption settings dialog
              _showEncryptionSettingsDialog();
            },
          ),

          // General settings section
          const ListTile(
            title: Text(
              'General Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            secondary: const Icon(Icons.notifications),
            value: _notificationsEnabled,
            activeColor: Colors.teal,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
            value: _darkMode,
            activeColor: Colors.teal,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              // Update app theme
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show language selection dialog
            },
          ),

          // About section
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Janatonese'),
            subtitle: const Text('Secure messaging with three-number encryption'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show about dialog
              _showAboutDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help screen
            },
          ),

          // Sign out button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Sign out
                _confirmSignOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // App version at bottom
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Janatonese v1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showEncryptionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encryption Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TOTP Period',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: 30,
              items: [
                DropdownMenuItem(value: 15, child: Text('15 seconds')),
                DropdownMenuItem(value: 30, child: Text('30 seconds')),
                DropdownMenuItem(value: 60, child: Text('60 seconds')),
              ],
              onChanged: (value) {
                // Update TOTP period
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Secret Key Length',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: 20,
              items: [
                DropdownMenuItem(value: 16, child: Text('16 characters')),
                DropdownMenuItem(value: 20, child: Text('20 characters')),
                DropdownMenuItem(value: 32, child: Text('32 characters')),
              ],
              onChanged: (value) {
                // Update key length
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Save encryption settings
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Janatonese'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.message,
              size: 48,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            const Text(
              'Janatonese',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text('Version 1.0.0'),
            const SizedBox(height: 16),
            const Text(
              'Janatonese is a secure messaging app that uses a unique TOTP-based encryption system. Each character in your message is encrypted as a set of three numbers, making your communications highly secure.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2023 Janatonese',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
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

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}