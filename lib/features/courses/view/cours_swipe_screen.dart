import 'package:flutter/material.dart';
import '../../../legacy/cours_model.dart';
import '../../../core/services/cours_service.dart';
import '../../../core/legacy/swipable_card.dart';
import '../../../core/legacy/card_model.dart';
import '../widgets/code_exercise_card.dart';  // ✅ AJOUTÉ

class CoursSwipeScreen extends StatefulWidget {
  final CoursModel cours;

  const CoursSwipeScreen({Key? key, required this.cours}) : super(key: key);

  @override
  State<CoursSwipeScreen> createState() => _CoursSwipeScreenState();
}

class _CoursSwipeScreenState extends State<CoursSwipeScreen> {
  final CoursService _coursService = CoursService();
  int _currentCardIndex = 0;
  int _totalCorrect = 0;

  @override
  Widget build(BuildContext context) {
    final isLastCard = _currentCardIndex >= widget.cours.cards.length - 1;
    final progress = (_currentCardIndex + 1) / widget.cours.cards.length;

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF2F80ED),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cours.titre,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_currentCardIndex + 1} / ${widget.cours.cards.length}',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: _currentCardIndex < widget.cours.cards.length
          ? _buildCardView()
          : _buildCompletionView(),
    );
  }

  Widget _buildCardView() {
    final currentCard = widget.cours.cards[_currentCardIndex];
    
    // ✅ AJOUTÉ : Afficher l'exercice de code si c'est un exercice
    if (currentCard.type == 'exercise') {
      return SafeArea(
        child: CodeExerciseCard(
          key: ValueKey(_currentCardIndex),
          card: currentCard,
          onComplete: (isCorrect) {
            if (isCorrect) {
              // Attendre 2 secondes avant de passer à la carte suivante
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  _handleNextCard();
                }
              });
            }
          },
        ),
      );
    }
    
    // Pour les autres types de cartes (lesson, quiz, example)
    return SafeArea(
      child: SwipableCard(
        key: ValueKey(_currentCardIndex),
        card: currentCard,
        isLastCard: _currentCardIndex >= widget.cours.cards.length - 1,
        onSwipeRight: _handleNextCard,
      ),
    );
  }

  void _handleNextCard() async {
    if (_currentCardIndex < widget.cours.cards.length - 1) {
      // Sauvegarder la progression
      await _coursService.saveProgress(
        widget.cours.id,
        _currentCardIndex + 1,
        widget.cours.cards.length,
      );

      setState(() {
        _currentCardIndex++;
      });
    } else {
      // Marquer comme terminé
      await _coursService.saveProgress(
        widget.cours.id,
        widget.cours.cards.length,
        widget.cours.cards.length,
      );

      setState(() {
        _currentCardIndex++; // Pour afficher l'écran de complétion
      });
    }
  }

  Widget _buildCompletionView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation de succès
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events,
                size: 60,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 32),

            // Titre
            Text(
              'Cours terminé ! 🎉',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16),

            // Statistiques
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildStat(
                    Icons.layers,
                    'Cartes complétées',
                    '${widget.cours.cards.length}',
                  ),
                  Divider(height: 32),
                  _buildStat(
                    Icons.quiz,
                    'Quiz réussis',
                    '${widget.cours.quizCount}',
                  ),
                  Divider(height: 32),
                  _buildStat(
                    Icons.code,
                    'Exercices complétés',
                    '${widget.cours.exerciseCount}',  // ✅ AJOUTÉ
                  ),
                  Divider(height: 32),
                  _buildStat(
                    Icons.stars,
                    'Points gagnés',
                    '+${widget.cours.cards.length * 10}',
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Bouton retour
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2F80ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Retour aux cours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Bouton recommencer
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentCardIndex = 0;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF2F80ED), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Recommencer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F80ED),
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
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF2F80ED).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Color(0xFF2F80ED), size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2F80ED),
          ),
        ),
      ],
    );
  }
}