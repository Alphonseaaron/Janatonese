import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

/// Service that handles user online presence
/// Uses Firebase Realtime Database for fast presence updates
/// and Firestore for user profile data
class PresenceService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  
  // Connection status
  bool _isOnline = false;
  
  // References
  DatabaseReference? _connectedRef;
  DatabaseReference? _userStatusRef;
  
  // Stream subscriptions
  StreamSubscription? _connectedSubscription;
  
  // Callbacks
  Function(String userId, bool isOnline)? onUserStatusChanged;
  
  // Singleton pattern
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();
  
  /// Initialize the presence service for the current user
  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Setup connection monitoring
    _connectedRef = _rtdb.ref('.info/connected');
    _userStatusRef = _rtdb.ref('status/${user.uid}');
    
    // Listen for connection state changes
    _connectedSubscription = _connectedRef!.onValue.listen((event) {
      final isConnected = event.snapshot.value as bool? ?? false;
      
      if (isConnected) {
        _updateOnlineStatus(true);
      }
    });
    
    // Set offline status on disconnect
    _userStatusRef!.onDisconnect().update({
      'state': 'offline',
      'last_changed': ServerValue.timestamp,
    });
    
    // Set initial online status
    await _updateOnlineStatus(true);
  }
  
  /// Update the user's online status
  Future<void> _updateOnlineStatus(bool isOnline) async {
    if (_isOnline == isOnline) return;
    _isOnline = isOnline;
    
    final user = _auth.currentUser;
    if (user == null || _userStatusRef == null) return;
    
    try {
      // Update status in RTDB
      await _userStatusRef!.update({
        'state': isOnline ? 'online' : 'offline',
        'last_changed': ServerValue.timestamp,
      });
      
      // Also update in Firestore for persistent storage
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }
  
  /// Listen to a user's online status
  StreamSubscription listenToUserStatus(String userId) {
    // First check RTDB for real-time updates
    final statusRef = _rtdb.ref('status/$userId');
    
    return statusRef.onValue.listen((event) {
      bool isOnline = false;
      
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        isOnline = data?['state'] == 'online';
      }
      
      if (onUserStatusChanged != null) {
        onUserStatusChanged!(userId, isOnline);
      }
    });
  }
  
  /// Set the user as offline
  Future<void> setOffline() async {
    await _updateOnlineStatus(false);
  }
  
  /// Clean up
  void dispose() {
    _connectedSubscription?.cancel();
    _connectedSubscription = null;
    _setOfflineAndPersist();
  }
  
  /// Set offline status and wait for it to persist
  Future<void> _setOfflineAndPersist() async {
    final user = _auth.currentUser;
    if (user == null || _userStatusRef == null) return;
    
    try {
      // Clear onDisconnect handler
      await _userStatusRef!.onDisconnect().cancel();
      
      // Set offline status
      await _updateOnlineStatus(false);
    } catch (e) {
      print('Error setting offline status: $e');
    }
  }
}