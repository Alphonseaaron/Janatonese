import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/**
 * Secure Storage Utility
 * Handles encrypted storage of sensitive information
 */
class SecureStorage {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  /**
   * Derive an encryption key from the user ID
   */
  static String _deriveEncryptionKey(String userId) {
    final bytes = utf8.encode(userId + 'Janatonese_Key_Salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /**
   * Simple XOR encryption/decryption
   */
  static String _xorEncryptDecrypt(String text, String key) {
    final result = StringBuffer();
    final keyBytes = utf8.encode(key);
    final textBytes = utf8.encode(text);

    for (var i = 0; i < textBytes.length; i++) {
      final keyByte = keyBytes[i % keyBytes.length];
      result.write(String.fromCharCode(textBytes[i] ^ keyByte));
    }

    return base64Encode(utf8.encode(result.toString()));
  }

  /**
   * Create a storage key based on userId, type and ID
   */
  static String _createStorageKey(String userId, String type, String id) {
    return 'janatonese_${userId}_${type}_$id';
  }

  /**
   * Store a shared secret
   */
  static Future<void> storeSharedSecret(String userId, String contactId, String secret) async {
    final key = _createStorageKey(userId, 'secret', contactId);
    final encryptedSecret = _xorEncryptDecrypt(secret, _deriveEncryptionKey(userId));
    await _storage.write(key: key, value: encryptedSecret);
  }

  /**
   * Retrieve a shared secret
   */
  static Future<String?> getSharedSecret(String userId, String contactId) async {
    final key = _createStorageKey(userId, 'secret', contactId);
    final encryptedSecret = await _storage.read(key: key);
    
    if (encryptedSecret == null) return null;
    
    return _xorEncryptDecrypt(
      utf8.decode(base64Decode(encryptedSecret)), 
      _deriveEncryptionKey(userId)
    );
  }

  /**
   * Remove a shared secret
   */
  static Future<void> removeSharedSecret(String userId, String contactId) async {
    final key = _createStorageKey(userId, 'secret', contactId);
    await _storage.delete(key: key);
  }

  /**
   * Store offline messages
   */
  static Future<void> storeOfflineMessages(String userId, String chatId, List<dynamic> messages) async {
    final key = _createStorageKey(userId, 'messages', chatId);
    final serialized = jsonEncode(messages);
    final encrypted = _xorEncryptDecrypt(serialized, _deriveEncryptionKey(userId));
    await _storage.write(key: key, value: encrypted);
  }

  /**
   * Retrieve offline messages
   */
  static Future<List<dynamic>> getOfflineMessages(String userId, String chatId) async {
    try {
      final key = _createStorageKey(userId, 'messages', chatId);
      final encrypted = await _storage.read(key: key);
      
      if (encrypted == null) return [];
      
      final decrypted = _xorEncryptDecrypt(
        utf8.decode(base64Decode(encrypted)), 
        _deriveEncryptionKey(userId)
      );
      
      return jsonDecode(decrypted);
    } catch (e) {
      print('Error retrieving offline messages: $e');
      return [];
    }
  }

  /**
   * Store a pending message
   */
  static Future<void> storePendingMessage(String userId, String chatId, dynamic message) async {
    final messages = await getPendingMessages(userId, chatId);
    messages.add(message);
    
    final key = _createStorageKey(userId, 'pending', chatId);
    final serialized = jsonEncode(messages);
    final encrypted = _xorEncryptDecrypt(serialized, _deriveEncryptionKey(userId));
    await _storage.write(key: key, value: encrypted);
  }

  /**
   * Get pending messages
   */
  static Future<List<dynamic>> getPendingMessages(String userId, String chatId) async {
    try {
      final key = _createStorageKey(userId, 'pending', chatId);
      final encrypted = await _storage.read(key: key);
      
      if (encrypted == null) return [];
      
      final decrypted = _xorEncryptDecrypt(
        utf8.decode(base64Decode(encrypted)), 
        _deriveEncryptionKey(userId)
      );
      
      return jsonDecode(decrypted);
    } catch (e) {
      print('Error retrieving pending messages: $e');
      return [];
    }
  }

  /**
   * Clear pending messages
   */
  static Future<void> clearPendingMessages(String userId, String chatId) async {
    final key = _createStorageKey(userId, 'pending', chatId);
    await _storage.delete(key: key);
  }
}