import 'package:flutter/material.dart';
import '../../../../core/legacy/card_model.dart';

/// Dialogue pour créer/modifier un exercice de code
class ExerciseEditorDialog extends StatefulWidget {
  final CardModel? card;
  final Function(CardModel) onSave;

  const ExerciseEditorDialog({
    Key? key,
    this.card,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ExerciseEditorDialog> createState() => _ExerciseEditorDialogState();
}

class _ExerciseEditorDialogState extends State<ExerciseEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _promptController;
  late TextEditingController _starterCodeController;
  late TextEditingController _solutionController;
  late TextEditingController _hintController;
  late TextEditingController _explanationController;
  late TextEditingController _testsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card?.title ?? '');
    _promptController = TextEditingController(text: widget.card?.exercisePrompt ?? '');
    _starterCodeController = TextEditingController(text: widget.card?.exerciseStarterCode ?? '');
    _solutionController = TextEditingController(text: widget.card?.exerciseSolution ?? '');
    _hintController = TextEditingController(text: widget.card?.exerciseHint ?? '');
    _explanationController = TextEditingController(text: widget.card?.explanation ?? '');
    _testsController = TextEditingController(
      text: widget.card?.exerciseTests?.join('\n') ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _starterCodeController.dispose();
    _solutionController.dispose();
    _hintController.dispose();
    _explanationController.dispose();
    _testsController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire')),
      );
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La consigne est obligatoire')),
      );
      return;
    }

    if (_solutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La solution est obligatoire')),
      );
      return;
    }

    // Parser les tests (un par ligne)
    final tests = _testsController.text
        .split('\n')
        .where((t) => t.trim().isNotEmpty)
        .map((t) => t.trim())
        .toList();

    final card = CardModel(
      id: widget.card?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'exercise',
      title: _titleController.text.trim(),
      exercisePrompt: _promptController.text.trim(),
      exerciseStarterCode: _starterCodeController.text.trim().isEmpty 
          ? null 
          : _starterCodeController.text.trim(),
      exerciseSolution: _solutionController.text.trim(),
      exerciseHint: _hintController.text.trim().isEmpty 
          ? null 
          : _hintController.text.trim(),
      explanation: _explanationController.text.trim().isEmpty 
          ? null 
          : _explanationController.text.trim(),
      exerciseTests: tests.isEmpty ? null : tests,
      question: null,
      reponse: '',
    );

    widget.onSave(card);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      title: Text(
        widget.card == null ? '💻 Nouvel exercice de code' : '💻 Modifier l\'exercice',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              _buildTextField(
                controller: _titleController,
                label: 'Titre de l\'exercice *',
                hint: 'Ex: Afficher "Hello World"',
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Consigne
              _buildTextField(
                controller: _promptController,
                label: 'Consigne *',
                hint: 'Écris un programme qui affiche "Hello World" dans la console',
                maxLines: 3,
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Code de départ (optionnel)
              const Text(
                '📝 Code de départ (optionnel)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _buildCodeField(
                controller: _starterCodeController,
                hint: '# Complète ce code\nprint("...")',
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Solution
              const Text(
                '✅ Solution attendue *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              _buildCodeField(
                controller: _solutionController,
                hint: 'print("Hello World")',
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Indice
              _buildTextField(
                controller: _hintController,
                label: '💡 Indice (optionnel)',
                hint: 'Utilise la fonction print()',
                maxLines: 2,
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Mots-clés à vérifier
              const Text(
                '🔍 Mots-clés requis (optionnel)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Un mot-clé par ligne. Le code doit contenir tous ces mots.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _testsController,
                hint: 'print\nHello World',
                maxLines: 3,
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Explication
              _buildTextField(
                controller: _explanationController,
                label: '📚 Explication (optionnel)',
                hint: 'La fonction print() affiche du texte dans la console...',
                maxLines: 3,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    required String hint,
    int maxLines = 1,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
      ),
    );
  }

  Widget _buildCodeField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      maxLines: 4,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D),
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}