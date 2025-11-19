import 'package:flutter/material.dart';
import '../legacy/card_model.dart';

class SwipableCard extends StatelessWidget {
  final CardModel card;
  final bool isLastCard;
  final VoidCallback onSwipeRight;

  const SwipableCard({
    Key? key,
    required this.card,
    required this.isLastCard,
    required this.onSwipeRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe vers la droite → prochaine carte
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 0) {
          onSwipeRight();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (card.isLesson) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.titre,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (card.contenu != null)
            Text(
              card.contenu!,
              style: const TextStyle(fontSize: 16),
            ),
          if (card.codeExample != null &&
              card.codeExample!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Exemple de code :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.codeExample!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Quiz
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.question ?? card.titre,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...card.options.asMap().entries.map((e) {
          final index = e.key;
          final option = e.value;
          final isCorrect = card.correctAnswer == index;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCorrect
                  ? const Color(0xFFE3F2FD)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  String.fromCharCode(65 + index),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(option)),
              ],
            ),
          );
        }).toList(),
        if (card.explanation != null &&
            card.explanation!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Explication',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(card.explanation!),
        ],
      ],
    );
  }
}
