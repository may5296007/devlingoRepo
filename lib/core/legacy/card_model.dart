class CardModel {
  final String id;
  final String type; // 'lesson', 'quiz', 'example', 'exercise'
  final String title;
  final String? content;
  final String? codeExample;
  final String? explanation;
  
  // Pour les quiz
  final List<String>? options;
  final String? correctAnswer;
  
  // Pour les exercices de code
  final String? exercisePrompt;      // La consigne de l'exercice
  final String? exerciseStarterCode; // Code de départ (template)
  final String? exerciseSolution;    // Solution attendue
  final String? exerciseHint;        // Indice
  final List<String>? exerciseTests; // Tests à vérifier
  
  // Anciens champs (compatibilité)
  final String? question;
  final String reponse;

  CardModel({
    required this.id,
    required this.type,
    required this.title,
    this.content,
    this.codeExample,
    this.explanation,
    this.options,
    this.correctAnswer,
    this.exercisePrompt,
    this.exerciseStarterCode,
    this.exerciseSolution,
    this.exerciseHint,
    this.exerciseTests,
    this.question,
    this.reponse = '', String? answer, String? code,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'content': content,
      'codeExample': codeExample,
      'explanation': explanation,
      'options': options,
      'correctAnswer': correctAnswer,
      'exercisePrompt': exercisePrompt,
      'exerciseStarterCode': exerciseStarterCode,
      'exerciseSolution': exerciseSolution,
      'exerciseHint': exerciseHint,
      'exerciseTests': exerciseTests,
      'question': question,
      'reponse': reponse,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] ?? '',
      type: map['type'] ?? 'lesson',
      title: map['title'] ?? map['titre'] ?? '',
      content: map['content'] ?? map['contenu'],
      codeExample: map['codeExample'],
      explanation: map['explanation'],
      options: map['options'] != null 
          ? List<String>.from(map['options']) 
          : null,
      correctAnswer: map['correctAnswer'],
      exercisePrompt: map['exercisePrompt'],
      exerciseStarterCode: map['exerciseStarterCode'],
      exerciseSolution: map['exerciseSolution'],
      exerciseHint: map['exerciseHint'],
      exerciseTests: map['exerciseTests'] != null
          ? List<String>.from(map['exerciseTests'])
          : null,
      question: map['question'],
      reponse: map['reponse'] ?? '',
    );
  }

  get answer => null;

  get code => null;

  CardModel copyWith({
    String? id,
    String? type,
    String? title,
    String? content,
    String? codeExample,
    String? explanation,
    List<String>? options,
    String? correctAnswer,
    String? exercisePrompt,
    String? exerciseStarterCode,
    String? exerciseSolution,
    String? exerciseHint,
    List<String>? exerciseTests,
    String? question,
    String? reponse,
  }) {
    return CardModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      codeExample: codeExample ?? this.codeExample,
      explanation: explanation ?? this.explanation,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      exercisePrompt: exercisePrompt ?? this.exercisePrompt,
      exerciseStarterCode: exerciseStarterCode ?? this.exerciseStarterCode,
      exerciseSolution: exerciseSolution ?? this.exerciseSolution,
      exerciseHint: exerciseHint ?? this.exerciseHint,
      exerciseTests: exerciseTests ?? this.exerciseTests,
      question: question ?? this.question,
      reponse: reponse ?? this.reponse,
    );
  }
}