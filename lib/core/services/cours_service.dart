// Cleaned and improved CoursService code

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../legacy/langage_model.dart';
import '../../legacy/cours_model.dart';
import '../legacy/card_model.dart';

class CoursService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===============================
  // LANGAGES
  // ===============================

  Stream<List<LangageModel>> getAllLangages() {
    return _firestore
        .collection('langages')
        .orderBy('ordre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LangageModel.fromFirestore(doc))
            .toList());
  }

  Future<String> createLangage(
    String nom,
    String icon,
    String description,
  ) async {
    final count = await _firestore.collection('langages').get();

    final docRef = await _firestore.collection('langages').add({
      'nom': nom,
      'icon': icon,
      'description': description,
      'ordre': count.docs.length + 1,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // ===============================
  // COURS
  // ===============================

  Stream<List<CoursModel>> getCoursByLangage(String langageId) {
    return _firestore
        .collection('cours')
        .where('langageId', isEqualTo: langageId)
        .orderBy('ordre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoursModel.fromFirestore(doc))
            .toList());
  }

  Future<String> createCours({
    required String langageId,
    required String titre,
    String? description,
    required List<CardModel> cards,
  }) async {
    final existingCours = await _firestore
        .collection('cours')
        .where('langageId', isEqualTo: langageId)
        .get();

    final ordre = existingCours.docs.length + 1;

    final quizCount = cards.where((c) => c.type.toLowerCase() == 'quiz').length;
    final cardsData = cards.map((c) => c.toMap()).toList();

    final docRef = await _firestore.collection('cours').add({
      'langageId': langageId,
      'titre': titre,
      'description': description ?? '',
      'ordre': ordre,
      'totalCards': cards.length,
      'quizCount': quizCount,
      'cards': cardsData,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> updateCourseCards(String coursId, List<CardModel> cards) async {
    final quizCount = cards.where((c) => c.type == 'quiz').length;
    final exerciseCount = cards.where((c) => c.type == 'exercise').length;
    final cardsData = cards.map((c) => c.toMap()).toList();

    await _firestore.collection('cours').doc(coursId).update({
      'cards': cardsData,
      'totalCards': cards.length,
      'quizCount': quizCount,
      'exerciseCount': exerciseCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCours(String coursId) async {
    await _firestore.collection('cours').doc(coursId).delete();
  }

  // ===============================
  // PROGRESSION
  // ===============================

  Future<void> saveProgress(
    String coursId,
    int currentCard,
    int totalCards,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final progress = (currentCard / totalCards * 100).round();
    final completed = currentCard >= totalCards;

    await _firestore.collection('utilisateurs').doc(user.uid).set({
      'coursProgress': {
        coursId: {
          'progress': progress,
          'completed': completed,
          'lastCard': currentCard,
          'lastAccessed': FieldValue.serverTimestamp(),
        },
      },
    }, SetOptions(merge: true));

    if (completed) {
      await _firestore.collection('utilisateurs').doc(user.uid).update({
        'points': FieldValue.increment(100),
      });
    }
  }

  Future<Map<String, dynamic>> getProgress(String coursId) async {
    final user = _auth.currentUser;
    if (user == null) return {'progress': 0, 'completed': false};

    final doc = await _firestore.collection('utilisateurs').doc(user.uid).get();
    if (!doc.exists) return {'progress': 0, 'completed': false};

    final data = doc.data();
    final p = (data?['coursProgress'] ?? {})[coursId];

    return {
      'progress': p?['progress'] ?? 0,
      'completed': p?['completed'] ?? false,
    };
  }

  Future<void> updateCours(
    String id, {
    required String titre,
    String? description,
    required List<CardModel> cards,
  }) async {
    final quizCount = cards.where((c) => c.type == 'quiz').length;
    final exerciseCount = cards.where((c) => c.type == 'exercise').length;
    final cardsData = cards.map((c) => c.toMap()).toList();

    await _firestore.collection('cours').doc(id).update({
      'titre': titre,
      'description': description ?? '',
      'quizCount': quizCount,
      'exerciseCount': exerciseCount,
      'totalCards': cards.length,
      'cards': cardsData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}