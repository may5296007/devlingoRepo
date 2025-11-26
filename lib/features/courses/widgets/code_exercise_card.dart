import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/legacy/card_model.dart';

/// Widget pour afficher et compléter un exercice de code
class CodeExerciseCard extends StatefulWidget {
  final CardModel card;
  final Function(bool isCorrect) onComplete;

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
  String? _feedback;
  bool? _isCorrect;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    // Initialiser avec le code de départ s'il existe
    _codeController = TextEditingController(
      text: widget.card.exerciseStarterCode ?? '',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Vérifier le code de l'utilisateur
  void _checkCode() {
    setState(() {
      _attempts++;
      final userCode = _codeController.text.trim();
      final solution = widget.card.exerciseSolution?.trim() ?? '';

      // Méthode 1 : Comparaison exacte (simple)
      if (_isCodeCorrect(userCode, solution)) {
        _isCorrect = true;
        _feedback = '✅ Excellent ! Ton code est correct !';
        widget.onComplete(true);
      } else {
        _isCorrect = false;
        _feedback = '❌ Pas tout à fait. Réessaie !';
        
        // Afficher l'indice après 2 tentatives
        if (_attempts >= 2 && !_showHint) {
          _showHint = true;
        }
      }
    });
  }

  // Vérifier si le code est correct (plusieurs méthodes possibles)
  bool _isCodeCorrect(String userCode, String solution) {
    // Méthode 1 : Comparaison exacte (ignorer les espaces)
    final normalizedUser = _normalizeCode(userCode);
    final normalizedSolution = _normalizeCode(solution);
    
    if (normalizedUser == normalizedSolution) {
      return true;
    }

    // Méthode 2 : Vérifier des mots-clés essentiels (plus flexible)
    if (widget.card.exerciseTests != null) {
      return _checkKeywords(userCode, widget.card.exerciseTests!);
    }

    return false;
  }

  // Normaliser le code (enlever espaces inutiles, etc.)
  String _normalizeCode(String code) {
    return code
        .replaceAll(RegExp(r'\s+'), ' ') // Remplacer multiples espaces par un
        .replaceAll(RegExp(r'\s*([=+\-*/,;(){}[\]])\s*'), r'\1') // Enlever espaces autour des opérateurs
        .trim();
  }

  // Vérifier que le code contient les mots-clés requis
  bool _checkKeywords(String code, List<String> keywords) {
    for (var keyword in keywords) {
      if (!code.contains(keyword)) {
        return false;
      }
    }
    return true;
  }

  // Réinitialiser l'exercice
  void _reset() {
    setState(() {
      _codeController.text = widget.card.exerciseStarterCode ?? '';
      _feedback = null;
      _isCorrect = null;
      _showHint = false;
      _showSolution = false;
      _attempts = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consigne de l'exercice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.code,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '💻 Exercice de code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.card.exercisePrompt ?? 'Complète le code ci-dessous',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Éditeur de code
            Text(
              'Ton code :',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCorrect == null
                      ? Colors.grey[700]!
                      : _isCorrect!
                          ? Colors.green
                          : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // Barre d'outils
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '📝 Code Editor',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (_isCorrect != true)
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                            onPressed: _reset,
                            tooltip: 'Réinitialiser',
                          ),
                      ],
                    ),
                  ),
                  
                  // Zone de code
                 // Zone de code
TextField(
  controller: _codeController,
  maxLines: 10,
  style: const TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    color: Color(0xFF4EC9B0),
    height: 1.5,
  ),
  decoration: InputDecoration(
    hintText: '// Écris ton code ici...',
    hintStyle: TextStyle(
      color: Colors.grey[600],
      fontFamily: 'monospace',
    ),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.all(16),
  ),
  enabled: _isCorrect != true,
),

TextField(
  controller: _codeController,
  maxLines: 10,
  autofocus: false,  // ✅ AJOUTÉ
  keyboardType: TextInputType.multiline,  // ✅ AJOUTÉ
  textInputAction: TextInputAction.newline,  // ✅ AJOUTÉ
  style: const TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    color: Color(0xFF4EC9B0),
    height: 1.5,
  ),
  decoration: InputDecoration(
    hintText: '// Clique ici et écris ton code...',  // ✅ MODIFIÉ
    hintStyle: TextStyle(
      color: Colors.grey[600],
      fontFamily: 'monospace',
    ),
    filled: true,  // ✅ AJOUTÉ
    fillColor: Colors.black.withOpacity(0.05),  // ✅ AJOUTÉ
    border: OutlineInputBorder(  // ✅ MODIFIÉ
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(  // ✅ AJOUTÉ
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xFF2F80ED), width: 2),
    ),
    contentPadding: const EdgeInsets.all(16),
  ),
  enabled: _isCorrect != true,
),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                // Bouton Vérifier
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isCorrect == true ? null : _checkCode,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Vérifier',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Bouton Indice
                if (widget.card.exerciseHint != null && _showHint)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('💡 Indice'),
                            content: Text(widget.card.exerciseHint!),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.lightbulb_outline, size: 20),
                      label: const Text('Indice'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Feedback
            if (_feedback != null) ...[
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect!
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isCorrect! ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCorrect! ? Icons.check_circle : Icons.error,
                      color: _isCorrect! ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _feedback!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect! ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Afficher la solution après plusieurs tentatives
            if (_attempts >= 3 && _isCorrect != true) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showSolution = !_showSolution;
                  });
                },
                icon: Icon(_showSolution ? Icons.visibility_off : Icons.visibility),
                label: Text(_showSolution ? 'Masquer la solution' : 'Voir la solution'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
              
              if (_showSolution) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✨ Solution :',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        widget.card.exerciseSolution ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: Color(0xFF4EC9B0),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Explication (si exercice réussi)
            if (_isCorrect == true && widget.card.explanation != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📚 Explication :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.card.explanation!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}