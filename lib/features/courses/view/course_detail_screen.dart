import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({Key? key}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  int currentCardIndex = 0;
  Map<String, dynamic>? courseData;
  String? courseId;
  Map<String, dynamic>? langageData;
  List<dynamic> cards = [];
  bool showAnswer = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      courseId = args['courseId'];
      courseData = args['courseData'];
      langageData = args['langageData'];
      cards = courseData?['cards'] ?? [];
    }
  }

  void _nextCard() {
    if (currentCardIndex < cards.length - 1) {
      setState(() {
        currentCardIndex++;
        showAnswer = false;
      });
      _saveProgress();
    } else {
      // Cours terminé
      _showCompletionDialog();
    }
  }

  void _previousCard() {
    if (currentCardIndex > 0) {
      setState(() {
        currentCardIndex--;
        showAnswer = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    final user = _auth.currentUser;
    if (user == null || courseId == null) return;

    final progress = ((currentCardIndex + 1) / cards.length * 100).round();
    final completed = currentCardIndex + 1 >= cards.length;

    await _firestore.collection('users').doc(user.uid).set({
      'coursProgress': {
        courseId: {
          'progress': progress,
          'completed': completed,
          'lastAccessed': FieldValue.serverTimestamp(),
        }
      }
    }, SetOptions(merge: true));

    // Ajouter des points si c'est la première fois
    if (completed) {
      await _firestore.collection('utilisateurs').doc(user.uid).update({
        'points': FieldValue.increment(100),
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉',
              style: TextStyle(fontSize: 60),
            ),
            SizedBox(height: 20),
            Text(
              'Félicitations !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F80ED),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tu as terminé ce cours !',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFFD93D).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+100 XP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Retour aux cours',
              style: TextStyle(color: Color(0xFF2F80ED)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (courseData == null || cards.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Aucune carte disponible',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final currentCard = cards[currentCardIndex] as Map<String, dynamic>;
    final progress = (currentCardIndex + 1) / cards.length;

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              courseData?['titre'] ?? 'Cours',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${langageData?['nom'] ?? 'Langage'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de progression
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Carte ${currentCardIndex + 1} sur ${cards.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F80ED),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
                  minHeight: 8,
                ),
              ],
            ),
          ),

          // Contenu de la carte
          Expanded(
            child: Container(
              margin: EdgeInsets.all(24),
              child: GestureDetector(
                onTap: () {
                  if (currentCard['type'] != 'quiz') {
                    setState(() {
                      showAnswer = !showAnswer;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Type de carte
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getCardTypeColor(currentCard['type']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getCardTypeLabel(currentCard['type']),
                          style: TextStyle(
                            color: _getCardTypeColor(currentCard['type']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Contenu principal
                      if (currentCard['type'] == 'quiz')
                        _buildQuizCard(currentCard)
                      else
                        _buildLessonCard(currentCard),

                      if (currentCard['type'] != 'quiz' && !showAnswer)
                        Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Text(
                            'Tapez pour voir la réponse',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Boutons de navigation
          Container(
            padding: EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                if (currentCardIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousCard,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Color(0xFF2F80ED)),
                      ),
                      child: Text(
                        'Précédent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (currentCardIndex > 0) SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2F80ED),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      currentCardIndex == cards.length - 1 ? 'Terminer' : 'Suivant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> card) {
    return Column(
      children: [
        Text(
          card['question'] ?? '',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
        ),
        if (showAnswer) ...[
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF2F80ED).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF2F80ED).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Text(
              card['reponse'] ?? '',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF1A1A1A),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> card) {
    final options = card['options'] as List<dynamic>? ?? [];
    final selectedOption = card['selectedOption'];
    
    return Column(
      children: [
        Text(
          card['question'] ?? '',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = selectedOption == index;
          final isCorrect = index == card['correctAnswer'];
          
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  cards[currentCardIndex]['selectedOption'] = index;
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isCorrect ? Colors.green : Colors.red)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getCardTypeColor(String? type) {
    switch (type) {
      case 'lecon':
        return Color(0xFF2F80ED);
      case 'quiz':
        return Color(0xFFFF6B6B);
      case 'exemple':
        return Color(0xFF4ECDC4);
      default:
        return Color(0xFF2F80ED);
    }
  }

  String _getCardTypeLabel(String? type) {
    switch (type) {
      case 'lecon':
        return '📚 Leçon';
      case 'quiz':
        return '❓ Quiz';
      case 'exemple':
        return '💡 Exemple';
      default:
        return '📝 Carte';
    }
  }
}