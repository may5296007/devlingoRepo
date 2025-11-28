// Votre fichier ExerciseEditorDialog réécrit proprement
import 'package:flutter/material.dart';
import '../../../../core/legacy/card_model.dart';

class ExerciseEditorDialog extends StatefulWidget {
  final CardModel? card;
  final Function(CardModel) onSave;

  const ExerciseEditorDialog({
    Key? key,
    this.card,
    required this.onSave, CardModel? cardToEdit,
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
  late TextEditingController _testsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card?.title ?? "");
    _promptController = TextEditingController(text: widget.card?.exercisePrompt ?? "");
    _starterCodeController = TextEditingController(text: widget.card?.exerciseStarterCode ?? "");
    _solutionController = TextEditingController(text: widget.card?.exerciseSolution ?? "");
    _hintController = TextEditingController(text: widget.card?.exerciseHint ?? "");
    _testsController = TextEditingController(
      text: widget.card?.exerciseTests?.join("\n") ?? "",
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _starterCodeController.dispose();
    _solutionController.dispose();
    _hintController.dispose();
    _testsController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le titre est obligatoire")),
      );
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La consigne est obligatoire")),
      );
      return;
    }

    if (_solutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La solution est obligatoire")),
      );
      return;
    }

    final tests = _testsController.text
        .split("\n")
        .where((t) => t.trim().isNotEmpty)
        .map((t) => t.trim())
        .toList();

    final card = CardModel(
      id: widget.card?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: "exercise",
      title: _titleController.text.trim(),
      exercisePrompt: _promptController.text.trim(),
      exerciseStarterCode: _starterCodeController.text.trim().isEmpty
          ? null
          : _starterCodeController.text.trim(),
      exerciseSolution: _solutionController.text.trim(),
      exerciseHint: _hintController.text.trim().isEmpty
          ? null
          : _hintController.text.trim(),
      exerciseTests: tests.isEmpty ? null : tests,
    );

    widget.onSave(card);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Row(
        children: const [
          Text("💻", style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Text("Nouvel exercice", style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _titleController,
                label: "Titre *",
                hint: "Afficher 'Hello World'",
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _promptController,
                label: "Consigne *",
                hint: "Écris un programme qui affiche 'Hello World'",
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _starterCodeController,
                label: "Code de départ (optionnel)",
                hint: "# Complète ce code\nprint('...')",
                maxLines: 3,
                isCode: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _solutionController,
                label: "Solution *",
                hint: "print('Hello World')",
                maxLines: 3,
                isCode: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _hintController,
                label: "Indice (optionnel)",
                hint: "Utilise la fonction print()",
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              const Text(
                "Mots-clés requis (optionnel)",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Un mot-clé par ligne. Le code doit contenir tous ces mots.",
                style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),

              _buildTextField(
                controller: _testsController,
                hint: "print\nHello World",
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2F80ED),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Enregistrer"),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    required String hint,
    int maxLines = 1,
    bool isCode = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: isCode
          ? const TextStyle(fontFamily: "monospace", fontSize: 13)
          : const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isCode ? Color(0xFFF5F5F5) : Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}