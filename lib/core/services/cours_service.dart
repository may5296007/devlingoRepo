import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../legacy/langage_model.dart';
import '../../legacy/cours_model.dart';
import '../legacy/card_model.dart';
import 'role_service.dart';

class CoursService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RoleService _roleService = RoleService();

  // ==================== LANGAGES ====================

  // Récupérer tous les langages
  Stream<List<LangageModel>> getAllLangages() {
    return _firestore
        .collection('langages')
        .orderBy('nom')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LangageModel.fromFirestore(doc)).toList());
  }

  // Créer un langage
  Future<void> createLangage(String nom, String icon, String description) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final canCreate = await _roleService.canCreateCours();
    if (!canCreate) throw Exception('Permissions insuffisantes');

    await _firestore.collection('langages').add({
      'nom': nom,
      'icon': icon,
      'description': description,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== COURS ====================

  // Récupérer les cours d'un langage
  Stream<List<CoursModel>> getCoursByLangage(String langageId) {
    return _firestore
        .collection('cours')
        .where('langageId', isEqualTo: langageId)
        .orderBy('ordre')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CoursModel.fromFirestore(doc)).toList());
  }

  // Créer un cours
  Future<String> createCours({
    required String titre,
    required String langageId,
    required List<CardModel> cards,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final canCreate = await _roleService.canCreateCours();
    if (!canCreate) throw Exception('Permissions insuffisantes');

    // Obtenir le prochain ordre
    final existingCours = await _firestore
        .collection('cours')
        .where('langageId', isEqualTo: langageId)
        .get();
    final ordre = existingCours.docs.length + 1;

    final docRef = await _firestore.collection('cours').add({
      'titre': titre,
      'langageId': langageId,
      'ordre': ordre,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      if (description != null) 'description': description,
      'cards': cards.map((card) => card.toMap()).toList(),
    });

    return docRef.id;
  }

  // Modifier un cours
  // Dans votre cours_service.dart, mettez à jour la méthode updateCours :

Future<void> updateCours(
  String coursId, {
  String? titre,
  String? description,
  List<CardModel>? cards,
}) async {
  final Map<String, dynamic> updates = {};

  if (titre != null) {
    updates['titre'] = titre;
  }
  if (description != null) {
    updates['description'] = description;
  }
  if (cards != null) {
    // Convertir les cartes en Map en utilisant la méthode toMap() du CardModel
    updates['cards'] = cards.map((card) => card.toMap()).toList();
  }

  await _firestore.collection('cours').doc(coursId).update(updates);
}

  // Supprimer un cours
  Future<void> deleteCours(String coursId) async {
    final canDelete = await _roleService.canDeleteCours();
    if (!canDelete) throw Exception('Permissions insuffisantes');

    await _firestore.collection('cours').doc(coursId).delete();
  }

  // ==================== PROGRESSION ====================

  // Sauvegarder la progression d'un utilisateur
  Future<void> saveProgress(String coursId, int cardIndex, int totalCards) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final progress = ((cardIndex + 1) / totalCards * 100).round();
    final completed = cardIndex + 1 >= totalCards;

    await _firestore.collection('users').doc(user.uid).set({
      'coursProgress': {
        coursId: {
          'progress': progress,
          'completed': completed,
          'lastAccessed': FieldValue.serverTimestamp(),
        }
      }
    }, SetOptions(merge: true));
  }

  // Récupérer la progression d'un cours
  Future<Map<String, dynamic>> getProgress(String coursId) async {
    final user = _auth.currentUser;
    if (user == null) return {'progress': 0, 'completed': false};

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final coursProgress = doc.data()?['coursProgress'] as Map<String, dynamic>?;
    
    return coursProgress?[coursId] as Map<String, dynamic>? ?? 
           {'progress': 0, 'completed': false};
  }
}