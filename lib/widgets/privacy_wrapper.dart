import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/privacy_service.dart';
import 'privacy_animations.dart';

/// A widget that wraps content with a privacy lock overlay when privacy mode is enabled
class PrivacyWrapper extends StatefulWidget {
  final Widget child;
  final String? customMessage;
  final bool enforcePrivacy;
  
  const PrivacyWrapper({
    Key? key,
    required this.child,
    this.customMessage,
    this.enforcePrivacy = false,
  }) : super(key: key);

  @override
  _PrivacyWrapperState createState() => _PrivacyWrapperState();
}

class _PrivacyWrapperState extends State<PrivacyWrapper> with SingleTickerProviderStateMixin {
  bool _locked = false;
  bool _animating = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Create animation controller for lock/unlock transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Initial state check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivacyStatus();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Check if privacy mode is active and update lock status
  void _checkPrivacyStatus() {
    final privacyProvider = Provider.of<PrivacyProvider>(context, listen: false);
    final shouldBeLocked = widget.enforcePrivacy || privacyProvider.isPrivacyModeEnabled;
    
    if (shouldBeLocked != _locked) {
      setState(() {
        _locked = shouldBeLocked;
        
        if (_locked) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }
  
  // Handle unlock tap
  void _handleUnlock() {
    if (_animating) return;
    
    final privacyProvider = Provider.of<PrivacyProvider>(context, listen: false);
    
    // If we have biometric auth enabled, we should trigger that here
    // For now, just toggle the lock without biometrics
    
    setState(() {
      _animating = true;
      _locked = false;
    });
    
    privacyProvider.recordUnlock();
    _animationController.reverse().then((_) {
      setState(() {
        _animating = false;
      });
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPrivacyStatus();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, _) {
        final shouldBeLocked = widget.enforcePrivacy || privacyProvider.isPrivacyModeEnabled;
        
        // If lock status changed, update animations
        if (shouldBeLocked != _locked && !_animating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _locked = shouldBeLocked;
              
              if (_locked) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            });
          });
        }
        
        // Stack to overlay privacy screen
        return Stack(
          children: [
            // The main content
            widget.child,
            
            // The privacy overlay (shown when locked)
            if (_locked || _animationController.value > 0)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: GestureDetector(
                      onTap: _handleUnlock,
                      child: Container(
                        color: Colors.black.withOpacity(0.9),
                        width: double.infinity,
                        height: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated lock
                            SizedBox(
                              height: 120,
                              width: 120,
                              child: PrivacyLockAnimation(
                                locked: true,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Custom message or default
                            Text(
                              widget.customMessage ?? 'Tap to unlock',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}