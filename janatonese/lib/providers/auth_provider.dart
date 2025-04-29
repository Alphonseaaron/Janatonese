import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/firebase_service.dart';
import '../models/user.dart' as app_models;

class AuthErrorResult {
  final String code;
  final String message;
  
  AuthErrorResult({required this.code, required this.message});
  
  @override
  String toString() => message;
}

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  app_models.User? _user;
  firebase_auth.User? _firebaseUser;
  bool _loading = true;
  String? _lastErrorCode;

  // Getters
  app_models.User? get user => _user;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  bool get loading => _loading;
  bool get isAuthenticated => _firebaseUser != null;
  String? get lastErrorCode => _lastErrorCode;

  // Constructor with initialization
  AuthProvider() {
    _initializeAuth();
  }

  // Initialize the authentication state
  Future<void> _initializeAuth() async {
    _loading = true;
    notifyListeners();

    try {
      // Listen to auth state changes
      firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
        _firebaseUser = user;
        
        if (user != null) {
          try {
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
          } catch (e) {
            debugPrint('Error getting user profile: $e');
            // Continue with authentication even if profile has issues
            // We'll create/fetch the profile on next login attempt
          }
        } else {
          _user = null;
        }
        
        _loading = false;
        notifyListeners();
      }, onError: (error) {
        debugPrint('Auth state change error: $error');
        _loading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _loading = false;
      notifyListeners();
    }
  }

  // Register a new user
  Future<void> register(String email, String password, String displayName) async {
    try {
      final credentials = await _firebaseService.signUp(email, password);
      _lastErrorCode = null;
      
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
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastErrorCode = e.code;
      throw AuthErrorResult(
        code: e.code,
        message: e.message ?? 'An authentication error occurred',
      );
    } catch (e) {
      _lastErrorCode = 'unknown';
      throw AuthErrorResult(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  // Log in existing user
  Future<void> login(String email, String password) async {
    try {
      await _firebaseService.signIn(email, password);
      _lastErrorCode = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastErrorCode = e.code;
      throw AuthErrorResult(
        code: e.code,
        message: e.message ?? 'An authentication error occurred',
      );
    } catch (e) {
      _lastErrorCode = 'unknown';
      throw AuthErrorResult(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _lastErrorCode = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastErrorCode = e.code;
      throw AuthErrorResult(
        code: e.code,
        message: e.message ?? 'Error signing out',
      );
    } catch (e) {
      _lastErrorCode = 'unknown';
      throw AuthErrorResult(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    if (_firebaseUser == null || _user == null) {
      throw AuthErrorResult(
        code: 'not-authenticated',
        message: 'You must be logged in to update your profile',
      );
    }

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
          displayName: displayName ?? _user!.displayName,
          photoURL: photoURL ?? _user!.photoURL,
          updatedAt: DateTime.now(),
        );
        
        notifyListeners();
      }
      _lastErrorCode = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastErrorCode = e.code;
      throw AuthErrorResult(
        code: e.code,
        message: e.message ?? 'Error updating profile',
      );
    } catch (e) {
      _lastErrorCode = 'unknown';
      throw AuthErrorResult(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    if (_firebaseUser == null || _user == null) {
      throw AuthErrorResult(
        code: 'not-authenticated',
        message: 'You must be logged in to update your password',
      );
    }

    if (_firebaseUser!.email == null) {
      throw AuthErrorResult(
        code: 'no-email',
        message: 'Cannot change password for accounts without an email',
      );
    }

    try {
      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: currentPassword,
      );
      
      await _firebaseUser!.reauthenticateWithCredential(credential);
      
      // Update password
      await _firebaseUser!.updatePassword(newPassword);
      _lastErrorCode = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastErrorCode = e.code;
      throw AuthErrorResult(
        code: e.code,
        message: e.message ?? 'Error updating password',
      );
    } catch (e) {
      _lastErrorCode = 'unknown';
      throw AuthErrorResult(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _lastErrorCode = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastErrorCode = e.code;
      throw AuthErrorResult(
        code: e.code,
        message: e.message ?? 'Error sending password reset email',
      );
    } catch (e) {
      _lastErrorCode = 'unknown';
      throw AuthErrorResult(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }
  
  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final methods = await firebase_auth.FirebaseAuth.instance
          .fetchSignInMethodsForEmail(email);
      _lastErrorCode = null;
      return methods.isNotEmpty;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastErrorCode = e.code;
      if (e.code == 'invalid-email') {
        throw AuthErrorResult(
          code: e.code,
          message: 'The email address is invalid',
        );
      }
      return false;
    } catch (e) {
      _lastErrorCode = 'unknown';
      return false;
    }
  }
}