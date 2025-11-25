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
      
      // Debug
      print('📚 Nombre de cartes: ${cards.length}');
      if (cards.isNotEmpty) {
        print('🃏 Première carte: ${cards[0]}');
      }
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
            const Text(
              '🎉',
              style: TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              'Félicitations !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F80ED),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu as terminé ce cours !',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD93D).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
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
            child: const Text(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (courseData == null || cards.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline, 
                size: 64, 
                color: isDark ? Colors.grey[600] : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune carte disponible',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final currentCard = cards[currentCardIndex] as Map<String, dynamic>;
    final progress = (currentCardIndex + 1) / cards.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close, 
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              courseData?['titre'] ?? 'Cours',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              langageData?['nom'] ?? 'Langage',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Carte ${currentCardIndex + 1} sur ${cards.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark 
                    ? const Color(0xFF2A3142) 
                    : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ),

          // Contenu de la carte
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: () {
                  if (currentCard['type']?.toLowerCase() != 'quiz') {
                    setState(() {
                      showAnswer = !showAnswer;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark 
                      ? Border.all(color: const Color(0xFF3C445C), width: 2)
                      : null,
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Type de carte
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getCardTypeColor(currentCard['type'])
                                .withOpacity(0.1),
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
                        const SizedBox(height: 32),

                        // Contenu principal
                        if (currentCard['type']?.toLowerCase() == 'quiz')
                          _buildQuizCard(currentCard, isDark)
                        else
                          _buildLessonCard(currentCard, isDark),

                        if (currentCard['type']?.toLowerCase() != 'quiz' && 
                            !showAnswer)
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Text(
                              'Tapez pour voir la réponse',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                if (currentCardIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousCard,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      child: Text(
                        'Précédent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                if (currentCardIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      currentCardIndex == cards.length - 1 
                        ? 'Terminer' 
                        : 'Suivant',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildLessonCard(Map<String, dynamic> card, bool isDark) {
    // Utiliser 'title' et 'content' du nouveau modèle
    final title = card['titre'] ?? card['title'] ?? '';
    final content = card['contenu'] ?? card['content'] ?? '';
    final codeExample = card['codeExample'];
    final explanation = card['explanation'];

    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (showAnswer) ...[
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          if (codeExample != null && codeExample.toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                  ? const Color(0xFF1E1E1E) 
                  : const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                codeExample.toString(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Color(0xFF4EC9B0),
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (explanation != null && explanation.toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              explanation.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> card, bool isDark) {
    final title = card['titre'] ?? card['title'] ?? '';
    final content = card['contenu'] ?? card['content'];
    final options = (card['options'] as List<dynamic>?) ?? [];
    final correctAnswer = card['correctAnswer'];
    final selectedOption = card['selectedOption'];
    
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (content != null && content.toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            content.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value.toString();
          final isSelected = selectedOption == option || 
                           selectedOption == index;
          final isCorrect = option == correctAnswer;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  cards[currentCardIndex]['selectedOption'] = option;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isCorrect 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1))
                      : (isDark 
                        ? const Color(0xFF2A3142) 
                        : Colors.grey[50]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isCorrect ? Colors.green : Colors.red)
                        : (isDark 
                          ? const Color(0xFF3C445C) 
                          : Colors.grey[300]!),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: isSelected 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
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
      ],
    );
  }

  Color _getCardTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'lesson':
        return const Color(0xFF2F80ED);
      case 'quiz':
        return const Color(0xFFFF6B6B);
      case 'example':
        return const Color(0xFF4ECDC4);
      default:
        return const Color(0xFF2F80ED);
    }
  }

  String _getCardTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'lesson':
        return '📚 Leçon';
      case 'quiz':
        return '❓ Quiz';
      case 'example':
        return '💡 Exemple';
      default:
        return '📝 Carte';
    }
  }
}