import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated lock icon for privacy mode
class PrivacyLockAnimation extends StatefulWidget {
  final bool locked;
  final Color color;
  final double size;
  
  const PrivacyLockAnimation({
    Key? key,
    required this.locked,
    this.color = Colors.white,
    this.size = 48.0,
  }) : super(key: key);

  @override
  _PrivacyLockAnimationState createState() => _PrivacyLockAnimationState();
}

class _PrivacyLockAnimationState extends State<PrivacyLockAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 70,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start the animation if we're locked
    if (widget.locked) {
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(PrivacyLockAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Play animation when lock status changes
    if (widget.locked != oldWidget.locked) {
      if (widget.locked) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Icon(
                widget.locked ? Icons.lock : Icons.lock_open,
                color: widget.color,
                size: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Privacy mode splash screen animation
class PrivacySplashAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final bool activate;
  
  const PrivacySplashAnimation({
    Key? key,
    required this.onComplete,
    required this.activate,
  }) : super(key: key);

  @override
  _PrivacySplashAnimationState createState() => _PrivacySplashAnimationState();
}

class _PrivacySplashAnimationState extends State<PrivacySplashAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lockScaleAnimation;
  late Animation<double> _rippleScaleAnimation;
  late Animation<double> _rippleOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _lockScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.5),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.0),
        weight: 70,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _rippleScaleAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _rippleOpacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
      ),
    );
    
    // Start animation and call onComplete when done
    _controller.forward().then((_) {
      widget.onComplete();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect
            Opacity(
              opacity: _rippleOpacityAnimation.value,
              child: Container(
                width: MediaQuery.of(context).size.width * _rippleScaleAnimation.value,
                height: MediaQuery.of(context).size.width * _rippleScaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.activate ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                ),
              ),
            ),
            
            // Lock icon
            Transform.scale(
              scale: _lockScaleAnimation.value,
              child: Icon(
                widget.activate ? Icons.lock : Icons.lock_open,
                size: 80,
                color: widget.activate ? Colors.red : Colors.green,
              ),
            ),
            
            // Status text
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.4,
              child: Opacity(
                opacity: _textOpacityAnimation.value,
                child: Text(
                  widget.activate ? 'Privacy Mode Activated' : 'Privacy Mode Deactivated',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.activate ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}