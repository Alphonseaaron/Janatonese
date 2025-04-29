import 'package:flutter/material.dart';
import '../widgets/app_walkthrough.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  
  const OnboardingScreen({
    Key? key, 
    required this.onFinish,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return AppWalkthrough(
      onComplete: widget.onFinish,
      canSkip: true,
    );
  }
}