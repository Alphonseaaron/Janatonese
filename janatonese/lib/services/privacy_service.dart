import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for managing privacy mode state
class PrivacyProvider extends ChangeNotifier {
  bool _isPrivacyModeEnabled = false;
  bool _isBiometricAuthEnabled = false;
  Duration _autoLockDuration = const Duration(minutes: 5);
  DateTime? _lastUnlockedTime;
  
  bool get isPrivacyModeEnabled => _isPrivacyModeEnabled;
  bool get isBiometricAuthEnabled => _isBiometricAuthEnabled;
  Duration get autoLockDuration => _autoLockDuration;
  bool get isAutoLockActive => _shouldAutoLock();
  
  PrivacyProvider() {
    _loadSettings();
  }
  
  // Load saved privacy settings
  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isPrivacyModeEnabled = prefs.getBool('privacy_mode_enabled') ?? false;
    _isBiometricAuthEnabled = prefs.getBool('biometric_auth_enabled') ?? false;
    _autoLockDuration = Duration(minutes: prefs.getInt('auto_lock_minutes') ?? 5);
    
    // If we're loading and privacy mode is enabled, reset the last unlocked time
    if (_isPrivacyModeEnabled) {
      _lastUnlockedTime = null;
    }
    
    notifyListeners();
  }
  
  // Toggle privacy mode on/off
  void togglePrivacyMode() {
    _isPrivacyModeEnabled = !_isPrivacyModeEnabled;
    
    // If disabling privacy mode, clear the last unlocked time
    if (!_isPrivacyModeEnabled) {
      _lastUnlockedTime = null;
    }
    
    _saveSettings();
    notifyListeners();
  }
  
  // Enable/disable biometric authentication requirement
  void setBiometricAuth(bool enabled) {
    _isBiometricAuthEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }
  
  // Update auto-lock duration
  void setAutoLockDuration(Duration duration) {
    _autoLockDuration = duration;
    _saveSettings();
    notifyListeners();
  }
  
  // Records when privacy mode was unlocked
  void recordUnlock() {
    _lastUnlockedTime = DateTime.now();
    notifyListeners();
  }
  
  // Check if we need to automatically lock based on inactivity
  bool _shouldAutoLock() {
    if (!_isPrivacyModeEnabled || _lastUnlockedTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_lastUnlockedTime!);
    return difference >= _autoLockDuration;
  }
  
  // Lock the app immediately
  void lockNow() {
    if (_isPrivacyModeEnabled) {
      _lastUnlockedTime = null;
      notifyListeners();
    }
  }
  
  // Save privacy settings to shared preferences
  Future<void> _saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_mode_enabled', _isPrivacyModeEnabled);
    await prefs.setBool('biometric_auth_enabled', _isBiometricAuthEnabled);
    await prefs.setInt('auto_lock_minutes', _autoLockDuration.inMinutes);
  }
}

// Floating action button for quick privacy toggle
class PrivacyToggleFAB extends StatelessWidget {
  const PrivacyToggleFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, _) {
        final isPrivacyModeActive = privacyProvider.isPrivacyModeEnabled;
        
        return FloatingActionButton(
          heroTag: 'privacy_toggle_fab',
          mini: true,
          backgroundColor: isPrivacyModeActive 
              ? Colors.red.shade700
              : Colors.green.shade700,
          onPressed: () {
            privacyProvider.togglePrivacyMode();
            
            // Show feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isPrivacyModeActive 
                      ? 'Privacy mode disabled' 
                      : 'Privacy mode enabled'
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Icon(
            isPrivacyModeActive ? Icons.lock : Icons.lock_open,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

// App bar button for privacy toggle
class PrivacyToggleButton extends StatelessWidget {
  final bool mini;
  
  const PrivacyToggleButton({
    Key? key,
    this.mini = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, _) {
        final isPrivacyModeActive = privacyProvider.isPrivacyModeEnabled;
        
        return IconButton(
          icon: Icon(
            isPrivacyModeActive ? Icons.lock : Icons.lock_open,
            color: isPrivacyModeActive ? Colors.red : Colors.green,
            size: mini ? 20 : 24,
          ),
          onPressed: () {
            privacyProvider.togglePrivacyMode();
            
            // Show feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isPrivacyModeActive 
                      ? 'Privacy mode disabled' 
                      : 'Privacy mode enabled'
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          tooltip: isPrivacyModeActive ? 'Disable Privacy Mode' : 'Enable Privacy Mode',
        );
      },
    );
  }
}