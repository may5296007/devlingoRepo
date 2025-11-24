import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

// Services
import 'core/services/auth_service.dart';

// Theme
import 'core/theme/theme_provider.dart';

// Routing
import 'core/routing/auth_wrapper.dart';

// Screens
import 'features/onboarding/view/onboarding_screen.dart';
import 'features/onboarding/view/welcome_screen.dart';
import 'features/auth/view/login_screen.dart';
import 'features/auth/view/signup_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/profile/view/profile_screen.dart';
import 'features/settings/view/settings_screen.dart';
import 'features/courses/view/cours_list_screen.dart';
import 'features/courses/admin/view/admin_cours_screen.dart';
import 'features/courses/view/course_detail_screen.dart';

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

  try {
    await SharedPreferences.getInstance();
    print('✅ SharedPreferences initialisé!');
  } catch (e) {
    print('⚠️ SharedPreferences pas disponible: $e');
  }
  
  runApp(const DevLingoApp());
}

class DevLingoApp extends StatelessWidget {
  const DevLingoApp({super.key});

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

            // 🎨 Thème dynamique
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            home: const AuthWrapper(),

            routes: {
              '/onboarding': (context) => const OnBoardingScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/cours': (context) => CoursListScreen(),
              '/admin-cours': (context) =>  AdminCoursScreen(),
              '/course-detail': (context) =>  CourseDetailScreen(),
            },
          );
        },
      ),
    );
  }
}
