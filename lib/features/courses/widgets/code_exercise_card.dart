import 'package:flutter/material.dart';
import '../../../core/legacy/card_model.dart';

class CodeExerciseCard extends StatefulWidget {
  final CardModel card;
  final Function(bool) onComplete;

  const CodeExerciseCard({
    Key? key,
    required this.card,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<CodeExerciseCard> createState() => _CodeExerciseCardState();
}

class _CodeExerciseCardState extends State<CodeExerciseCard> {
  late TextEditingController _codeController;
  bool _showHint = false;
  bool _showSolution = false;
  bool _isCorrect = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.card.exerciseStarterCode ?? '',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _checkSolution() {
    final userCode = _codeController.text.trim();
    final solution = widget.card.exerciseSolution?.trim() ?? '';
    final tests = widget.card.exerciseTests ?? [];

    // Vérification simple : le code contient-il tous les mots-clés requis ?
    bool allTestsPass = true;
    List<String> failedTests = [];

    if (tests.isNotEmpty) {
      for (String test in tests) {
        if (!userCode.contains(test.trim())) {
          allTestsPass = false;
          failedTests.add(test);
        }
      }
    }

    setState(() {
      if (userCode.isEmpty) {
        _isCorrect = false;
        _feedbackMessage = '❌ Écris du code avant de vérifier !';
      } else if (userCode == solution) {
        // Solution exacte
        _isCorrect = true;
        _feedbackMessage = '✅ Parfait ! C\'est exactement la solution attendue !';
        widget.onComplete(true);
      } else if (allTestsPass && tests.isNotEmpty) {
        // Tests passés
        _isCorrect = true;
        _feedbackMessage = '✅ Excellent ! Ton code contient tous les éléments requis !';
        widget.onComplete(true);
      } else if (!allTestsPass && tests.isNotEmpty) {
        // Tests échoués
        _isCorrect = false;
        _feedbackMessage = '❌ Il manque : ${failedTests.join(", ")}';
      } else {
        // Pas de tests, comparaison approximative
        final similarity = _calculateSimilarity(userCode, solution);
        if (similarity > 0.8) {
          _isCorrect = true;
          _feedbackMessage = '✅ Très bien ! Ton code fonctionne !';
          widget.onComplete(true);
        } else {
          _isCorrect = false;
          _feedbackMessage = '❌ Ce n\'est pas tout à fait ça. Essaie encore !';
        }
      }
    });
  }

  double _calculateSimilarity(String s1, String s2) {
    // Calcul simple de similarité (Jaccard)
    final words1 = s1.toLowerCase().split(RegExp(r'\s+'));
    final words2 = s2.toLowerCase().split(RegExp(r'\s+'));
    final intersection = words1.where((w) => words2.contains(w)).length;
    final union = {...words1, ...words2}.length;
    return union > 0 ? intersection / union : 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header avec titre et badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF4A9FFF), const Color(0xFF7EC8FF)]
                  : [const Color(0xFF2F80ED), const Color(0xFF56CCF2)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '💻 EXERCICE DE CODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.card.title ?? 'Exercice',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Contenu principal
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Consigne
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3C445C) : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Consigne',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.card.exercisePrompt ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Éditeur de code
                Text(
                  'Ton code :',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isCorrect
                          ? Colors.green
                          : (_feedbackMessage != null && !_isCorrect)
                              ? Colors.red
                              : Colors.grey[700]!,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _codeController,
                    maxLines: 12,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                      hintText: '# Écris ton code ici...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                    onChanged: (_) {
                      // Réinitialiser le feedback quand l'utilisateur modifie
                      if (_feedbackMessage != null) {
                        setState(() {
                          _feedbackMessage = null;
                          _isCorrect = false;
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Boutons d'aide
                Row(
                  children: [
                    if (widget.card.exerciseHint != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showHint = !_showHint;
                            });
                          },
                          icon: Icon(_showHint ? Icons.visibility_off : Icons.lightbulb),
                          label: Text(_showHint ? 'Cacher l\'indice' : 'Voir l\'indice'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    if (widget.card.exerciseHint != null) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showSolution = !_showSolution;
                          });
                        },
                        icon: Icon(_showSolution ? Icons.visibility_off : Icons.code),
                        label: Text(_showSolution ? 'Cacher' : 'Voir solution'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Indice
                if (_showHint && widget.card.exerciseHint != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.card.exerciseHint!,
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_showHint && widget.card.exerciseHint != null)
                  const SizedBox(height: 16),

                // Solution
                if (_showSolution)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.code, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Solution :',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.card.exerciseSolution ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_showSolution) const SizedBox(height: 16),

                // Feedback
                if (_feedbackMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isCorrect ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCorrect ? Icons.check_circle : Icons.error,
                          color: _isCorrect ? Colors.green : Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _feedbackMessage!,
                            style: TextStyle(
                              color: _isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_feedbackMessage != null) const SizedBox(height: 16),

                // Explication (après succès)
                if (_isCorrect && widget.card.explanation != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Explication :',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.card.explanation!,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bouton de vérification
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isCorrect ? null : _checkSolution,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCorrect ? Colors.green : const Color(0xFF2F80ED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _isCorrect ? '✓ Exercice réussi !' : 'Vérifier mon code',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}