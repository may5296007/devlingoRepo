// lib/legacy/card_model.dart

/// Modèle d'une "carte" de cours (leçon ou quiz)
class CardModel {
  final String id;

  /// Type de carte : ex. "lesson", "quiz"
  final String type;

  /// Titre de la carte
  final String title;

  /// Contenu texte principal (pour les leçons)
  final String? content;

  /// Exemple de code éventuel
  final String? codeExample;

  /// Explication affichée après un quiz / complément
  final String? explanation;

  /// Options pour les quiz à choix multiple
  final List<String> options;

  /// Bonne réponse pour les quiz
  final String? correctAnswer;

  CardModel({
    required this.id,
    required this.type,
    required this.title,
    this.content,
    this.codeExample,
    this.explanation,
    List<String>? options,
    this.correctAnswer, String? question, required String reponse,
  }) : options = options ?? const [];

  /// Création depuis une Map Firestore
  /// On ne passe qu'une seule Map => corrige l'erreur "2 positional arguments expected"
  factory CardModel.fromMap(Map<String, dynamic> data) {
    // On accepte plusieurs clés possibles pour être compatible
    final rawOptions = data['options'];

    return CardModel(
      id: (data['id'] ?? '') as String,
      type: (data['type'] ?? 'lesson') as String,
      title: (data['titre'] ?? data['title'] ?? '') as String,
      content: (data['contenu'] ?? data['content']) as String?,
      codeExample: data['codeExample'] as String?,
      explanation: data['explanation'] as String?,
      options: rawOptions is List
          ? rawOptions.map((e) => e.toString()).toList()
          : const [],
      correctAnswer: data['correctAnswer'] as String?, reponse: '',
    );
  }

  /// Conversion vers Map pour stockage dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'titre': title,
      'contenu': content,
      'codeExample': codeExample,
      'explanation': explanation,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }

  // ====== Getters de compatibilité avec l'ancien code ======

  /// L'ancien code utilise `card.titre`
  String get titre => title;

  /// L'ancien code utilise `card.contenu`
  String? get contenu => content;

  /// L'ancien code utilise `card.isQuiz` / `card.isLesson`
  bool get isQuiz => type.toLowerCase() == 'quiz';
  bool get isLesson => type.toLowerCase() == 'lesson';

  get question => null;

  get reponse => null;
}
