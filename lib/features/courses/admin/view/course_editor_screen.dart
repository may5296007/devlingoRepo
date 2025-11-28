import 'package:flutter/material.dart';
import '../../../../legacy/cours_model.dart';
import '../../../../core/services/cours_service.dart';
import '../../../../core/legacy/card_model.dart';
import '../view/exercise_editor_dialog.dart';

class CourseEditorScreen extends StatefulWidget {
  final String langageId;
  final CoursModel? cours;

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

  // Liste des cartes
  List<CardModel> _cards = [];

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.cours?.titre ?? '');
    _descriptionController =
        TextEditingController(text: widget.cours?.description ?? '');
    
    // Charger les cartes existantes si on édite un cours
    if (widget.cours != null) {
      _cards = List.from(widget.cours!.cards);
    }
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
        // Création d'un nouveau cours
        await _coursService.createCours(
          titre: _titreController.text.trim(),
          langageId: widget.langageId,
          cards: _cards,
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
        // Mise à jour du cours existant
        await _coursService.updateCours(
          widget.cours!.id,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          cards: _cards,
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
  // ===============================================
// MÉTHODE À AJOUTER dans course_editor_screen.dart
// ===============================================
// Place cette méthode APRÈS _saveCours() (vers ligne 104)

Future<void> _deleteCours() async {
  // Demander confirmation
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text('Supprimer le cours ?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu es sur le point de supprimer :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '"${widget.cours?.titre}"',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cette action est irréversible !',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever, size: 20),
              SizedBox(width: 4),
              Text('Supprimer'),
            ],
          ),
        ),
      ],
    ),
  );

  // Si l'utilisateur annule
  if (confirmed != true) return;

  setState(() => _isLoading = true);

  try {
    // Supprimer le cours
    await _coursService.deleteCours(widget.cours!.id);
    
    if (mounted) {
      // Notification de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Cours supprimé avec succès !'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Retour à la liste
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) {
      // Notification d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Erreur : $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _addCard(String type) {
    if (type == 'exercise') {
      // Dialogue spécial pour les exercices
      showDialog(
        context: context,
        builder: (context) => ExerciseEditorDialog(
          onSave: (card) {
            setState(() {
              _cards.add(card);
            });
          },
        ),
      );
    } else {
      // Dialogue normal pour les autres types
      showDialog(
        context: context,
        builder: (context) => _CardEditorDialog(
          type: type,
          onSave: (card) {
            setState(() {
              _cards.add(card);
            });
          },
        ),
      );
    }
  }

  void _editCard(int index) {
    final card = _cards[index];
    
    if (card.type == 'exercise') {
      // Dialogue spécial pour les exercices
      showDialog(
        context: context,
        builder: (context) => ExerciseEditorDialog(
          card: card,
          onSave: (updatedCard) {
            setState(() {
              _cards[index] = updatedCard;
            });
          },
        ),
      );
    } else {
      // Dialogue normal pour les autres types
      showDialog(
        context: context,
        builder: (context) => _CardEditorDialog(
          type: card.type,
          card: card,
          onSave: (updatedCard) {
            setState(() {
              _cards[index] = updatedCard;
            });
          },
        ),
      );
    }
  }

  void _deleteCard(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la carte'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette carte ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _cards.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _reorderCards(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final card = _cards.removeAt(oldIndex);
      _cards.insert(newIndex, card);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.cours == null ? 'Nouveau cours' : 'Modifier le cours',
        ),
        backgroundColor: Theme.of(context).primaryColor,
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
        child: Column(
          children: [
            // Formulaire de base
            Container(
              color: isDark ? const Color(0xFF1E2430) : Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titreController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Titre du cours',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
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
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnelle)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Section des cartes
            Expanded(
              child: Container(
                color: isDark ? const Color(0xFF131823) : const Color(0xFFF5F7FA),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Cartes du cours',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            '${_cards.length} carte(s)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    // Boutons d'ajout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildAddCardButton('Leçon', Icons.book, () => _addCard('lesson')),
                          _buildAddCardButton('Exemple', Icons.lightbulb, () => _addCard('example')),
                          _buildAddCardButton('Quiz', Icons.quiz, () => _addCard('quiz')),
                          _buildAddCardButton('Exercice', Icons.code, () => _addCard('exercise')),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Liste des cartes
                    Expanded(
                      child: _cards.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.layers_outlined,
                                    size: 64,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune carte',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ajoutez des cartes pour créer votre cours',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _cards.length,
                              onReorder: _reorderCards,
                              itemBuilder: (context, index) {
                                return _buildCardItem(_cards[index], index, isDark);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCardItem(CardModel card, int index, bool isDark) {
    return Container(
      key: ValueKey(card.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: const Color(0xFF3C445C), width: 2) : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getTypeColor(card.type).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTypeIcon(card.type),
            color: _getTypeColor(card.type),
            size: 22,
          ),
        ),
        title: Text(
          card.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          _getTypeLabel(card.type),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editCard(index),
              color: Theme.of(context).primaryColor,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _deleteCard(index),
              color: Colors.red,
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lesson':
        return Icons.book;
      case 'example':
        return Icons.lightbulb;
      case 'quiz':
        return Icons.quiz;
      case 'exercise':
        return Icons.code;
      default:
        return Icons.article;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lesson':
        return const Color(0xFF2F80ED);
      case 'example':
        return const Color(0xFFFFD93D);
      case 'quiz':
        return const Color(0xFFFF6B6B);
      case 'exercise':
        return const Color(0xFF4ECDC4);
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'lesson':
        return 'Leçon';
      case 'example':
        return 'Exemple';
      case 'quiz':
        return 'Quiz';
      case 'exercise':
        return 'Exercice de code';
      default:
        return 'Carte';
    }
  }
}

// ==========================================
// DIALOGUE D'ÉDITION DE CARTE (NORMAL)
// ==========================================

class _CardEditorDialog extends StatefulWidget {
  final String type;
  final CardModel? card;
  final Function(CardModel) onSave;

  const _CardEditorDialog({
    required this.type,
    this.card,
    required this.onSave,
  });

  @override
  State<_CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<_CardEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _codeExampleController;
  late TextEditingController _explanationController;

  // Pour les quiz
  final List<TextEditingController> _optionsControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctAnswerIndex = 0;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.card?.title ?? '');
    _contentController = TextEditingController(text: widget.card?.content ?? '');
    _codeExampleController = TextEditingController(text: widget.card?.codeExample ?? '');
    _explanationController = TextEditingController(text: widget.card?.explanation ?? '');

    if (widget.type.toLowerCase() == 'quiz' && widget.card?.options != null) {
      for (int i = 0; i < widget.card!.options!.length && i < 4; i++) {
        _optionsControllers[i].text = widget.card!.options![i];
      }
      if (widget.card!.correctAnswer != null) {
        _correctAnswerIndex = widget.card!.options!.indexOf(widget.card!.correctAnswer!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _codeExampleController.dispose();
    _explanationController.dispose();
    for (var controller in _optionsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire')),
      );
      return;
    }

    if (widget.type.toLowerCase() == 'quiz') {
      // Vérifier que toutes les options sont remplies
      for (var controller in _optionsControllers) {
        if (controller.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Toutes les options sont obligatoires')),
          );
          return;
        }
      }

      final options = _optionsControllers.map((c) => c.text.trim()).toList();

      widget.onSave(
        CardModel(
          id: widget.card?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: widget.type,
          title: _titleController.text.trim(),
          content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
          explanation: _explanationController.text.trim().isEmpty ? null : _explanationController.text.trim(),
          options: options,
          correctAnswer: options[_correctAnswerIndex],
          question: null,
          reponse: '',
        ),
      );
    } else {
      if (_contentController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le contenu est obligatoire')),
        );
        return;
      }

      widget.onSave(
        CardModel(
          id: widget.card?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: widget.type,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          codeExample: _codeExampleController.text.trim().isEmpty ? null : _codeExampleController.text.trim(),
          explanation: _explanationController.text.trim().isEmpty ? null : _explanationController.text.trim(),
          question: null,
          reponse: '',
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      title: Text(
        widget.card == null
            ? 'Nouvelle carte ${_getTypeLabel()}'
            : 'Modifier la carte',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.type.toLowerCase() == 'quiz') ...[
                TextField(
                  controller: _contentController,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Question (optionnelle)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(_optionsControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _correctAnswerIndex,
                          onChanged: (value) {
                            setState(() {
                              _correctAnswerIndex = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _optionsControllers[index],
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  'Cochez la bonne réponse',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _explanationController,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Explication (optionnelle)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Contenu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeExampleController,
                  maxLines: 4,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Exemple de code (optionnel)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _explanationController,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Explication supplémentaire (optionnelle)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
              ],
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

  String _getTypeLabel() {
    switch (widget.type.toLowerCase()) {
      case 'lesson':
        return '📚';
      case 'example':
        return '💡';
      case 'quiz':
        return '❓';
      default:
        return '📝';
    }
  }
}