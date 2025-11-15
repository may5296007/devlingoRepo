import 'package:cloud_firestore/cloud_firestore.dart';

class LangageModel {
  final String id;
  final String nom;
  final String icon;
  final String description;
  final String createdBy;
  final DateTime createdAt;

  LangageModel({
    required this.id,
    required this.nom,
    required this.icon,
    required this.description,
    required this.createdBy,
    required this.createdAt,
  });

  factory LangageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LangageModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      icon: data['icon'] ?? '📚',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'icon': icon,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}