import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../utils/app_theme.dart';
import '../utils/janatonese.dart';

/// A widget that visually explains the Janatonese three-number encryption system
/// with interactive animations and step-by-step guides
class EncryptionExplainer extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool interactive;

  const EncryptionExplainer({
    Key? key,
    this.onComplete,
    this.interactive = true,
  }) : super(key: key);

  @override
  State<EncryptionExplainer> createState() => _EncryptionExplainerState();
}

class _EncryptionExplainerState extends State<EncryptionExplainer> with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  late final AnimationController _controller;
  late final AnimationController _characterController;
  
  final TextEditingController _messageController = TextEditingController();
  String _encryptedResult = '';
  List<int> _encryptionNumbers = [];
  String _sampleMessage = 'Hello';
  bool _showDecryption = false;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _messageController.text = _sampleMessage;
    
    // Generate sample encryption
    _generateEncryption();
    
    // Start the animation
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _characterController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  void _generateEncryption() {
    // Use the actual Janatonese encryption method
    final message = _messageController.text;
    if (message.isNotEmpty) {
      // Create the encrypted version of the message
      final encrypted = JanatoneseEncryption.encrypt(message);
      setState(() {
        _encryptedResult = encrypted;
        
        // Extract the three numbers from each character
        _encryptionNumbers = [];
        for (int i = 0; i < message.length; i++) {
          final encodedChar = JanatoneseEncryption.encodeCharacter(message[i]);
          _encryptionNumbers.addAll(encodedChar);
        }
      });
    }
  }
  
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        if (_currentStep == 2) {
          _showDecryption = true;
        }
      });
      _controller.reset();
      _controller.forward();
    } else {
      // Last step, call onComplete if provided
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep < 2) {
          _showDecryption = false;
        }
      });
      _controller.reset();
      _controller.forward();
    }
  }
  
  // Builds the current step's content
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIntroduction();
      case 1:
        return _buildEncryptionDemo();
      case 2:
        return _buildDecryptionDemo();
      case 3:
        return _buildSecurityFeatures();
      default:
        return Container();
    }
  }
  
  // Step 1: Introduction to Janatonese
  Widget _buildIntroduction() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'The Three-Number Encryption System',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.security,
                size: 60,
                color: AppTheme.primaryColor,
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).shimmer(
                delay: 1.seconds,
                duration: 1.seconds,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'Janatonese converts each character of your message into a set of three random-looking numbers.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This makes your messages appear as meaningless number sequences to anyone who might intercept them.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Only someone with the Janatonese app can convert these numbers back into the original text.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.interactive)
          _buildNavButtons(),
      ],
    ).animate().fade(duration: 500.ms);
  }
  
  // Step 2: Encryption Demonstration
  Widget _buildEncryptionDemo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Encryption in Action',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        if (widget.interactive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter a message to encrypt',
              ),
              onChanged: (_) => _generateEncryption(),
              maxLength: 12, // Limit to keep visualization manageable
            ),
          ),
        const SizedBox(height: 20),
        _buildEncryptionAnimation(),
        const SizedBox(height: 24),
        if (widget.interactive)
          _buildNavButtons(),
      ],
    ).animate().fade(duration: 500.ms);
  }
  
  // Step 3: Decryption Demonstration
  Widget _buildDecryptionDemo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Decryption Process',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDecryptionAnimation(),
              const SizedBox(height: 16),
              const Text(
                'When receiving a message, Janatonese automatically converts the number sets back to text.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Each three-number set corresponds to exactly one character, making decryption accurate.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.interactive)
          _buildNavButtons(),
      ],
    ).animate().fade(duration: 500.ms);
  }
  
  // Step 4: Security Features
  Widget _buildSecurityFeatures() {
    final features = [
      {'icon': Icons.verified_user, 'text': 'End-to-end encryption'},
      {'icon': Icons.visibility_off, 'text': 'No stored messages on server'},
      {'icon': Icons.lock_clock, 'text': 'Time-based number generation'},
      {'icon': Icons.security, 'text': 'Brute-force attack protection'},
    ];
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Security Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Janatonese offers comprehensive security:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ...List.generate(
                features.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        features[index]['icon'] as IconData,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ).animate(
                        delay: (index * 200).ms,
                      ).fadeIn(
                        duration: 500.ms,
                      ).scale(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          features[index]['text'] as String,
                          style: const TextStyle(fontSize: 16),
                        ).animate(
                          delay: (index * 200 + 100).ms,
                        ).fadeIn(
                          duration: 500.ms,
                        ).moveX(
                          begin: 20,
                          end: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your privacy is our priority. Messages are only visible to you and your intended recipient.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ).animate(
                delay: 1.seconds,
              ).fadeIn(
                duration: 800.ms,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.interactive)
          _buildNavButtons(isLastStep: true),
      ],
    ).animate().fade(duration: 500.ms);
  }
  
  // Build navigation buttons
  Widget _buildNavButtons({bool isLastStep = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          ElevatedButton(
            onPressed: _previousStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16),
                SizedBox(width: 4),
                Text('Back'),
              ],
            ),
          )
        else
          const SizedBox(width: 88), // Placeholder for alignment
          
        // Step indicators
        Row(
          children: List.generate(
            _totalSteps,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentStep
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
        
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isLastStep ? 'Finish' : 'Next'),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }
  
  // Encryption Animation
  Widget _buildEncryptionAnimation() {
    final message = _messageController.text;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Original Message:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Encryption visualization
          SizedBox(
            height: 100,
            child: message.isEmpty
                ? const Center(
                    child: Text('Enter a message to see encryption'),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      message.length,
                      (index) => _buildCharacterEncryption(message[index], index),
                    ),
                  ),
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Encrypted Result:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              _encryptedResult,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'monospace',
                color: Colors.grey.shade800,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  // Individual character encryption animation
  Widget _buildCharacterEncryption(String character, int charIndex) {
    if (_encryptionNumbers.length < (charIndex + 1) * 3) {
      return const SizedBox();
    }
    
    final num1 = _encryptionNumbers[charIndex * 3];
    final num2 = _encryptionNumbers[charIndex * 3 + 1];
    final num3 = _encryptionNumbers[charIndex * 3 + 2];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              character,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .shimmer(
            delay: (charIndex * 200).ms,
            duration: 1.seconds,
            color: AppTheme.primaryColor.withOpacity(0.7),
          ),
          Icon(
            Icons.arrow_downward,
            size: 14,
            color: Colors.grey.shade600,
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$num1',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '$num2',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '$num3',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
            delay: (charIndex * 300).ms,
            duration: 500.ms,
          ).moveY(
            begin: 10,
            end: 0,
            delay: (charIndex * 300).ms,
            duration: 500.ms,
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
  
  // Decryption Animation
  Widget _buildDecryptionAnimation() {
    final message = _messageController.text;
    
    if (message.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text('Enter a message to see decryption'),
        ),
      );
    }
    
    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          message.length,
          (index) => _buildCharacterDecryption(message[index], index),
        ),
      ),
    );
  }
  
  // Individual character decryption animation
  Widget _buildCharacterDecryption(String character, int charIndex) {
    if (_encryptionNumbers.length < (charIndex + 1) * 3) {
      return const SizedBox();
    }
    
    final num1 = _encryptionNumbers[charIndex * 3];
    final num2 = _encryptionNumbers[charIndex * 3 + 1];
    final num3 = _encryptionNumbers[charIndex * 3 + 2];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$num1',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '$num2',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '$num3',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_downward,
            size: 14,
            color: Colors.grey.shade600,
          ),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              character,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
          .animate(
            delay: (charIndex * 300).ms,
          )
          .fadeIn(
            duration: 500.ms,
          )
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            curve: Curves.elasticOut,
            duration: 800.ms,
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: (charIndex * 200).ms,
      duration: 500.ms,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildStepContent(),
      ),
    );
  }
}