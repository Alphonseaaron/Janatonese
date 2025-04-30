import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../utils/app_theme.dart';
import 'encryption_explainer.dart';

/// A walkthrough widget that introduces new users to the app's features
class AppWalkthrough extends StatefulWidget {
  final VoidCallback onComplete;
  final bool canSkip;
  
  const AppWalkthrough({
    Key? key,
    required this.onComplete,
    this.canSkip = true,
  }) : super(key: key);
  
  @override
  State<AppWalkthrough> createState() => _AppWalkthroughState();
}

class _AppWalkthroughState extends State<AppWalkthrough> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Welcome to Janatonese',
      'description': 'A secure messaging app that uses innovative three-number encryption to protect your conversations.',
      'asset': 'assets/animations/welcome.json',
      'color': Color(0xFF00796B),
    },
    {
      'title': 'End-to-End Encryption',
      'description': 'All messages are encrypted on your device and can only be decrypted by your intended recipient.',
      'asset': 'assets/animations/encryption.json',
      'color': Color(0xFF00695C),
    },
    {
      'title': 'Unique Three-Number System',
      'description': 'Each character you type is converted into a set of three random-looking numbers, making your messages secure.',
      'asset': 'assets/animations/numbers.json',
      'color': Color(0xFF004D40),
      'showDemo': true,
    },
    {
      'title': 'Secure File Sharing',
      'description': 'Share photos, documents, and more with the same level of encryption and security.',
      'asset': 'assets/animations/file_sharing.json',
      'color': Color(0xFF00796B),
    },
    {
      'title': 'Real-Time Status Updates',
      'description': 'See when your messages are delivered and read, and when your contacts are typing.',
      'asset': 'assets/animations/status.json',
      'color': Color(0xFF00695C),
    },
    {
      'title': 'You\'re All Set!',
      'description': 'Start chatting securely with your contacts. Your privacy is our priority.',
      'asset': 'assets/animations/done.json',
      'color': Color(0xFF004D40),
    },
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (widget.canSkip)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: widget.onComplete,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Main content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentStep = page;
                  });
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  final showDemo = step['showDemo'] ?? false;
                  
                  return Container(
                    color: step['color'],
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Animation
                                if (!showDemo)
                                  SizedBox(
                                    height: 220,
                                    width: 220,
                                    child: Lottie.asset(
                                      step['asset'],
                                      repeat: true,
                                      animate: true,
                                    ),
                                  ).animate().fadeIn(
                                    duration: 600.ms,
                                    curve: Curves.easeOut,
                                  ),
                                
                                // Title
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                                  child: Text(
                                    step['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ).animate().fadeIn(
                                    delay: 200.ms,
                                    duration: 600.ms,
                                  ).moveY(
                                    begin: 20,
                                    end: 0,
                                    delay: 200.ms,
                                    duration: 600.ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                
                                // Description
                                Text(
                                  step['description'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(
                                  delay: 400.ms,
                                  duration: 600.ms,
                                ),
                                
                                // Demo for encryption explainer
                                if (showDemo)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                                    child: SizedBox(
                                      height: 240,
                                      child: EncryptionExplainer(
                                        interactive: false,
                                      ),
                                    ),
                                  ).animate().fadeIn(
                                    delay: 600.ms,
                                    duration: 800.ms,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Bottom navigation
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 32.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back button
                              if (_currentStep > 0)
                                TextButton(
                                  onPressed: _previousStep,
                                  child: const Text(
                                    'Back',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 48),
                              
                              // Step indicators
                              Row(
                                children: List.generate(
                                  _steps.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: index == _currentStep ? 16 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: index == _currentStep
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Next/Done button
                              ElevatedButton(
                                onPressed: _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: step['color'],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _currentStep < _steps.length - 1 ? 'Next' : 'Get Started',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}