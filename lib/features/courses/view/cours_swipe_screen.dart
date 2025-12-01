import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/code_exercise_card.dart';
import '../../../core/legacy/card_model.dart';

class CoursSwipeScreen extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic> courseData;
  final Map<String, dynamic> langageData;

  const CoursSwipeScreen({
    Key? key,
    required this.courseId,
    required this.courseData,
    required this.langageData,
  }) : super(key: key);

  @override
  State<CoursSwipeScreen> createState() => _CoursSwipeScreenState();
}

class _CoursSwipeScreenState extends State<CoursSwipeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  int _currentCardIndex = 0;
  bool _showAnswer = false;

  List<dynamic> get cards => widget.courseData['cards'] as List<dynamic>? ?? [];
  
  // Convertir les données Firestore en CardModel
  CardModel _cardFromFirestore(Map<String, dynamic> data) {
    return CardModel(
      id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: data['type']?.toString() ?? 'lesson',
      title: data['title']!.toString(),
      question: data['question']?.toString(),
      answer: data['answer']?.toString(),
      code: data['code']?.toString(),
      content: data['content']?.toString(),
      options: data['options'] != null ? List<String>.from(data['options']) : null,
      correctAnswer: data['correctAnswer']?.toString(),
      explanation: data['explanation']?.toString(),
      codeExample: data['codeExample']?.toString(),
      // Champs pour les exercices
      exercisePrompt: data['exercisePrompt']?.toString(),
      exerciseStarterCode: data['exerciseStarterCode']?.toString(),
      exerciseSolution: data['exerciseSolution']?.toString(),
      exerciseHint: data['exerciseHint']?.toString(),
      exerciseTests: data['exerciseTests'] != null ? List<String>.from(data['exerciseTests']) : null,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = cards.isEmpty ? 0.0 : (_currentCardIndex + 1) / cards.length;

    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.courseData['titre']?.toString() ?? 'Cours'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune carte disponible pour ce cours',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseData['titre']?.toString() ?? 'Cours',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${_currentCardIndex + 1} / ${cards.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: _currentCardIndex < cards.length
          ? _buildCardView(isDark)
          : _buildCompletionView(isDark),
    );
  }

  Widget _buildCardView(bool isDark) {
    final currentCardData = cards[_currentCardIndex] as Map<String, dynamic>;
    final currentCard = _cardFromFirestore(currentCardData);
    final type = currentCard.type;

    // ✅ Si c'est un exercice, utiliser CodeExerciseCard
    if (type == 'exercise') {
      return CodeExerciseCard(
        key: ValueKey(_currentCardIndex),
        card: currentCard,
        onComplete: (isCorrect) {
          if (isCorrect) {
            // Auto-passer à la carte suivante après 2 secondes
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _handleNextCard();
              }
            });
          }
        },
      );
    }

    // Pour les autres types de cartes (lesson, quiz, example)
    final question = currentCard.question ?? 
                    currentCard.content ?? 
                    'Aucune question';
                    
    final answer = currentCard.answer ?? 
                  currentCard.correctAnswer ?? 
                  'Aucune réponse';
                  
    final code = currentCard.code ?? currentCard.codeExample;
    final options = currentCard.options;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Type de carte
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getTypeColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getTypeIcon(type), color: _getTypeColor(type), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _getTypeLabel(type),
                    style: TextStyle(
                      color: _getTypeColor(type),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Carte principale
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: isDark
                      ? Border.all(color: const Color(0xFF3C445C), width: 2)
                      : null,
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      Text(
                        question,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Code (si présent)
                      if (code != null && code.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFF4EC9B0),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Options (pour les quiz)
                      if (type == 'quiz' && options != null && options.isNotEmpty) ...[
                        ...options.map((option) {
                          final isCorrect = option == answer;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _showAnswer = true;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _showAnswer
                                      ? (isCorrect
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1))
                                      : Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _showAnswer
                                        ? (isCorrect ? Colors.green : Colors.red)
                                        : Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _showAnswer
                                              ? (isCorrect ? Colors.green : Colors.red)
                                              : Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ),
                                    if (_showAnswer)
                                      Icon(
                                        isCorrect ? Icons.check_circle : Icons.cancel,
                                        color: isCorrect ? Colors.green : Colors.red,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ] else if (_showAnswer) ...[
                        // Réponse
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Réponse',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              if (answer.contains('print') || answer.contains('def') || answer.contains('{')) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : const Color(0xFF2D2D2D),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      answer,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        color: Color(0xFF4EC9B0),
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  answer,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                              
                              if (currentCard.explanation != null) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, 
                                      color: Colors.blue.shade700, 
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Explication',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentCard.explanation!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Boutons selon le type de carte
            // LESSON : Seulement "Suivant" (pas de "Voir la réponse")
            // QUIZ/EXAMPLE : "Voir la réponse" puis "Revoir" + "Suivant"
            if (type == 'lesson')
              // ✅ LESSON : Un seul bouton "Suivant"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _handleNextCard,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: Text(
                    _currentCardIndex < cards.length - 1 ? 'Suivant' : 'Terminer',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              )
            else if (!_showAnswer)
              // ✅ QUIZ/EXAMPLE : Bouton "Voir la réponse"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAnswer = true;
                    });
                  },
                  icon: const Icon(Icons.visibility, color: Colors.white),
                  label: const Text(
                    'Voir la réponse',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              )
            else
              // ✅ QUIZ/EXAMPLE : Boutons "Revoir" + "Suivant"
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAnswer = false;
                          });
                        },
                        icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
                        label: Text(
                          'Revoir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _handleNextCard,
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                        label: Text(
                          _currentCardIndex < cards.length - 1 ? 'Suivant' : 'Terminer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _handleNextCard() async {
    if (_currentCardIndex < cards.length - 1) {
      await _saveProgress(_currentCardIndex + 1);

      setState(() {
        _currentCardIndex++;
        _showAnswer = false;
      });
    } else {
      await _saveProgress(cards.length);

      setState(() {
        _currentCardIndex++;
      });
    }
  }

  Future<void> _saveProgress(int cardIndex) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final progress = (cardIndex / cards.length * 100).round();

      await _firestore.collection('users').doc(user.uid).set({
        'coursProgress': {
          widget.courseId: {
            'progress': progress,
            'lastCard': cardIndex,
            'lastUpdate': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));

      await _firestore.collection('users').doc(user.uid).update({
        'points': FieldValue.increment(10),
      });
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
    }
  }

  Widget _buildCompletionView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Cours terminé ! 🎉',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: isDark
                    ? Border.all(color: const Color(0xFF3C445C))
                    : null,
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  _buildStat(
                    Icons.layers,
                    'Cartes complétées',
                    '${cards.length}',
                  ),
                  const Divider(height: 32),
                  _buildStat(
                    Icons.stars,
                    'Points gagnés',
                    '+${cards.length * 10}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Retour aux cours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentCardIndex = 0;
                    _showAnswer = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Recommencer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'lesson':
        return const Color(0xFF2F80ED);
      case 'quiz':
        return const Color(0xFFFF6B6B);
      case 'exercise':
        return const Color(0xFF4CAF50);
      case 'example':
        return const Color(0xFFFFD93D);
      default:
        return const Color(0xFF2F80ED);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'lesson':
        return Icons.school;
      case 'quiz':
        return Icons.quiz;
      case 'exercise':
        return Icons.code;
      case 'example':
        return Icons.lightbulb;
      default:
        return Icons.school;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'lesson':
        return 'Leçon';
      case 'quiz':
        return 'Quiz';
      case 'exercise':
        return 'Exercice';
      case 'example':
        return 'Exemple';
      default:
        return 'Contenu';
    }
  }
}