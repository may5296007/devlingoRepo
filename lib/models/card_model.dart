class CardModel {
  final String type; // 'lesson' ou 'quiz'
  final String titre;
  final String? contenu;
  final String? codeExample;
  final String? question;
  final List<String>? options;
  final int? correctAnswer;
  final String? explanation;

  CardModel({
    required this.type,
    required this.titre,
    this.contenu,
    this.codeExample,
    this.question,
    this.options,
    this.correctAnswer,
    this.explanation,
  });

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      type: map['type'] ?? 'lesson',
      titre: map['titre'] ?? '',
      contenu: map['contenu'],
      codeExample: map['codeExample'],
      question: map['question'],
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      correctAnswer: map['correctAnswer'],
      explanation: map['explanation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'titre': titre,
      if (contenu != null) 'contenu': contenu,
      if (codeExample != null) 'codeExample': codeExample,
      if (question != null) 'question': question,
      if (options != null) 'options': options,
      if (correctAnswer != null) 'correctAnswer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
    };
  }

  bool get isQuiz => type == 'quiz';
  bool get isLesson => type == 'lesson';
}