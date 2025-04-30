import 'dart:math';
import 'package:otp/otp.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class JanatoneseEncryption {
  // Constants
  static const int defaultPeriod = 30; // Default TOTP period in seconds
  static const int defaultDigits = 3; // Number of digits for each character
  static const int secretLength = 20; // Default secret key length

  // Generate a random shared secret for TOTP
  static String generateSharedSecret() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'; // Base32 characters
    return List.generate(secretLength, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Verify if a shared secret is valid
  static bool verifySharedSecret(String secret) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    if (secret.length < 16) return false; // Too short
    
    // Check if all characters are valid base32
    for (var char in secret.split('')) {
      if (!base32Chars.contains(char)) return false;
    }
    
    return true;
  }

  // Encrypt a message using TOTP-based three-number system
  static String encrypt(String message, String sharedSecret, {int period = defaultPeriod}) {
    if (message.isEmpty) return '';

    final List<String> encryptedChars = [];
    
    for (int i = 0; i < message.length; i++) {
      final char = message[i];
      
      // Use character code + position as factor for TOTP
      final charCode = char.codeUnitAt(0);
      final seed = _generateSeed(charCode, i);
      
      // Get the TOTP code for this character
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final counter = (now ~/ period) + seed;
      
      // Generate a TOTP value for this character using otp package
      final totpValue = OTP.generateTOTPCodeString(
        sharedSecret, 
        counter, 
        length: defaultDigits, 
        algorithm: Algorithm.SHA1,
        isGoogle: false
      );
      
      encryptedChars.add(totpValue);
    }
    
    return encryptedChars.join(' ');
  }

  // Decrypt a message using TOTP-based three-number system
  static String decrypt(String encryptedMessage, String sharedSecret, {int period = defaultPeriod}) {
    if (encryptedMessage.isEmpty) return '';

    final parts = encryptedMessage.split(' ');
    final List<String> decryptedChars = [];
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final baseCounter = now ~/ period;
    
    // For non-real-time decryption (can decrypt messages from the past)
    // Try current timeframe and a few previous ones
    List<int> possibleBaseCounters = [baseCounter, baseCounter - 1, baseCounter - 2];
    
    for (int i = 0; i < parts.length; i++) {
      final encryptedChar = parts[i];
      bool found = false;
      
      // Try all possible character codes
      for (int charCode = 32; charCode <= 126 && !found; charCode++) { // ASCII printable range
        for (final counter in possibleBaseCounters) {
          final seed = _generateSeed(charCode, i);
          final testCounter = counter + seed;
          
          // Generate expected TOTP for this character and counter
          final expectedTOTP = OTP.generateTOTPCodeString(
            sharedSecret, 
            testCounter, 
            length: defaultDigits, 
            algorithm: Algorithm.SHA1,
            isGoogle: false
          );
          
          if (expectedTOTP == encryptedChar) {
            decryptedChars.add(String.fromCharCode(charCode));
            found = true;
            break;
          }
        }
      }
      
      // If no matching character found, add a placeholder
      if (!found) {
        decryptedChars.add('�');
      }
    }
    
    return decryptedChars.join();
  }
  
  // Generate a seed value based on character code and position
  static int _generateSeed(int charCode, int position) {
    final combinedInput = '$charCode:$position';
    final bytes = utf8.encode(combinedInput);
    final digest = sha1.convert(bytes);
    
    // Use first 4 bytes of hash as an integer
    int seed = 0;
    for (int i = 0; i < 4; i++) {
      seed = (seed << 8) | digest.bytes[i];
    }
    
    // Use modulo to keep the seed within a reasonable range
    return seed % 1000;
  }
}