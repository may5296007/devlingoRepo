import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../legacy/langage_model.dart';
import '../../legacy/cours_model.dart';
import '../legacy/card_model.dart';

class CoursService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========================================
  // LANGAGES
  // ========================================

  /// Récupère tous les langages
  Stream<List<LangageModel>> getAllLangages() {
    print('📚 Chargement des langages...');

    return _firestore.collection('langages').orderBy('ordre').snapshots().map((
      snapshot,
    ) {
      print('✅ ${snapshot.docs.length} langage(s) trouvé(s)');
      return snapshot.docs
          .map((doc) => LangageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Crée un nouveau langage
  Future<String> createLangage(
    String nom,
    String icon,
    String description,
  ) async {
    try {
      print('🔨 Création du langage: $nom');

      // Compter les langages existants pour l'ordre
      final count = await _firestore.collection('langages').get();

      final docRef = await _firestore.collection('langages').add({
        'nom': nom,
        'icon': icon,
        'description': description,
        'ordre': count.docs.length + 1,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Langage créé avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur création langage: $e');
      rethrow;
    }
  }

  // ========================================
  // COURS - REQUÊTE CORRIGÉE
  // ========================================

  /// ✅ REQUÊTE CORRIGÉE - Récupère les cours par langageId
  Stream<List<CoursModel>> getCoursByLangage(String langageId) {
    print('🔍 Recherche des cours pour langageId: $langageId');

    return _firestore
        .collection('cours') // ✅ Collection racine
        .where('langageId', isEqualTo: langageId) // ✅ Filtre
        .orderBy('ordre') // ✅ Tri (nécessite l'index)
        .snapshots()
        .map((snapshot) {
          print('📦 Cours trouvés: ${snapshot.docs.length}');

          return snapshot.docs.map((doc) {
            final data = doc.data();
            print(
              '   📄 ${doc.id}: ${data['titre']} (ordre: ${data['ordre']})',
            );
            return CoursModel.fromFirestore(doc);
          }).toList();
        })
        .handleError((error) {
          print('❌ Erreur récupération cours: $error');
          if (error.toString().contains('index')) {
            print('💡 SOLUTION: Crée l\'index Firestore !');
            print('   1. Va sur Firebase Console → Indexes');
            print('   2. Crée un index composite:');
            print('      Collection: cours');
            print('      Fields: langageId (Ascending), ordre (Ascending)');
          }
          throw error;
        });
  }

  // ========================================
  // CRÉATION DE COURS - DÉJÀ CORRECTE
  // ========================================

  /// Crée un nouveau cours
  Future<String> createCours({
    required String langageId,
    required String titre,
    String? description,
    required List<CardModel> cards,
  }) async {
    try {
      print('🔨 Création du cours: $titre');
      print('   langageId: $langageId');
      print('   Nombre de cartes: ${cards.length}');

      // Compter les cours existants pour ce langage
      final existingCours = await _firestore
          .collection('cours')
          .where('langageId', isEqualTo: langageId)
          .get();

      final ordre = existingCours.docs.length + 1;
      print('   ordre: $ordre');

      // Compter les quiz
      final quizCount = cards
          .where((c) => c.type.toLowerCase() == 'quiz')
          .length;

      // Convertir les cartes en Map
      final cardsData = cards.map((card) => card.toMap()).toList();

      // ✅ Créer dans la collection racine avec langageId
      final docRef = await _firestore.collection('cours').add({
        'langageId': langageId, // ✅ IMPORTANT
        'titre': titre,
        'description': description ?? '',
        'ordre': ordre,
        'totalCards': cards.length,
        'quizCount': quizCount,
        'cards': cardsData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Cours créé avec succès: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur création cours: $e');
      rethrow;
    }
  }

  /// Met à jour un cours existant
  Future<void> updateCours(
    String coursId, {
    required String titre,
    String? description,
    required List<CardModel> cards,
  }) async {
    try {
      print('🔄 Mise à jour du cours: $coursId');

      final quizCount = cards
          .where((c) => c.type.toLowerCase() == 'quiz')
          .length;
      final cardsData = cards.map((card) => card.toMap()).toList();

      await _firestore.collection('cours').doc(coursId).update({
        'titre': titre,
        'description': description ?? '',
        'totalCards': cards.length,
        'quizCount': quizCount,
        'cards': cardsData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Cours mis à jour');
    } catch (e) {
      print('❌ Erreur mise à jour cours: $e');
      rethrow;
    }
  }

  /// Supprime un cours
  Future<void> deleteCours(String coursId) async {
    try {
      print('🗑️ Suppression du cours: $coursId');
      await _firestore.collection('cours').doc(coursId).delete();
      print('✅ Cours supprimé');
    } catch (e) {
      print('❌ Erreur suppression cours: $e');
      rethrow;
    }
  }

  // ========================================
  // PROGRESSION
  // ========================================

  /// Sauvegarde la progression d'un utilisateur
  Future<void> saveProgress(
    String coursId,
    int currentCard,
    int totalCards,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ Utilisateur non connecté');
        return;
      }

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

      print('✅ Progression sauvegardée: $progress%');

      if (completed) {
        await _firestore.collection('utilisateurs').doc(user.uid).update({
          'points': FieldValue.increment(100),
        });
        print('✅ +100 points ajoutés');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde progression: $e');
    }
  }

  /// Récupère la progression d'un utilisateur
  Future<Map<String, dynamic>> getProgress(String coursId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'progress': 0, 'completed': false};
      }

      final userDoc = await _firestore
          .collection('utilisateurs')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return {'progress': 0, 'completed': false};
      }

      final data = userDoc.data();
      final coursProgress = data?['coursProgress'] as Map<String, dynamic>?;
      final progress = coursProgress?[coursId] as Map<String, dynamic>?;

      return {
        'progress': progress?['progress'] ?? 0,
        'completed': progress?['completed'] ?? false,
      };
    } catch (e) {
      print('❌ Erreur récupération progression: $e');
      return {'progress': 0, 'completed': false};
    }
  }
    /// Supprime un langage + tous ses cours
  Future<void> deleteLangage(String langageId) async {
    try {
      print('🗑️ Suppression du langage: $langageId');

      // 1) Récupérer tous les cours liés à ce langage
      final coursSnap = await _firestore
          .collection('cours')
          .where('langageId', isEqualTo: langageId)
          .get();

      // 2) Batch pour tout supprimer proprement
      final batch = _firestore.batch();

      for (final doc in coursSnap.docs) {
        batch.delete(doc.reference);
      }

      // 3) Supprimer le langage lui-même
      final langageRef = _firestore.collection('langages').doc(langageId);
      batch.delete(langageRef);

      await batch.commit();

      print('✅ Langage + ${coursSnap.docs.length} cours supprimés');
    } catch (e) {
      print('❌ Erreur suppression langage: $e');
      rethrow;
    }
  }

}
