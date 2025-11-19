import 'package:flutter/material.dart';
import '../../../../legacy/cours_model.dart';
import '../../../../core/services/cours_service.dart';
import '../../../../legacy/cours_model.dart';
import '../../../../core/legacy/card_model.dart';

class CourseEditorScreen extends StatefulWidget {
  final String langageId;
  final CoursModel? cours; // null = création, non-null = édition

  const CourseEditorScreen({
    super.key,
    required this.langageId,
    this.cours,
  });

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final CoursService _coursService = CoursService();

  late final TextEditingController _titreController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.cours?.titre ?? '');
    _descriptionController =
        TextEditingController(text: widget.cours?.description ?? '');
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCours() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.cours == null) {
        // Création d’un nouveau cours avec une liste de cartes VIDE pour l’instant
        await _coursService.createCours(
          titre: _titreController.text.trim(),
          langageId: widget.langageId,
          cards: <CardModel>[],
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cours créé avec succès !')),
          );
        }
      } else {
        // Mise à jour du cours existant (on ne touche pas aux cards)
        await _coursService.updateCours(
          widget.cours!.id,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cours modifié avec succès !')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.cours == null ? 'Nouveau cours' : 'Modifier le cours',
        ),
        backgroundColor: const Color(0xFF2F80ED),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCours,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'ENREGISTRER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titreController,
              decoration: const InputDecoration(
                labelText: 'Titre du cours',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'L’édition des cartes (leçons / quiz) sera ajoutée plus tard.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
