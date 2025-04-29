import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/privacy_service.dart';
import '../utils/app_theme.dart';
import '../widgets/privacy_animations.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showSplash = false;
  bool _activateSplash = false;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, _) {
        // Show splash animation if toggled
        if (_showSplash) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: PrivacySplashAnimation(
              activate: _activateSplash,
              onComplete: () {
                setState(() {
                  _showSplash = false;
                });
              },
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Privacy Settings'),
            actions: [
              PrivacyToggleButton(),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy mode card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  privacyProvider.isPrivacyModeEnabled 
                                      ? Icons.lock 
                                      : Icons.lock_open,
                                  color: privacyProvider.isPrivacyModeEnabled 
                                      ? Colors.red 
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Privacy Mode',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: privacyProvider.isPrivacyModeEnabled,
                              activeColor: Colors.red,
                              onChanged: (value) {
                                // Show splash animation when toggling
                                setState(() {
                                  _showSplash = true;
                                  _activateSplash = value;
                                });
                                
                                // Toggle privacy mode
                                privacyProvider.togglePrivacyMode();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'When enabled, your chats will be blurred and hidden behind a privacy screen until unlocked with a tap.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Settings section
                const Text(
                  'Auto-Lock Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Auto-lock timer
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.timer_outlined),
                            SizedBox(width: 8),
                            Text(
                              'Auto-Lock Timer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Automatically re-lock chats after being inactive:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Auto-lock duration options
                        ...buildTimerOptions(privacyProvider),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Biometric authentication
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.fingerprint),
                                SizedBox(width: 8),
                                Text(
                                  'Biometric Authentication',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: privacyProvider.isBiometricAuthEnabled,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (value) {
                                // In a real app, we would check if biometrics is available
                                // For now, simply toggle the setting
                                privacyProvider.setBiometricAuth(value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Require fingerprint or face authentication to unlock chats when privacy mode is enabled.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Lock now button
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock, color: Colors.white),
                    label: const Text(
                      'Lock Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: privacyProvider.isPrivacyModeEnabled
                        ? () {
                            privacyProvider.lockNow();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('App locked')),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Privacy explanation
                const Card(
                  elevation: 1,
                  color: Color(0xFFEEF3FF),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Privacy mode helps you keep your conversations private when someone might be looking over your shoulder. It adds an extra layer of security beyond the app\'s built-in encryption.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper method to build timer selection options
  List<Widget> buildTimerOptions(PrivacyProvider provider) {
    final selectedDuration = provider.autoLockDuration;
    
    final options = [
      {'label': 'Immediately', 'duration': const Duration(seconds: 0)},
      {'label': '30 seconds', 'duration': const Duration(seconds: 30)},
      {'label': '1 minute', 'duration': const Duration(minutes: 1)},
      {'label': '5 minutes', 'duration': const Duration(minutes: 5)},
      {'label': '15 minutes', 'duration': const Duration(minutes: 15)},
      {'label': '30 minutes', 'duration': const Duration(minutes: 30)},
    ];
    
    return options.map((option) {
      final duration = option['duration'] as Duration;
      final isSelected = duration == selectedDuration;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: RadioListTile<Duration>(
          title: Text(option['label'] as String),
          value: duration,
          groupValue: selectedDuration,
          onChanged: (value) {
            if (value != null) {
              provider.setAutoLockDuration(value);
            }
          },
          activeColor: AppTheme.primaryColor,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      );
    }).toList();
  }
}