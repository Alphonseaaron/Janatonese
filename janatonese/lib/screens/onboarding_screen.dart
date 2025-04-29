import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_page.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const OnboardingScreen({Key? key, this.onFinish}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;
  late AnimationController _animationController;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Janatonese',
      description: 'A secure messaging app with three-number encryption to keep your conversations private.',
      animationAsset: 'assets/images/welcome_animation.svg',
    ),
    OnboardingPage(
      title: 'Three-Number Encryption',
      description: 'Each character in your message is encrypted as a set of three numbers, making it virtually impossible to decode without the key.',
      animationAsset: 'assets/images/encryption_animation.svg',
    ),
    OnboardingPage(
      title: 'Secure Chats',
      description: 'Chat with friends knowing your messages are protected with end-to-end encryption. Only you and your contact can read them.',
      animationAsset: 'assets/images/secure_chat_animation.svg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
        _isLastPage = _currentPage == _pages.length - 1;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return OnboardingPageWidget(
                    page: page,
                    isActive: _currentPage == index,
                    animationController: _animationController,
                  );
                },
              ),
            ),
            // Page indicators
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    onPressed: _isLastPage ? null : _markOnboardingComplete,
                    child: Text(
                      _isLastPage ? '' : 'Skip',
                      style: TextStyle(
                        color: _isLastPage ? Colors.transparent : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: Theme.of(context).primaryColor,
                      dotColor: Colors.grey.shade300,
                    ),
                  ),
                  // Next or get started button
                  ElevatedButton(
                    onPressed: _isLastPage
                        ? _markOnboardingComplete
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      _isLastPage ? 'Get Started' : 'Next',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageWidget extends StatefulWidget {
  final OnboardingPage page;
  final bool isActive;
  final AnimationController animationController;

  const OnboardingPageWidget({
    Key? key,
    required this.page,
    required this.isActive,
    required this.animationController,
  }) : super(key: key);

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(OnboardingPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      widget.animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated title
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                widget.page.title,
                textStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF009688),
                ),
                speed: const Duration(milliseconds: 100),
              ),
            ],
            isRepeatingAnimation: false,
            totalRepeatCount: 1,
            displayFullTextOnTap: true,
          ),
          const SizedBox(height: 30),
          
          // Animation illustration
          Expanded(
            child: Center(
              child: widget.page.isVectorAnimation
                  ? SvgPicture.asset(
                      widget.page.animationAsset,
                      width: 240,
                      height: 240,
                    )
                  : Lottie.asset(
                      widget.page.animationAsset,
                      width: 240,
                      height: 240,
                      controller: widget.animationController,
                      onLoaded: (composition) {
                        widget.animationController.duration = composition.duration;
                        if (widget.isActive) {
                          widget.animationController.forward();
                        }
                      },
                    ),
            ),
          )
              .animate(
                target: widget.isActive ? 1 : 0,
              )
              .fadeIn(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
              )
              .slide(
                begin: const Offset(0.2, 0),
                end: const Offset(0, 0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ),
          
          const SizedBox(height: 30),
          
          // Description
          Text(
            widget.page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          )
              .animate(
                target: widget.isActive ? 1 : 0,
              )
              .fadeIn(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
              )
              .slide(
                begin: const Offset(0, 0.2),
                end: const Offset(0, 0),
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}