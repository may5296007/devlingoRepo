import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'providers/ theme_provider.dart';
import 'screens/cours/cours_list_screen.dart';
import 'screens/cours/admin/admin_cours_screen.dart';
import 'screens/cours/course_detail_screen.dart';



// Importation des écrans
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès!');
  } catch (e) {
    print('❌ Erreur Firebase: $e');
  }

  // ✅ Initialiser SharedPreferences pour le Web
  try {
    await SharedPreferences.getInstance();
    print('✅ SharedPreferences initialisé!');
  } catch (e) {
    print('⚠️ SharedPreferences pas disponible: $e');
  }
  
  runApp(DevLingoApp());
}

class DevLingoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'DevLingo',
            debugShowCheckedModeBanner: false,
            
            // 🎨 Thèmes dynamiques
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            home: AuthWrapper(),
            routes: {
              '/onboarding': (context) => OnBoardingScreen(),
              '/welcome': (context) => WelcomeScreen(),
              '/login': (context) => LoginScreen(),
              '/signup': (context) => SignUpScreen(),
              '/home': (context) => HomeScreen(),
              '/profile': (context) => ProfileScreen(),
              '/settings': (context) => SettingsScreen(),
              '/cours': (context) => CoursListScreen(),        // ⬅️ AJOUTE CETTE LIGNE
              '/admin-cours': (context) => AdminCoursScreen(), 
              '/course-detail': (context) => CourseDetailScreen(),
            },

          );
        },
      ),
    );
  }
}

// Wrapper qui gère l'état d'authentification
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    // Si l'utilisateur est connecté
    if (user != null) {
      print('✅ Utilisateur connecté: ${user.email}');
      return HomeScreen();
    }

    // Si l'utilisateur n'est pas connecté, on vérifie s'il a déjà vu l'onboarding
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        // Si l'utilisateur a déjà vu l'onboarding, on va direct au Welcome
        if (snapshot.data == true) {
          return WelcomeScreen();
        }

        // Sinon, on montre l'onboarding
        return OnBoardingScreen();
      },
    );
  }

  Future<bool> _hasSeenOnboarding() async {
    // TODO: Implémenter avec SharedPreferences
    // Pour l'instant, on retourne false pour toujours montrer l'onboarding
    await Future.delayed(Duration(milliseconds: 500));
    return false;
  }
}

// Écran de chargement
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8F0FE),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo DevLingo
              Text(
                '</DevLingo>',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F80ED),
                  fontFamily: 'monospace',
                ),
              ),
              SizedBox(height: 40),
              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}