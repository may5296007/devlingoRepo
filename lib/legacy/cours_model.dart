import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/legacy/card_model.dart';  // ✅ CORRIGÉ (sans _OLD)

class CoursModel {
  final String id;
  final String titre;
  final String langageId;
  final int ordre;
  final String createdBy;
  final DateTime createdAt;
  final List<CardModel> cards;
  final String? description;

  CoursModel({
    required this.id,
    required this.titre,
    required this.langageId,
    required this.ordre,
    required this.createdBy,
    required this.createdAt,
    required this.cards,
    this.description,
  });

  factory CoursModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoursModel(
      id: doc.id,
      titre: data['titre'] ?? '',
      langageId: data['langageId'] ?? '',
      ordre: data['ordre'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
      cards: (data['cards'] as List<dynamic>?)
              ?.map((card) => CardModel.fromMap(card as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titre': titre,
      'langageId': langageId,
      'ordre': ordre,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (description != null) 'description': description,
      'cards': cards.map((card) => card.toMap()).toList(),
    };
  }

  int get totalCards => cards.length;
  
  int get quizCount => cards.where((c) => c.type == 'quiz').length;
  
  int get lessonCount => cards.where((c) => c.type == 'lesson').length;
  
  int get exerciseCount => cards.where((c) => c.type == 'exercise').length;  // ✅ AJOUTÉ
}