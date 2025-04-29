import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/firebase_service.dart';
import '../models/user.dart' as app_models;

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  app_models.User? _user;
  firebase_auth.User? _firebaseUser;
  bool _loading = true;

  // Getters
  app_models.User? get user => _user;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  bool get loading => _loading;
  bool get isAuthenticated => _firebaseUser != null;

  // Constructor with initialization
  AuthProvider() {
    _initializeAuth();
  }

  // Initialize the authentication state
  Future<void> _initializeAuth() async {
    _loading = true;
    notifyListeners();

    // Listen to auth state changes
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
      _firebaseUser = user;
      
      if (user != null) {
        // Get or create user profile
        _user = await _firebaseService.getUserProfile(user.uid);
        
        if (_user == null) {
          // Create profile if it doesn't exist
          final newUser = app_models.User(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
            photoURL: user.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await _firebaseService.createUserProfile(user.uid, newUser);
          _user = newUser;
        }
      } else {
        _user = null;
      }
      
      _loading = false;
      notifyListeners();
    });
  }

  // Register a new user
  Future<void> register(String email, String password, String displayName) async {
    try {
      final credentials = await _firebaseService.signUp(email, password);
      
      // Update display name
      await credentials.user?.updateDisplayName(displayName);
      
      // Create user profile
      if (credentials.user != null) {
        final newUser = app_models.User(
          id: credentials.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _firebaseService.createUserProfile(credentials.user!.uid, newUser);
      }
    } catch (e) {
      // Rethrow to be handled by UI
      rethrow;
    }
  }

  // Log in existing user
  Future<void> login(String email, String password) async {
    try {
      await _firebaseService.signIn(email, password);
    } catch (e) {
      // Rethrow to be handled by UI
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      // Rethrow to be handled by UI
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    if (_firebaseUser == null || _user == null) return;

    try {
      final userId = _firebaseUser!.uid;
      final updates = <String, dynamic>{};
      
      if (displayName != null && displayName.isNotEmpty) {
        updates['displayName'] = displayName;
        await _firebaseUser!.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        updates['photoURL'] = photoURL;
        await _firebaseUser!.updatePhotoURL(photoURL);
      }
      
      if (updates.isNotEmpty) {
        updates['updatedAt'] = DateTime.now();
        await _firebaseService.updateUserProfile(userId, updates);
        
        // Update local user object
        _user = _user!.copyWith(
          displayName: displayName,
          photoURL: photoURL,
        );
        
        notifyListeners();
      }
    } catch (e) {
      // Rethrow to be handled by UI
      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    if (_firebaseUser == null || _user == null) return;

    try {
      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: currentPassword,
      );
      
      await _firebaseUser!.reauthenticateWithCredential(credential);
      
      // Update password
      await _firebaseUser!.updatePassword(newPassword);
    } catch (e) {
      // Rethrow to be handled by UI
      rethrow;
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      // Rethrow to be handled by UI
      rethrow;
    }
  }
}