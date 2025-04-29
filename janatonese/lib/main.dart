import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/add_contact_screen.dart';
import 'screens/onboarding_screen.dart';

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
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Janatonese',
            theme: ThemeData(
              primarySwatch: Colors.teal,
              primaryColor: Colors.teal,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              fontFamily: 'Roboto',
              useMaterial3: true,
            ),
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
              '/home': (context) => const HomeScreen(),
              '/add-contact': (context) => const AddContactScreen(),
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
                final args = settings.arguments as Map<String, String>;
                return MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: args['chatId']!,
                    contactId: args['contactId']!,
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
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}

// A simple splash screen shown during app initialization
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.message,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Janatonese',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Secure Messaging with Three-Number Encryption',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
