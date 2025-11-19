import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/view/home_screen.dart';
import '../../features/onboarding/view/onboarding_screen.dart';
import '../../features/onboarding/view/welcome_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    // Utilisateur connecté
    if (user != null) {
      print('✅ Utilisateur connecté: ${user.email}');
      return const HomeScreen();
    }

    // Pas connecté → check onboarding
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final hasSeenOnboarding = snapshot.data ?? false;

        if (hasSeenOnboarding) {
          return const WelcomeScreen();
        }

        return const OnBoardingScreen();
      },
    );
  }
}

Future<bool> _hasSeenOnboarding() async {
  // Pour l'instant: toujours false comme ton ancienne implémentation.
  // On branchera SharedPreferences proprement quand on refactorera l'onboarding.
  await Future.delayed(const Duration(milliseconds: 500));
  return false;
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8F0FE),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
