import 'package:flutter/material.dart';
import '../models/card_model.dart';

class SwipableCard extends StatefulWidget {
  final CardModel card;
  final VoidCallback onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final bool isLastCard;

  const SwipableCard({
    Key? key,
    required this.card,
    required this.onSwipeRight,
    this.onSwipeLeft,
    this.isLastCard = false,
  }) : super(key: key);

  @override
  State<SwipableCard> createState() => _SwipableCardState();
}

class _SwipableCardState extends State<SwipableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  
  int? _selectedAnswer;
  bool _showExplanation = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSwipe() {
    _controller.forward().then((_) {
      widget.onSwipeRight();
      if (mounted) {
        _controller.reset();
        setState(() {
          _selectedAnswer = null;
          _showExplanation = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2F80ED).withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.card.isLesson ? Icons.school : Icons.quiz,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.card.isLesson ? 'Leçon' : 'Quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      widget.card.titre,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    
                    SizedBox(height: 20),

                    // Contenu de la leçon
                    if (widget.card.isLesson && widget.card.contenu != null)
                      ...[
                        Text(
                          widget.card.contenu!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                        if (widget.card.codeExample != null) ...[
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.card.codeExample!,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFF4EC9B0),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],

                    // Quiz
                    if (widget.card.isQuiz) ...[
                      Text(
                        widget.card.question!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      ...List.generate(
                        widget.card.options?.length ?? 0,
                        (index) => _buildOption(index),
                      ),

                      if (_showExplanation && widget.card.explanation != null) ...[
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedAnswer == widget.card.correctAnswer
                                ? Color(0xFF4CAF50).withOpacity(0.1)
                                : Color(0xFFFF6B6B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedAnswer == widget.card.correctAnswer
                                  ? Color(0xFF4CAF50)
                                  : Color(0xFFFF6B6B),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _selectedAnswer == widget.card.correctAnswer
                                        ? Icons.check_circle
                                        : Icons.info,
                                    color: _selectedAnswer == widget.card.correctAnswer
                                        ? Color(0xFF4CAF50)
                                        : Color(0xFFFF6B6B),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _selectedAnswer == widget.card.correctAnswer
                                        ? 'Correct !'
                                        : 'Explication',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _selectedAnswer == widget.card.correctAnswer
                                          ? Color(0xFF4CAF50)
                                          : Color(0xFFFF6B6B),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.card.explanation!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // Bouton suivant
            Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.card.isQuiz && _selectedAnswer == null
                      ? null
                      : _handleSwipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2F80ED),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isLastCard ? 'Terminer' : 'Continuer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.card.isQuiz && _selectedAnswer == null
                              ? Colors.grey[600]
                              : Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        widget.isLastCard ? Icons.check : Icons.arrow_forward,
                        color: widget.card.isQuiz && _selectedAnswer == null
                            ? Colors.grey[600]
                            : Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = index == widget.card.correctAnswer;
    final showResult = _showExplanation;

    Color getColor() {
      if (!showResult) {
        return isSelected ? Color(0xFF2F80ED) : Colors.grey[200]!;
      }
      if (isCorrect) return Color(0xFF4CAF50);
      if (isSelected && !isCorrect) return Color(0xFFFF6B6B);
      return Colors.grey[200]!;
    }

    return GestureDetector(
      onTap: _showExplanation
          ? null
          : () {
              setState(() {
                _selectedAnswer = index;
                _showExplanation = true;
              });
            },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: getColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: getColor(),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: getColor(),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.card.options![index],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (showResult && isCorrect)
              Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            if (showResult && isSelected && !isCorrect)
              Icon(Icons.cancel, color: Color(0xFFFF6B6B)),
          ],
        ),
      ),
    );
  }
}