import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/enhanced_chat_provider.dart';
import 'services/privacy_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/enhanced_home_screen.dart';
import 'screens/enhanced_chat_screen.dart';
import 'screens/real_time_chat_screen_with_privacy.dart';
import 'screens/add_contact_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/privacy_settings_screen.dart';
import 'utils/app_theme.dart';
import 'widgets/encryption_explainer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    
    setState(() {
      _showOnboarding = !onboardingComplete;
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => EnhancedChatProvider()),
        ChangeNotifierProvider(create: (_) => PrivacyProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Janatonese',
            theme: AppTheme.lightTheme(),
            home: !_initialized
              ? const SplashScreen()
              : _showOnboarding
                ? OnboardingScreen(
                    onFinish: () async {
                      // Mark onboarding as complete
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboardingComplete', true);
                      
                      setState(() {
                        _showOnboarding = false;
                      });
                    },
                  )
                : _getInitialScreen(authProvider),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const EnhancedHomeScreen(),
              '/add-contact': (context) => const AddContactScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/privacy-settings': (context) => const PrivacySettingsScreen(),
              '/encryption-explainer': (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Janatonese Encryption'),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 550,
                        child: EncryptionExplainer(),
                      ),
                    ],
                  ),
                ),
              ),
              '/onboarding': (context) => OnboardingScreen(
                onFinish: () async {
                  // Mark onboarding as complete
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboardingComplete', true);
                  
                  setState(() {
                    _showOnboarding = false;
                  });
                  
                  Navigator.of(context).pushReplacementNamed(
                    authProvider.isAuthenticated ? '/home' : '/login'
                  );
                },
              ),
            },
            // For dynamic routes like chat screen that need parameters
            onGenerateRoute: (settings) {
              if (settings.name == '/chat') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => RealTimeChatScreen(
                    chatId: args['chatId'],
                    contactId: args['contactId'],
                    contactName: args['contactName'] ?? 'Contact',
                    contactPhotoUrl: args['contactPhotoUrl'],
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
  
  // Helper to determine the initial screen
  Widget _getInitialScreen(AuthProvider authProvider) {
    if (authProvider.loading) {
      return const SplashScreen();
    } else if (authProvider.isAuthenticated) {
      return const EnhancedHomeScreen(); // Using the enhanced home screen
    } else {
      return const LoginScreen();
    }
  }
}

// A splash screen shown during app initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDarkColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeInAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/app_logo.svg',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Janatonese',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Secure Messaging with Three-Number Encryption',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 42),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.9)
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
