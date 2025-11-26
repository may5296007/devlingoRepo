import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // ================== INSCRIPTION ==================

  Future<UserCredential?> inscription({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String niveau,
    required DateTime birthday,
  }) async {
    try {
      final userCredential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'niveau': niveau,
        'role': 'user',
        'points': 0,
        'streak': 0,
        'badges': [],
        'jours_apprentissage': [],
        'coursCompletes': [],
        'dateCreation': FieldValue.serverTimestamp(),
        'birthday': Timestamp.fromDate(birthday),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ================== CONNEXION ==================

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

  // ================== GOOGLE ==================

  Future<UserCredential?> connexionGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(uid).set({
          'nom': googleUser.displayName?.split(' ').last ?? '',
          'prenom': googleUser.displayName?.split(' ').first ?? '',
          'email': googleUser.email,
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

      return userCredential;
    } catch (e) {
      throw Exception('Erreur lors de la connexion avec Google');
    }
  }

  // ================== DECONNEXION / RESET ==================

  Future<void> deconnexion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ================== PROFIL ==================

  Future<Map<String, dynamic>?> getProfilUtilisateur(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

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

  // ========== CALENDRIER & STREAK ==========

  /// Marquer aujourd'hui comme jour d'apprentissage complété
  Future<void> marquerJourComplete(String uid) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final docRef = _firestore.collection('users').doc(uid);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final data = snap.data() as Map<String, dynamic>? ?? {};

        final List<String> joursApprentissage =
            List<String>.from(data['jours_apprentissage'] ?? []);

        if (!joursApprentissage.contains(todayStr)) {
          joursApprentissage.add(todayStr);
        }

        final int newStreak = _calculerStreak(joursApprentissage);

        tx.set(
          docRef,
          {
            'jours_apprentissage': joursApprentissage,
            'streak': newStreak,
            'derniere_connexion': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      // log discret, pas de crash
      print('Erreur marquerJourComplete: $e');
    }
  }

  /// Calculer le streak (jours consécutifs)
  int _calculerStreak(List<String> joursApprentissage) {
    if (joursApprentissage.isEmpty) return 0;

    final dates = joursApprentissage
        .map((d) => DateTime.parse(d))
        .toList()
      ..sort((a, b) => b.compareTo(a)); // plus récent -> plus ancien

    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    for (final date in dates) {
      final normalized = DateTime(date.year, date.month, date.day);

      if (normalized.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (normalized.isBefore(checkDate)) {
        break;
      }
    }

    return streak;
  }

  /// Vérifier si un jour spécifique est complété
  Future<bool> estJourComplete(String uid, DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return false;

      final jours = List<String>.from(data['jours_apprentissage'] ?? []);
      return jours.contains(dateStr);
    } catch (_) {
      return false;
    }
  }

  /// Obtenir les jours complétés de la semaine actuelle
  Future<List<String>> getJoursCompletsSemaine(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return [];

      final List<String> joursApprentissage =
          List<String>.from(data['jours_apprentissage'] ?? []);

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final List<String> joursCompletsSemaine = [];

      for (final dateStr in joursApprentissage) {
        final d = DateTime.parse(dateStr);
        if (!d.isBefore(startOfWeek) && !d.isAfter(endOfWeek)) {
          joursCompletsSemaine.add(dateStr);
        }
      }

      return joursCompletsSemaine;
    } catch (e) {
      print('Erreur getJoursCompletsSemaine: $e');
      return [];
    }
  }

  /// Recalcule le streak au chargement si besoin
  Future<void> updateStreakSiNecessaire(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return;

      final joursApprentissage =
          List<String>.from(data['jours_apprentissage'] ?? []);
      final int currentStreak = data['streak'] ?? 0;
      final int recalculated = _calculerStreak(joursApprentissage);

      if (recalculated != currentStreak) {
        await _firestore.collection('users').doc(uid).update({
          'streak': recalculated,
        });
      }
    } catch (e) {
      print('Erreur updateStreakSiNecessaire: $e');
    }
  }
}
