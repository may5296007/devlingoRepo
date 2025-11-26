import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Inscription avec email et mot de passe
  Future<UserCredential?> inscription({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String niveau,
    required DateTime birthday,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'niveau': niveau,
      'role': 'user',  // ⬅️ AJOUTE CETTE LIGNE
      'points': 0,
      'streak': 0,
      'badges': [],
      'dateCreation': FieldValue.serverTimestamp(),
      'birthday': Timestamp.fromDate(birthday),
    });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ✅ CONNEXION AVEC EMAIL ET MOT DE PASSE (CELLE QUI MANQUAIT)
  Future<UserCredential?> connexion({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Connexion avec Google
  Future<UserCredential?> connexionGoogle() async {
  try {
    if (kIsWeb) {
      // Web → Popup
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});
      UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
      
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _creerProfilGoogle(userCredential);
      }
      return userCredential;
    }
    
    // Mobile → GoogleSignIn
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Connexion annulée');
    
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    UserCredential userCredential = await _auth.signInWithCredential(credential);
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _creerProfilGoogle(userCredential);
    }
    return userCredential;
  } catch (e) {
    throw Exception('Erreur Google: $e');
  }
}

Future<void> _creerProfilGoogle(UserCredential userCredential) async {
  final user = userCredential.user!;
  await _firestore.collection('users').doc(user.uid).set({
    'nom': user.displayName?.split(' ').last ?? '',
    'prenom': user.displayName?.split(' ').first ?? '',
    'email': user.email,
    'niveau': 'débutant',
    'role': 'user',
    'points': 0,
    'badges': [],
    'streak': 0,
    'jours_apprentissage': [],
    'coursCompletes': [],
    'createdAt': FieldValue.serverTimestamp(),
  });
}

      

  // Déconnexion
  Future<void> deconnexion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Obtenir les données du profile utilisateur
  Future<Map<String, dynamic>?> getProfilUtilisateur(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Gestion des erreurs Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email';
      case 'invalid-email':
        return 'L\'adresse email est invalide';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return 'Une erreur est survenue: ${e.message}';
    }
  }

  // ========== SYSTÈME DE CALENDRIER ET STREAK ==========

  /// Marquer aujourd'hui comme jour d'apprentissage complété
  Future<void> marquerJourComplete(String uid) async {
    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      if (userData == null) return;

      List<String> joursApprentissage = List<String>.from(userData['jours_apprentissage'] ?? []);

      // Ajouter aujourd'hui si pas déjà fait
      if (!joursApprentissage.contains(dateString)) {
        joursApprentissage.add(dateString);

        // Calculer le nouveau streak
        int newStreak = _calculerStreak(joursApprentissage);

        await _firestore.collection('users').doc(uid).update({
          'jours_apprentissage': joursApprentissage,
          'streak': newStreak,
          'derniere_connexion': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur marquerJourComplete: $e');
    }
  }

  /// Calculer le streak (jours consécutifs)
  int _calculerStreak(List<String> joursApprentissage) {
    if (joursApprentissage.isEmpty) return 0;

    // Trier les dates du plus récent au plus ancien
    List<DateTime> dates = joursApprentissage
        .map((dateStr) => DateTime.parse(dateStr))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    for (DateTime date in dates) {
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);

      if (normalizedDate.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      } else if (normalizedDate.isBefore(checkDate)) {
        // Il y a un trou dans le streak
        break;
      }
    }

    return streak;
  }

  /// Vérifier si un jour spécifique est complété
  Future<bool> estJourComplete(String uid, DateTime date) async {
    try {
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      if (userData == null) return false;

      List<String> joursApprentissage = List<String>.from(userData['jours_apprentissage'] ?? []);
      return joursApprentissage.contains(dateString);
    } catch (e) {
      return false;
    }
  }

  /// Obtenir les jours complétés de la semaine actuelle
  Future<List<String>> getJoursCompletsSemaine(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      if (userData == null) return [];

      List<String> joursApprentissage = List<String>.from(userData['jours_apprentissage'] ?? []);

      // Obtenir les dates de la semaine actuelle
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

      // Filtrer les jours de la semaine actuelle
      List<String> joursCompletsSemaine = [];

      for (String dateStr in joursApprentissage) {
        DateTime date = DateTime.parse(dateStr);
        if (date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
            date.isBefore(endOfWeek.add(Duration(days: 1)))) {
          joursCompletsSemaine.add(dateStr);
        }
      }

      return joursCompletsSemaine;
    } catch (e) {
      print('Erreur getJoursCompletsSemaine: $e');
      return [];
    }
  }

  /// Mettre à jour le streak automatiquement (à appeler au chargement)
  Future<void> updateStreakSiNecessaire(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      if (userData == null) return;

      List<String> joursApprentissage = List<String>.from(userData['jours_apprentissage'] ?? []);
      int currentStreak = userData['streak'] ?? 0;
      int calculatedStreak = _calculerStreak(joursApprentissage);

      // Si le streak calculé est différent du streak actuel, on met à jour
      if (currentStreak != calculatedStreak) {
        await _firestore.collection('users').doc(uid).update({
          'streak': calculatedStreak,
        });
      }
    } catch (e) {
      print('Erreur updateStreakSiNecessaire: $e');
    }
  }
}